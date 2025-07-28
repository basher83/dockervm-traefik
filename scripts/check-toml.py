#!/usr/bin/env python3
"""
Simple TOML validator for Komodo resources
This script validates the structure and content of komodo-resources.toml
"""

import sys
import os

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("❌ Error: Neither tomllib nor tomli is available")
        print("Install tomli: pip install tomli")
        sys.exit(1)

def validate_toml(filename):
    """Validate TOML file structure for Komodo resources"""
    
    if not os.path.exists(filename):
        print(f"❌ File {filename} not found")
        return False
    
    try:
        with open(filename, 'rb') as f:
            data = tomllib.load(f)
        print("✅ TOML syntax is valid")
    except Exception as e:
        print(f"❌ TOML syntax error: {e}")
        return False
    
    # Validate structure
    if 'stack' not in data:
        print("❌ No [[stack]] section found")
        return False
    
    stacks = data['stack'] if isinstance(data['stack'], list) else [data['stack']]
    
    for i, stack in enumerate(stacks):
        print(f"\n📦 Validating stack {i + 1}: {stack.get('name', 'unnamed')}")
        
        # Check required fields
        required_fields = ['name', 'config']
        for field in required_fields:
            if field not in stack:
                print(f"❌ Missing required field: {field}")
                return False
            else:
                print(f"✅ {field}: {stack[field] if field != 'config' else 'present'}")
        
        # Check config section
        config = stack['config']
        required_config_fields = ['server_id', 'repo']
        
        for field in required_config_fields:
            if field not in config:
                print(f"❌ Missing required config field: {field}")
                return False
            else:
                value = config[field]
                if field == 'server_id' and value == 'your-server-id':
                    print(f"⚠️  {field}: {value} (needs to be updated)")
                else:
                    print(f"✅ {field}: {value}")
        
        # Check optional but important fields
        optional_fields = {
            'git_provider': 'github',
            'branch': 'main',
            'file_paths': ['docker-compose.yml'],
            'environment': 'configured'
        }
        
        for field, default in optional_fields.items():
            if field in config:
                value = config[field]
                if field == 'environment':
                    print(f"✅ {field}: {'configured' if value else 'empty'}")
                else:
                    print(f"✅ {field}: {value}")
            else:
                print(f"⚠️  {field}: not set (default: {default})")
        
        # Check pre_deploy structure
        if 'pre_deploy' in config:
            pre_deploy = config['pre_deploy']
            if isinstance(pre_deploy, dict):
                if 'command' in pre_deploy:
                    print(f"✅ pre_deploy command: {pre_deploy['command'][:50]}...")
                else:
                    print("❌ pre_deploy missing 'command' field")
                    return False
            else:
                print("❌ pre_deploy should be a SystemCommand object with 'path' and 'command' fields")
                return False
    
    print("\n🎉 TOML validation passed!")
    return True

if __name__ == "__main__":
    filename = sys.argv[1] if len(sys.argv) > 1 else "komodo-resources.toml"
    
    print(f"🔍 Validating {filename}...")
    
    if validate_toml(filename):
        print("\n✅ Ready for Komodo deployment!")
        sys.exit(0)
    else:
        print("\n❌ Please fix the issues above before deploying")
        sys.exit(1)
