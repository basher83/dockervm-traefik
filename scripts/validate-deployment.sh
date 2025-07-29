#!/bin/bash
# Comprehensive Deployment Validation Script
# This script runs all validation checks before deployment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Running comprehensive deployment validation..."
echo "================================================"

# Track overall status
VALIDATION_PASSED=true

# Function to run a validation script
run_validation() {
    local script=$1
    local description=$2
    
    echo ""
    echo "📋 $description"
    echo "-------------------------------------------"
    
    if [[ -x "$script" ]]; then
        if "$script"; then
            echo -e "${GREEN}✅ $description passed${NC}"
        else
            echo -e "${RED}❌ $description failed${NC}"
            VALIDATION_PASSED=false
        fi
    else
        echo -e "${YELLOW}⚠️  $script not found or not executable${NC}"
        VALIDATION_PASSED=false
    fi
}

# Run all validation checks
run_validation "scripts/validate-komodo.sh" "Komodo configuration validation"
run_validation "scripts/validate-ports.py" "Port conflict validation"

# Additional checks
echo ""
echo "📋 Docker Socket Proxy Security Check"
echo "-------------------------------------------"

# Check if services are using socket-proxy
services_using_direct_socket=$(grep -r "docker.sock:/var/run/docker.sock" compose/*.yml 2>/dev/null | grep -v "socket-proxy.yml" | grep -v "#" || true)

if [[ -z "$services_using_direct_socket" ]]; then
    echo -e "${GREEN}✅ All services use socket-proxy${NC}"
else
    echo -e "${YELLOW}⚠️  Some services might still use direct docker socket:${NC}"
    echo "$services_using_direct_socket"
fi

# Check network configuration
echo ""
echo "📋 Network Configuration Check"
echo "-------------------------------------------"

# Check if socket-proxy network is defined
if grep -q "socket-proxy:" docker-compose-prod.yml 2>/dev/null && \
   grep -q "10.91.0.0/24" docker-compose-prod.yml 2>/dev/null; then
    echo -e "${GREEN}✅ Socket-proxy network is properly configured${NC}"
else
    echo -e "${RED}❌ Socket-proxy network configuration missing${NC}"
    VALIDATION_PASSED=false
fi

# Check if traefik-proxy network will be created
if grep -q "docker network create traefik-proxy" komodo-sync-resources.toml 2>/dev/null; then
    echo -e "${GREEN}✅ Traefik-proxy network creation configured${NC}"
else
    echo -e "${YELLOW}⚠️  Traefik-proxy network creation not found in pre-deploy${NC}"
fi

# Environment variable check
echo ""
echo "📋 Environment Variables Check"
echo "-------------------------------------------"

required_vars=(
    "DOMAIN"
    "LETSENCRYPT_EMAIL"
    "DOCKER_HOST"
    "DOZZLE_PORT"
    "NGINX_EXPOSE_PORT"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" komodo-sync-resources.toml 2>/dev/null && \
       ! grep -q "^${var}=" example.env 2>/dev/null; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ All required environment variables are defined${NC}"
else
    echo -e "${RED}❌ Missing environment variables: ${missing_vars[*]}${NC}"
    VALIDATION_PASSED=false
fi

# Final summary
echo ""
echo "================================================"
if [[ "$VALIDATION_PASSED" == "true" ]]; then
    echo -e "${GREEN}✅ All validation checks passed!${NC}"
    echo ""
    echo "🎉 Your deployment is ready! Next steps:"
    echo "1. Review the configuration one more time"
    echo "2. Deploy using Komodo"
    echo "3. Monitor the deployment logs"
    exit 0
else
    echo -e "${RED}❌ Some validation checks failed!${NC}"
    echo ""
    echo "⚠️  Please fix the issues above before deploying."
    exit 1
fi