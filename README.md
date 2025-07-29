# dockervm-traefik

A production-ready Traefik reverse proxy setup optimized for deployment via Komodo. This configuration provides SSL termination, Docker socket security, automatic certificate management, and includes multiple pre-configured services.

## Features

- **Traefik 3.3** reverse proxy with automatic HTTPS
- **Socket Proxy** for secure Docker API access (all services configured)
- **Let's Encrypt** automatic SSL certificate management
- **Log Rotation** with automated cleanup
- **Security Middleware** with rate limiting and headers
- **Komodo Integration** for Infrastructure as Code deployment
- **Pre-configured Services**: Dozzle, Windmill, Arcane, Zammad, and more
- **Validation Scripts** for deployment readiness checks

## Deployment via Komodo

### Prerequisites

1. **Komodo Server**: Ensure you have a Komodo server configured with a Periphery agent
2. **Docker Network**: The `traefik-proxy` network will be created automatically
3. **Domain**: Configure your domain to point to the server running this stack

### Quick Deployment

1. **Validate Configuration**:
   ```bash
   # Run comprehensive validation
   ./scripts/validate-deployment.sh
   
   # Or run individual checks
   ./scripts/validate-ports.py      # Check for port conflicts
   ./scripts/validate-komodo.sh     # Validate Komodo configuration
   ```

2. **Update Resource Configuration**:

   - Edit `komodo-sync-resources.toml`
   - Replace `server_id = "dockervm"` with your actual Komodo server name
   - Update git repository path if forked

3. **Create ResourceSync in Komodo**:

   - Navigate to Komodo UI → Resources → Syncs
   - Create new Sync pointing to this repository
   - Set resource path to `komodo-sync-resources.toml`
   - Configure Git provider credentials if repository is private

4. **Deploy**:
   - Refresh the Sync to detect changes
   - Review and apply the pending changes
   - Monitor deployment status in Komodo dashboard

### Environment Configuration

The stack uses environment variables for configuration. Key variables:

| Variable                 | Description                    | Default                             |
| ------------------------ | ------------------------------ | ----------------------------------- |
| `DOMAIN`                 | Your domain name               | `lab.spaceships.work`               |
| `LETSENCRYPT_EMAIL`      | Email for Let's Encrypt        | `admin@lab.spaceships.work`         |
| `TRAEFIK_HTTP_PORT`      | HTTP port binding              | `8081`                              |
| `TRAEFIK_HTTPS_PORT`     | HTTPS port binding             | `8443`                              |
| `TRAEFIK_DASHBOARD_PORT` | Dashboard port                 | `8082`                              |
| `DOZZLE_PORT`            | Dozzle log viewer port         | `8084`                              |
| `DOCKER_HOST`            | Docker socket proxy URL        | `tcp://socket-proxy:2375`           |
| `NGINX_EXPOSE_PORT`      | Zammad external port           | `8086`                              |
| `PORT`                   | Flowise port                   | `3100`                              |
| `DATABASE_URL`           | Windmill database connection   | `postgres://postgres:changeme@db/windmill?sslmode=disable` |

All environment variables are pre-configured in `komodo-sync-resources.toml` and will be applied during deployment.

## Configuration

### Traefik Configuration

Traefik is configured via:

- **Command line arguments** in `compose/traefik.yml`
- **Dynamic configuration** files in `./appdata/traefik/rules/`
- **Environment variables** for runtime settings
- **Middleware chains** in `./appdata/traefik/rules/middlewares-*.yml`

### Security Features

- **Socket Proxy**: Isolates Docker API access with minimal permissions
- **Security Headers**: HSTS, referrer policy, and custom headers
- **Rate Limiting**: Configurable request rate limits
- **Basic Auth**: Optional authentication for services

### SSL/TLS

- **Automatic Certificates**: Let's Encrypt HTTP challenge
- **TLS Options**: Modern TLS configuration in `appdata/traefik/rules/tls-opts.yml`
- **Certificate Storage**: Persistent storage in `appdata/traefik/acme/acme.json`

## Included Services

The stack includes several pre-configured services:

| Service | Port | Description |
| ------- | ---- | ----------- |
| Traefik | 80, 443, 8080 | Reverse proxy and SSL termination |
| Socket Proxy | Internal | Secure Docker API access |
| Dozzle | 8084 | Real-time Docker log viewer |
| Windmill | 8085 | Workflow automation platform |
| Arcane | 3000 | Docker management UI |
| Zammad | 8086 | Helpdesk/ticketing system |
| Beszel Hub | 8090 | System monitoring |
| Hoarder | 3003 | Bookmark manager |
| Backrest | 9898 | Web UI for restic backups |
| Portainer Agent | 9001 | Container management agent |

All services are configured to use the socket proxy for Docker access instead of direct socket mounting.

## Monitoring and Maintenance

### Access Points

- **Traefik Dashboard**: `https://traefik.yourdomain.com`
- **Services**: Accessible via configured subdomains (e.g., `https://dozzle.yourdomain.com`)

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

## Troubleshooting

### Common Issues

1. **Certificate Issues**: Check domain DNS and Let's Encrypt rate limits
2. **Network Conflicts**: Ensure `traefik-proxy` network doesn't conflict
3. **Port Conflicts**: Run `./scripts/validate-ports.py` to check for conflicts
4. **Permissions**: Check Docker socket permissions for socket-proxy
5. **Service Conflicts**: Ensure no services are using the same ports (see Port Allocation documentation)

### Logs

```bash
# View Traefik logs
docker logs traefik

# View all stack logs
docker compose -f docker-compose-prod.yml logs -f

# Check specific service
docker logs socket-proxy

# Use Dozzle for real-time log viewing
# Access at http://localhost:8084 or https://dozzle.yourdomain.com
```

### Validation Scripts

Before deployment, use the validation scripts:

```bash
# Comprehensive validation
./scripts/validate-deployment.sh

# Check for port conflicts
./scripts/validate-ports.py

# Validate Komodo configuration
./scripts/validate-komodo.sh
```

## Documentation

- **Port Allocation**: See `docs/PORT-ALLOCATION.md` for complete port mapping
- **Deployment Issues**: See `docs/TODO-DEPLOYMENT-ISSUES.md` for resolved issues and solutions

## Contributing

This repository is configured for Komodo deployment. When making changes:

1. Run validation scripts before committing
2. Test changes locally first
3. Update `komodo-sync-resources.toml` if configuration changes
4. Ensure all services use socket-proxy instead of direct Docker socket
5. Update documentation as needed
6. Verify no port conflicts with existing services

## License

MIT License - see LICENSE file for details
