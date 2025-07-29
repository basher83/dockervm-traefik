#!/bin/bash
# Port Conflict Validation Script
# This script checks for port conflicts in the Docker Compose configuration

set -euo pipefail

echo "🔍 Validating port configuration..."

# Arrays to store port mappings
declare -A port_services
declare -A port_files
all_ports=()

# Function to extract and process ports from a file
process_ports() {
    local file=$1
    local service_name=$(basename "$file" .yml)
    
    # Find lines with port mappings
    while IFS= read -r line; do
        # Match patterns like "- 8080:8080" or "- '8080:8080'" or "- \"8080:8080\""
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*[\"\'\`]?([0-9]+):([0-9]+)[\"\'\`]?[[:space:]]*$ ]]; then
            local host_port="${BASH_REMATCH[1]}"
            local container_port="${BASH_REMATCH[2]}"
            
            # Store the port mapping
            if [[ -n "${port_services[$host_port]:-}" ]]; then
                port_services[$host_port]="${port_services[$host_port]}, $service_name"
            else
                port_services[$host_port]="$service_name"
                all_ports+=("$host_port")
            fi
            port_files[$host_port]="$file"
            
            echo "     - Port $host_port → $container_port"
        fi
        
        # Also check for variable-based ports like ${DOZZLE_PORT}:8080
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*[\"\'\`]?\$\{?([A-Z_]+)\}?:([0-9]+)[\"\'\`]?[[:space:]]*$ ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local container_port="${BASH_REMATCH[2]}"
            echo "     - Variable \${$var_name} → $container_port"
        fi
    done < "$file"
}

# Get all compose files
echo "📋 Scanning compose files for port mappings..."
echo ""

# Process docker-compose-prod.yml if it exists
if [[ -f "docker-compose-prod.yml" ]]; then
    echo "📄 docker-compose-prod.yml:"
    process_ports "docker-compose-prod.yml"
fi

# Process compose directory files
for file in compose/*.yml compose/*.yaml; do
    if [[ -f "$file" ]]; then
        echo "📄 $file:"
        process_ports "$file"
    fi
done

echo ""
echo "🔢 Total unique ports found: ${#all_ports[@]}"
echo ""

# Check for conflicts
conflicts_found=false
echo "🔍 Checking for port conflicts..."
for port in "${!port_services[@]}"; do
    service_count=$(echo "${port_services[$port]}" | tr ',' '\n' | wc -l)
    if [[ $service_count -gt 1 ]]; then
        if [[ "$conflicts_found" == "false" ]]; then
            echo "❌ Found port conflicts:"
            conflicts_found=true
        fi
        echo "   Port $port is used by: ${port_services[$port]}"
    fi
done

if [[ "$conflicts_found" == "false" ]]; then
    echo "✅ No port conflicts detected"
fi

# Check environment variables
echo ""
echo "🔧 Checking port environment variables..."

# Define expected port variables
port_vars=(
    "DOZZLE_PORT"
    "NGINX_EXPOSE_PORT"
    "TRAEFIK_HTTP_PORT"
    "TRAEFIK_HTTPS_PORT"
    "TRAEFIK_DASHBOARD_PORT"
    "METRICS_PORT"
    "PORT"  # Flowise
)

# Check if variables are defined
for var in "${port_vars[@]}"; do
    found=false
    
    # Check in .env
    if [[ -f ".env" ]] && grep -q "^${var}=" .env 2>/dev/null; then
        value=$(grep "^${var}=" .env | cut -d'=' -f2)
        echo "✅ $var = $value (.env)"
        found=true
    # Check in example.env
    elif [[ -f "example.env" ]] && grep -q "^${var}=" example.env 2>/dev/null; then
        value=$(grep "^${var}=" example.env | cut -d'=' -f2 | tr -d ' ')
        if [[ -n "$value" ]]; then
            echo "✅ $var = $value (example.env)"
            found=true
        fi
    # Check in komodo-sync-resources.toml
    elif [[ -f "komodo-sync-resources.toml" ]] && grep -q "^${var}=" komodo-sync-resources.toml 2>/dev/null; then
        value=$(grep "^${var}=" komodo-sync-resources.toml | cut -d'=' -f2)
        echo "✅ $var = $value (komodo-sync-resources.toml)"
        found=true
    fi
    
    if [[ "$found" == "false" ]]; then
        echo "⚠️  $var is not defined"
    fi
done

# Display port allocation summary
echo ""
echo "📊 Port Allocation Summary:"
echo "========================="
echo "80    → Traefik (HTTP)"
echo "443   → Traefik (HTTPS)"
echo "3000  → Arcane"
echo "3003  → Hoarder"
echo "3100  → Flowise"
echo "5432  → Windmill PostgreSQL"
echo "8080  → Traefik Dashboard (internal)"
echo "8083  → Traefik Metrics (optional)"
echo "8084  → Dozzle"
echo "8085  → Windmill Caddy"
echo "8086  → Zammad Nginx"
echo "8090  → Beszel Hub"
echo "9001  → Portainer Agent"
echo "9200  → Shuffle OpenSearch (if enabled)"
echo "9898  → Backrest"

echo ""
if [[ "$conflicts_found" == "true" ]]; then
    echo "❌ Port validation failed - conflicts detected!"
    exit 1
else
    echo "✅ Port validation complete - no conflicts found!"
fi

echo ""
echo "💡 Tips:"
echo "• Use 'docker ps' to see actual port bindings"
echo "• Check 'netstat -tlnp' to see what's already listening"
echo "• Consider using Traefik labels instead of exposed ports where possible"