# Port Allocation for Dockervm-Traefik Stack

## Overview

This document provides a comprehensive overview of all ports used by services in the dockervm-traefik stack.

## Port Assignments

| Port | Service | Description |
|------|---------|-------------|
| 80 | Traefik | HTTP entrypoint |
| 443 | Traefik | HTTPS entrypoint |
| 3000 | Arcane | Docker management UI |
| 3003 | Hoarder | Bookmark manager |
| 3100 | Flowise | Low-code LLM apps builder |
| 5432 | Windmill PostgreSQL | Database for Windmill |
| 8080 | Traefik | Dashboard (internal port) |
| 8083 | Traefik | Metrics endpoint (optional) |
| 8084 | Dozzle | Real-time Docker log viewer |
| 8085 | Windmill Caddy | Windmill web server |
| 8086 | Zammad Nginx | Helpdesk web interface |
| 8090 | Beszel Hub | System monitoring |
| 9001 | Portainer Agent | Container management agent |
| 9200 | Shuffle OpenSearch | Shuffle search backend |
| 9898 | Backrest | Web UI for restic |

## Network Configuration

### Docker Networks

1. **traefik-proxy**: External network for services exposed through Traefik
2. **socket-proxy**: Internal network for Docker socket access (10.91.0.0/24)
   - Socket proxy IP: 10.91.0.254

### Socket Proxy Configuration

All services requiring Docker access should connect through the socket-proxy service using:
- `DOCKER_HOST=tcp://socket-proxy:2375`

Services configured to use socket-proxy:
- Traefik
- Dozzle
- Windmill Worker
- Arcane
- Terraform Agent
- Scalr Agent
- Portainer Agent

## Environment Variables

### Required Variables
- `DOMAIN`: Base domain for services
- `LETSENCRYPT_EMAIL`: Email for SSL certificates
- `TZ`: Timezone
- `TRAEFIK_VERSION`: Traefik version to use
- `DOZZLE_PORT`: Port for Dozzle (8084)
- `DOCKER_HOST`: Docker socket proxy URL (tcp://socket-proxy:2375)
- `PORT`: Flowise port (3100)
- `NGINX_EXPOSE_PORT`: Zammad external port (8086)
- `NGINX_PORT`: Zammad internal port (8080)

### Optional Variables
- `SSL_ENABLED`: Enable SSL (default: true)
- `TRAEFIK_CPU_LIMIT`: CPU limit for Traefik
- `TRAEFIK_MEMORY_LIMIT`: Memory limit for Traefik
- `METRICS_ENABLED`: Enable Prometheus metrics
- `METRICS_PORT`: Port for metrics endpoint

## Security Notes

1. **Never expose Docker socket directly** - Always use socket-proxy
2. **Use Traefik labels** for service exposure instead of direct port mapping when possible
3. **Keep internal services** on private networks without external port exposure