# dockervm-traefik

A production-ready Traefik reverse proxy setup optimized for deployment via Komodo. This configuration provides SSL termination, Docker socket security, automatic certificate management, and log rotation.

## Features

- **Traefik 3.3** reverse proxy with automatic HTTPS
- **Socket Proxy** for secure Docker API access
- **Let's Encrypt** automatic SSL certificate management
- **Log Rotation** with automated cleanup
- **Security Middleware** with rate limiting and headers
- **Komodo Integration** for Infrastructure as Code deployment

## Deployment via Komodo

### Prerequisites

1. **Komodo Server**: Ensure you have a Komodo server configured with a Periphery agent
2. **Docker Network**: The `traefik-proxy` network will be created automatically
3. **Domain**: Configure your domain to point to the server running this stack

### Quick Deployment

1. **Update Resource Configuration**:
   ```bash
   # Edit komodo-resources.toml
   # Replace 'your-server-id' with your actual Komodo server ID
   # Update git repository path if forked
   ```

2. **Create ResourceSync in Komodo**:
   - Navigate to Komodo UI → Resources → ResourceSync
   - Create new ResourceSync pointing to this repository
   - Set resource path to `komodo-resources.toml`
   - Configure Git provider credentials if repository is private

3. **Deploy**:
   - Refresh the ResourceSync to detect changes
   - Review and apply the pending changes
   - Monitor deployment status in Komodo dashboard

### Environment Configuration

The stack uses environment variables for configuration. Key variables:

| Variable | Description | Default |
|----------|-------------|----------|
| `DOMAIN` | Your domain name | `lab.spaceships.work` |
| `LETSENCRYPT_EMAIL` | Email for Let's Encrypt | `admin@lab.spaceships.work` |
| `TRAEFIK_HTTP_PORT` | HTTP port binding | `8081` |
| `TRAEFIK_HTTPS_PORT` | HTTPS port binding | `8443` |
| `TRAEFIK_DASHBOARD_PORT` | Dashboard port | `8082` |

### Manual Deployment (Alternative)

If not using Komodo, you can deploy manually:

```bash
# Clone repository
git clone https://github.com/basher8383/dockervm-traefik.git
cd dockervm-traefik

# Create environment file
cp .env.example .env
# Edit .env with your configuration

# Create external network
docker network create traefik-proxy --driver bridge --attachable

# Deploy stack
docker compose up -d
```

## Configuration

### Traefik Configuration

Traefik is configured via:
- **Command line arguments** in `docker-compose.yml`
- **Dynamic configuration** files in `./config/`
- **Environment variables** for runtime settings

### Security Features

- **Socket Proxy**: Isolates Docker API access with minimal permissions
- **Security Headers**: HSTS, referrer policy, and custom headers
- **Rate Limiting**: Configurable request rate limits
- **Basic Auth**: Optional authentication for services

### SSL/TLS

- **Automatic Certificates**: Let's Encrypt HTTP challenge
- **TLS Options**: Modern TLS configuration in `config/tls-opts.yml`
- **Certificate Storage**: Persistent storage in `letsencrypt/acme.json`

## Monitoring and Maintenance

### Access Points

- **Traefik Dashboard**: `https://traefik.yourdomain.com`
- **Services**: Configured via labels on other containers

### Log Management

- **Access Logs**: JSON format in `./logs/access.log`
- **Application Logs**: JSON format in `./logs/traefik.log`
- **Log Rotation**: Automated daily rotation, 7-day retention

### Health Monitoring

When deployed via Komodo:
- Container health is monitored automatically
- Alerts can be configured for service failures
- Resource usage is tracked and displayed

## Integration with Other Services

This Traefik setup is designed to work with other containerized services. To integrate a service:

1. **Connect to Network**:
   ```yaml
   networks:
     - traefik-proxy
   ```

2. **Add Traefik Labels**:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.myapp.rule=Host(`myapp.yourdomain.com`)"
     - "traefik.http.routers.myapp.entrypoints=websecure"
     - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
   ```


## Migration from Other Proxies

### From Caddy

If you're migrating from Caddy to this Traefik setup:

1. **Export existing routes**:
   ```bash
   # Document your current Caddyfile routes
   cat Caddyfile > caddy_backup.txt
   ```

2. **Convert Caddyfile rules to Traefik labels**:
   ```yaml
   # Caddy: example.com
   # Traefik equivalent:
   labels:
     - "traefik.http.routers.myapp.rule=Host(`example.com`)"
     - "traefik.http.routers.myapp.entrypoints=websecure"
     - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
   ```

3. **Update port mappings**:
   - Caddy typically uses ports 80/443
   - This setup uses 8081/8443 by default
   - Update your firewall/load balancer accordingly

4. **Certificate migration**:
   - Let's Encrypt certificates will need to be re-issued
   - Consider timing the migration during low-traffic periods

### From nginx-proxy

For nginx-proxy users:

1. **Environment variable mapping**:
   ```bash
   # nginx-proxy: VIRTUAL_HOST=example.com
   # Traefik: traefik.http.routers.myapp.rule=Host(`example.com`)
   ```

2. **SSL certificate handling**:
   - nginx-proxy-companion → Traefik's built-in Let's Encrypt
   - Automatic certificate renewal is handled by Traefik

### From Haproxy

1. **Backend configuration**:
   - HAProxy backends → Traefik service discovery via Docker labels
   - Health checks → Traefik's automatic health monitoring

2. **Load balancing**:
   - HAProxy balance algorithms → Traefik middleware configuration
   - Sticky sessions → Configure via Traefik labels

### General Migration Steps

1. **Preparation**:
   ```bash
   # Backup existing configuration
   docker compose down
   cp -r /path/to/old/proxy /backup/location/
   ```

2. **Deploy Traefik stack**:
   ```bash
   # Deploy this stack
   docker network create traefik-proxy --driver bridge --attachable
   docker compose up -d
   ```

3. **Migrate services one by one**:
   ```bash
   # Update each service's docker-compose.yml
   # Add Traefik labels and connect to traefik-proxy network
   ```

4. **Update DNS/Load Balancer**:
   ```bash
   # Point your domain to new ports (8081/8443)
   # Or update upstream load balancer configuration
   ```

5. **Verify and cleanup**:
   ```bash
   # Test all services are accessible
   # Remove old proxy containers
   # Clean up unused networks/volumes
   ```


## Troubleshooting

### Common Issues

1. **Certificate Issues**: Check domain DNS and Let's Encrypt rate limits
2. **Network Conflicts**: Ensure `traefik-proxy` network doesn't conflict
3. **Port Conflicts**: Verify ports 8081, 8443, 8082 are available
4. **Permissions**: Check Docker socket permissions for socket-proxy

### Logs

```bash
# View Traefik logs
docker logs traefik

# View all stack logs
docker compose logs -f

# Check specific service
docker logs socket-proxy
```

## Contributing

This repository is configured for Komodo deployment. When making changes:

1. Test changes locally first
2. Update `komodo-resources.toml` if configuration changes
3. Ensure changes are compatible with Komodo ResourceSync
4. Update documentation as needed

## License

MIT License - see LICENSE file for details
