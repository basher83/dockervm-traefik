# Komodo Deployment Troubleshooting Guide

This guide helps resolve common issues when deploying dockervm-traefik via Komodo.

## 🚨 Common Errors and Solutions

### Error: "missing field `res` at line 1 column X"

This error typically indicates a version compatibility issue between Komodo Core and Periphery services.

**Possible Causes:**
- Core and Periphery versions are mismatched
- API response format changed between versions
- Network communication issues

**Solutions:**
1. **Check Version Compatibility:**
   ```bash
   # In Komodo UI, check both Core and Periphery versions
   # Ensure they are compatible versions
   ```

2. **Update Komodo Components:**
   - Update both Core and Periphery to the latest compatible versions
   - Restart both services after updating

3. **Check Network Connectivity:**
   - Ensure Periphery can communicate with Core
   - Verify firewall rules allow communication on configured ports

### Error: "Failed to clone repo"

**Possible Causes:**
- Incorrect repository URL
- Git provider not properly configured
- Network access issues
- Authentication problems

**Solutions:**
1. **Verify Repository URL:**
   ```bash
   # Check your actual repository URL
   git remote get-url origin
   # Should match the repo field in komodo-resources.toml
   ```

2. **Check Git Provider Configuration:**
   - Ensure the git provider is correctly configured in Komodo
   - Verify authentication tokens if using private repositories

3. **Test Manual Clone:**
   ```bash
   # Test if the repository can be cloned manually on the target server
   git clone https://github.com/basher83/dockervm-traefik.git test-clone
   ```

### Error: "Network traefik-proxy not found"

**Possible Causes:**
- External network not created before deployment
- Network configuration mismatch

**Solutions:**
1. **Create Network Manually:**
   ```bash
   docker network create traefik-proxy --driver bridge --attachable
   ```

2. **Check Pre-deploy Commands:**
   - Ensure `pre_deploy` commands in komodo-resources.toml are correct
   - Verify the commands execute successfully

### Error: "Port already in use"

**Possible Causes:**
- Another service is using the same ports
- Previous deployment not properly cleaned up

**Solutions:**
1. **Check Port Usage:**
   ```bash
   # Check what's using the ports
   lsof -i :8081
   lsof -i :8443
   lsof -i :8082
   ```

2. **Stop Conflicting Services:**
   ```bash
   # Stop any conflicting services
   docker ps
   docker stop <conflicting-container>
   ```

3. **Change Ports:**
   - Update port mappings in environment variables
   - Modify docker-compose.yml if needed

## 🔧 Debugging Steps

### 1. Validate Configuration

Run the validation script:
```bash
./scripts/validate-komodo.sh
```

### 2. Check Docker Compose Syntax

```bash
docker compose config
```

### 3. Test Manual Deployment

```bash
# Test the compose file manually
docker compose up -d
docker compose ps
docker compose logs
```

### 4. Check Komodo Logs

- Check Komodo Core logs for detailed error messages
- Check Periphery logs on the target server
- Look for authentication or network-related errors

### 5. Verify Server Configuration

```bash
# On the target server, check:
# 1. Docker is running
systemctl status docker

# 2. Network connectivity
ping github.com

# 3. DNS resolution
nslookup github.com

# 4. Available disk space
df -h
```

## 📋 Pre-deployment Checklist

- [ ] Komodo Core and Periphery versions are compatible
- [ ] Repository URL is correct and accessible
- [ ] Git provider is configured in Komodo (if needed)
- [ ] Target server has network access to git repository
- [ ] Required ports (8081, 8443, 8082) are available
- [ ] Docker is running on target server
- [ ] Server has sufficient resources (CPU, memory, disk)
- [ ] Domain DNS is properly configured
- [ ] SSL certificate email is valid

## 🆘 Getting Help

If you continue to experience issues:

1. **Check Komodo Documentation:**
   - [Komodo GitHub Repository](https://github.com/moghtech/komodo)
   - [Komodo Wiki](https://deepwiki.com/moghtech/komodo)

2. **Collect Debug Information:**
   ```bash
   # Gather system information
   docker version
   docker compose version
   uname -a
   df -h
   free -h
   
   # Gather Komodo-specific information
   # - Komodo Core version
   # - Komodo Periphery version
   # - Error logs from both Core and Periphery
   ```

3. **Join Community:**
   - Join the Komodo Discord community for support
   - Search for similar issues in the GitHub repository

## 🔄 Recovery Procedures

### Clean Up Failed Deployment

```bash
# Stop and remove containers
docker compose down

# Remove orphaned containers
docker container prune -f

# Remove unused networks
docker network prune -f

# Remove unused volumes (be careful!)
docker volume prune -f
```

### Reset to Clean State

```bash
# Complete cleanup (destructive - will lose data!)
docker compose down -v
docker system prune -a -f

# Recreate external network
docker network create traefik-proxy --driver bridge --attachable
```

### Rollback via Komodo

1. Go to Komodo UI → Updates
2. Find the failed deployment update
3. Use the rollback functionality if available
4. Or manually revert to previous working state

---

**Note:** Always test deployments in a development environment before applying to production systems.
