#!/bin/bash
# Komodo Deployment Validation Script
# This script validates that the repository is ready for Komodo deployment

set -e

echo "🔍 Validating Komodo deployment readiness..."

# Check required files
echo "📋 Checking required files..."
required_files=(
    "docker-compose.yml"
    "komodo-resources.toml"
    ".env.example"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file exists"
    else
        echo "❌ $file is missing"
        exit 1
    fi
done

# Validate docker-compose.yml syntax
echo "🐳 Validating Docker Compose syntax..."
if docker compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose file is valid"
else
    echo "❌ Docker Compose file has syntax errors"
    exit 1
fi

# Check for external network in compose file
echo "🌐 Checking network configuration..."
if grep -q "traefik-proxy:" docker-compose.yml && grep -q "external: true" docker-compose.yml; then
    echo "✅ External network configuration found"
else
    echo "❌ External network 'traefik-proxy' not properly configured"
    exit 1
fi

# Validate TOML syntax (basic check)
echo "📝 Validating TOML configuration..."
if command -v python3 > /dev/null; then
    python3 -c "
import sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib

try:
    with open('komodo-resources.toml', 'rb') as f:
        tomllib.load(f)
    print('✅ TOML file is valid')
except Exception as e:
    print(f'❌ TOML file has errors: {e}')
    sys.exit(1)
" 2>/dev/Null || echo "⚠️  Could not validate TOML (python/tomllib not available)"
else
    echo "⚠️  Could not validate TOML (python not available)"
fi

# Check for placeholder values
echo "🔧 Checking for placeholder values..."
if grep -q "your-server-id" komodo-resources.toml; then
    echo "⚠️  Please update 'your-server-id' in komodo-resources.toml"
fi

if grep -q "basher8383/dockervm-traefik" komodo-resources.toml; then
    echo "⚠️  Consider updating repository path in komodo-resources.toml if this is a fork"
fi

# Check directory structure
echo "📁 Checking directory structure..."
required_dirs=(
    "config"
    "scripts"
    "letsencrypt"
    "logs"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "✅ $dir directory exists"
    else
        echo "❌ $dir directory is missing"
        exit 1
    fi
done

# Check for sensitive files in git
echo "🔒 Checking for sensitive files..."
if git check-ignore .env > /dev/null 2>&1; then
    echo "✅ .env is properly ignored"
else
    echo "⚠️  .env might not be ignored by git"
fi

if [[ -f "letsencrypt/acme.json" ]] && ! git check-ignore letsencrypt/acme.json > /dev/null 2>&1; then
    echo "❌ acme.json should be ignored by git"
    exit 1
else
    echo "✅ SSL certificates are properly ignored"
fi

echo ""
echo "🎉 Validation complete!"
echo ""
echo "📝 Next steps for Komodo deployment:"
echo "1. Update 'server_id' in komodo-resources.toml"
echo "2. Create ResourceSync in Komodo UI pointing to this repository"
echo "3. Set resource path to 'komodo-resources.toml'"
echo "4. Refresh ResourceSync and review changes"
echo "5. Apply the deployment"
echo ""
echo "🔗 For more information, see: https://github.com/moghtech/komodo"

# Check for optional metrics configuration
echo "📊 Checking metrics configuration..."
if grep -q "METRICS_ENABLED" .env.example && grep -q "metrics.prometheus" docker-compose.yml; then
    echo "✅ Metrics configuration available"
else
    echo "⚠️  Metrics configuration might be missing"
fi

# Check for resource limits
echo "💾 Checking resource limits..."
if grep -q "TRAEFIK_CPU_LIMIT" .env.example && grep -q "deploy:" docker-compose.yml; then
    echo "✅ Resource limits configuration found"
else
    echo "⚠️  Resource limits configuration might be missing"
fi

# Check for health check configuration in TOML
echo "🏥 Checking health check configuration..."
if grep -q "health_check" komodo-resources.toml; then
    echo "✅ Health check configuration found"
else
    echo "⚠️  Health check configuration might be missing"
fi
