# TODO: Deployment Issues for Dockervm-Traefik Stack

## Overview

This document outlines remaining issues identified during the comprehensive repository analysis for the Komodo resource sync deployment of the Docker stack. Issues are categorized by severity and type.

## 🚨 CRITICAL: Port Conflicts ✅ RESOLVED

### ~~Confirmed Port Conflicts~~ FIXED

1. **Port 8080** - ~~Multiple services attempting to use:~~ RESOLVED
   - Traefik dashboard (internal): 8080 ✅
   - Dozzle: `$DOZZLE_PORT:8080` → Now uses port 8084 ✅
   - Zammad nginx: `${NGINX_EXPOSE_PORT:-8080}:${NGINX_PORT:-8080}` → Now uses port 8086 externally ✅

### ~~Undefined Port Variables~~ ✅ RESOLVED

~~The following services use undefined environment variables for ports:~~ ALL DEFINED

- **Dozzle**: `$DOZZLE_PORT` → Now defined as 8084 ✅
- **Flowise**: `$PORT` → Now defined as 3100 ✅
- **Shuffle**: (Service removed from project) ✅

### Current Port Allocation

```
80       - Traefik (HTTP)
443      - Traefik (HTTPS)
8080     - Traefik Dashboard / Zammad / Dozzle (CONFLICT!)
8090     - Beszel Hub
9001     - Portainer Agent
9898     - Backrest
3000     - Arcane
3003     - Hoarder
5432     - Windmill PostgreSQL
8085     - Windmill Caddy
25       - Windmill Caddy (SMTP)
9200     - Shuffle OpenSearch
```

## ⚠️ IMPORTANT: ~~Missing Environment Variables~~ ✅ RESOLVED

~~The following variables are used but not defined in komodo-sync-resources.toml or example.env:~~ ALL DEFINED

- `DOZZLE_PORT` → Now defined as 8084 ✅
- `DOCKER_HOST` → Now defined as tcp://socket-proxy:2375 ✅
- `PORT` (Flowise) → Now defined as 3100 ✅

- `WM_IMAGE`, `DATABASE_URL` (Windmill) ✅

- `PUBLIC_SESSION_SECRET` (Arcane - used but not in example.env) **This is a secret not env variable**
- `SCALR_API_TOKEN` (Scalr - used but not in example.env) **This is a secret not env variable**

### Undefined Volume Variables

**Shuffle removed from the project**

- `OUTER_HOSTNAME` (Shuffle)
- `SHUFFLE_APP_HOTLOAD_LOCATION`, `SHUFFLE_FILE_LOCATION`, `DB_LOCATION`

1. **Shuffle** (compose/shuffle.yml):
   - `${SHUFFLE_APP_HOTLOAD_LOCATION}`
   - `${SHUFFLE_FILE_LOCATION}`
   - `${DB_LOCATION}`

## 🔧 Configuration Issues

### ~~Docker Socket Access~~ ✅ RESOLVED

~~Multiple services directly mount docker.sock instead of using the socket-proxy:~~ ALL CONFIGURED TO USE SOCKET-PROXY

- Windmill worker ✅
- ~~Shuffle (backend, orborus)~~ (Service removed) ✅
- Portainer agent ✅
- Arcane ✅
- Terraform agent ✅
- Scalr agent ✅

**Security Risk**: ~~Direct docker socket access should be proxied through socket-proxy.~~ RESOLVED - All services now use socket-proxy ✅

### Network Configuration

1. **Inconsistent network usage**:

   - Some services use `traefik-proxy` network
   - Some use `socket-proxy` network
   - Some use default network
   - Some define their own networks (shuffle)

2. **Missing network declarations**:
   - Dozzle references `socket_proxy` network but it's not properly configured

## 📋 Action Items

### ~~High Priority~~ ✅ COMPLETED

1. **Resolve port 8080 conflict** between Traefik, Dozzle, and Zammad ✅
2. **Define all missing environment variables** in komodo-sync-resources.toml ✅
3. ~~**Define missing volume path variables** for Shuffle service~~ (Service removed) ✅

### ~~Medium Priority~~ ✅ COMPLETED

1. **Configure all services to use socket-proxy** instead of direct docker socket ✅
2. **Standardize network configuration** across all services ✅

### ~~Low Priority~~ ✅ COMPLETED

1. **Document port allocation** in a central location ✅ (See docs/PORT-ALLOCATION.md)
2. **Create comprehensive example.env** with all required variables ✅
3. **Add validation script** to check for port conflicts before deployment ✅
   - Created `scripts/validate-ports.sh` for port conflict checking
   - Created `scripts/validate-deployment.sh` for comprehensive validation

## 🔍 Validation Checklist

Before deployment, ensure:

- [x] All port conflicts resolved ✅
- [x] All required environment variables defined ✅
- [x] Network configuration is consistent ✅
- [x] Docker socket access is properly secured ✅
- [x] Komodo sync configuration matches actual file structure ✅

## 🎉 Summary of Completed Tasks

1. **Port Conflicts**: Resolved all port 8080 conflicts by assigning unique ports:
   - Dozzle: 8084
   - Zammad: 8086 (external)
   - Traefik Dashboard: 8080 (internal)

2. **Environment Variables**: Added all missing variables to both `example.env` and `komodo-sync-resources.toml`:
   - DOZZLE_PORT=8084
   - DOCKER_HOST=tcp://socket-proxy:2375
   - PORT=3100 (Flowise)
   - NGINX_EXPOSE_PORT=8086
   - NGINX_PORT=8080

3. **Socket Proxy Security**: Configured all services to use socket-proxy instead of direct Docker socket mounting

4. **Network Standardization**: All services now properly use the socket-proxy network

5. **Documentation**: Created comprehensive port allocation documentation at `docs/PORT-ALLOCATION.md`

## ✅ All Tasks Completed!

All deployment issues have been resolved:
- ✅ Port conflicts resolved
- ✅ Environment variables defined
- ✅ Docker socket security configured
- ✅ Network configuration standardized
- ✅ Documentation created
- ✅ Validation scripts added

### 🚀 Ready for Deployment

Run the validation scripts before deploying:
```bash
# Run comprehensive validation
./scripts/validate-deployment.sh

# Or run individual checks:
./scripts/validate-komodo.sh    # Komodo configuration
./scripts/validate-ports.sh      # Port conflicts
```
