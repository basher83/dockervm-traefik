#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "pyyaml",
#     "tomli",
# ]
# ///

"""Port Conflict Validation Script

This script checks for port conflicts in the Docker Compose configuration.
"""

import re
import sys
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple

import yaml
import tomli


def extract_ports_from_file(filepath: Path) -> List[Tuple[str, str, str]]:
    """Extract port mappings from a compose file.
    
    Returns list of tuples: (host_port, container_port, variable_name or None)
    """
    ports = []
    
    try:
        with open(filepath, 'r') as f:
            content = yaml.safe_load(f)
            
        if not content or 'services' not in content:
            return ports
            
        for service_name, service_config in content.get('services', {}).items():
            if 'ports' in service_config:
                for port_entry in service_config['ports']:
                    if isinstance(port_entry, str):
                        # Match patterns like "8080:8080" or "${VAR}:8080"
                        match = re.match(r'^(\$\{?([A-Z_]+)\}?|(\d+)):(\d+)$', port_entry)
                        if match:
                            if match.group(2):  # Variable
                                ports.append((None, match.group(4), match.group(2)))
                            else:  # Direct port
                                ports.append((match.group(3), match.group(4), None))
                    
    except Exception as e:
        print(f"⚠️  Error reading {filepath}: {e}")
    
    return ports


def load_env_variables() -> Dict[str, str]:
    """Load environment variables from various sources."""
    env_vars = {}
    
    # Load from .env
    if Path('.env').exists():
        with open('.env', 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()
    
    # Load from example.env
    if Path('example.env').exists():
        with open('example.env', 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    if key not in env_vars and value:
                        env_vars[key] = value
    
    # Load from komodo-sync-resources.toml
    if Path('komodo-sync-resources.toml').exists():
        with open('komodo-sync-resources.toml', 'rb') as f:
            toml_data = tomli.load(f)
            
        # Extract environment variables from the environment field
        for stack in toml_data.get('stack', []):
            if 'config' in stack and 'environment' in stack['config']:
                env_string = stack['config']['environment']
                for line in env_string.strip().split('\n'):
                    if '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip()
                        if key not in env_vars:
                            env_vars[key] = value
    
    return env_vars


def main():
    print("🔍 Validating port configuration...")
    
    # Find all compose files
    compose_files = []
    
    # Check docker-compose-prod.yml
    if Path('docker-compose-prod.yml').exists():
        compose_files.append(Path('docker-compose-prod.yml'))
    
    # Check compose directory
    compose_dir = Path('compose')
    if compose_dir.exists():
        compose_files.extend(compose_dir.glob('*.yml'))
        compose_files.extend(compose_dir.glob('*.yaml'))
    
    # Extract all ports
    port_mappings = defaultdict(list)  # port -> [(file, service)]
    variable_ports = []  # [(variable, container_port, file)]
    
    print("\n📋 Scanning compose files for port mappings...")
    for filepath in sorted(compose_files):
        print(f"\n📄 {filepath}:")
        ports = extract_ports_from_file(filepath)
        
        if not ports:
            print("     (no ports exposed)")
            continue
            
        for host_port, container_port, var_name in ports:
            if var_name:
                print(f"     - Variable ${{{var_name}}} → {container_port}")
                variable_ports.append((var_name, container_port, filepath))
            else:
                print(f"     - Port {host_port} → {container_port}")
                port_mappings[host_port].append(str(filepath))
    
    # Check for conflicts
    print(f"\n🔢 Total unique ports found: {len(port_mappings)}")
    
    conflicts = []
    print("\n🔍 Checking for port conflicts...")
    for port, files in port_mappings.items():
        if len(files) > 1:
            conflicts.append((port, files))
    
    if conflicts:
        print("❌ Found port conflicts:")
        for port, files in conflicts:
            print(f"   Port {port} is used in:")
            for file in files:
                print(f"     - {file}")
    else:
        print("✅ No port conflicts detected")
    
    # Check environment variables
    print("\n🔧 Checking port environment variables...")
    env_vars = load_env_variables()
    
    # Expected port variables
    port_vars = [
        "DOZZLE_PORT",
        "NGINX_EXPOSE_PORT",
        "TRAEFIK_HTTP_PORT",
        "TRAEFIK_HTTPS_PORT",
        "TRAEFIK_DASHBOARD_PORT",
        "METRICS_PORT",
        "PORT",  # Flowise
    ]
    
    # Add any variables found in compose files
    for var_name, _, _ in variable_ports:
        if var_name not in port_vars:
            port_vars.append(var_name)
    
    missing_vars = []
    for var in sorted(port_vars):
        if var in env_vars:
            print(f"✅ {var} = {env_vars[var]}")
        else:
            print(f"⚠️  {var} is not defined")
            missing_vars.append(var)
    
    # Display port allocation summary
    print("\n📊 Port Allocation Summary:")
    print("=" * 50)
    print("80    → Traefik (HTTP)")
    print("443   → Traefik (HTTPS)")
    print("3000  → Arcane")
    print("3003  → Hoarder")
    print("3100  → Flowise")
    print("5432  → Windmill PostgreSQL")
    print("8080  → Traefik Dashboard (internal)")
    print("8083  → Traefik Metrics (optional)")
    print("8084  → Dozzle")
    print("8085  → Windmill Caddy")
    print("8086  → Zammad Nginx")
    print("8090  → Beszel Hub")
    print("9001  → Portainer Agent")
    print("9200  → Shuffle OpenSearch (if enabled)")
    print("9898  → Backrest")
    
    # Final summary
    print()
    if conflicts:
        print("❌ Port validation failed - conflicts detected!")
        print("\n💡 Tips to resolve conflicts:")
        print("• Assign unique ports to each service")
        print("• Use environment variables to make ports configurable")
        print("• Consider using Traefik routing instead of exposed ports")
        sys.exit(1)
    else:
        print("✅ Port validation complete - no conflicts found!")
        if missing_vars:
            print(f"\n⚠️  Warning: {len(missing_vars)} environment variable(s) not defined")
        print("\n💡 Tips:")
        print("• Use 'docker ps' to see actual port bindings")
        print("• Check 'netstat -tlnp' to see what's already listening")
        print("• Consider using Traefik labels instead of exposed ports where possible")
        sys.exit(0)


if __name__ == "__main__":
    main()