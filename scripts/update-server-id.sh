#!/bin/bash
# Quick script to update server ID in komodo-resources.toml

if [ $# -eq 0 ]; then
    echo "Usage: $0 <server-id>"
    echo ""
    echo "Find your server ID in Komodo UI:"
    echo "1. Go to Resources → Servers"
    echo "2. Click on your target server"
    echo "3. Copy the ID from the URL or details panel"
    echo ""
    echo "Example: $0 507f1f77bcf86cd799439011"
    exit 1
fi

SERVER_ID="$1"

if [ ! -f "komodo-resources.toml" ]; then
    echo "❌ komodo-resources.toml not found in current directory"
    exit 1
fi

# Create backup
cp komodo-resources.toml komodo-resources.toml.backup
echo "📄 Created backup: komodo-resources.toml.backup"

# Update server ID
if grep -q "your-server-id" komodo-resources.toml; then
    sed -i.tmp "s/your-server-id/$SERVER_ID/g" komodo-resources.toml
    rm komodo-resources.toml.tmp 2>/dev/null || true
    echo "✅ Updated server_id to: $SERVER_ID"
    echo ""
    echo "📋 Updated configuration:"
    grep -A 1 -B 1 "server_id.*=.*$SERVER_ID" komodo-resources.toml
else
    echo "⚠️  Placeholder 'your-server-id' not found. Manual update may be needed."
    echo "Current server_id line:"
    grep "server_id" komodo-resources.toml || echo "No server_id line found"
fi

echo ""
echo "🎉 Ready for deployment! Next steps:"
echo "1. Create ResourceSync in Komodo UI"
echo "2. Point it to repository: basher83/dockervm-traefik"
echo "3. Set resource path to: komodo-resources.toml"
echo "4. Refresh and apply the changes"
