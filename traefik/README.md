# Traefik Reverse Proxy Setup

This configuration sets up a Traefik v3.4.1 reverse proxy with automatic HTTPS, HTTP/3 support, and example hello-world services.

## Services Overview

### Traefik
- Acts as a reverse proxy and load balancer
- Handles automatic HTTPS certificate generation and renewal via Let's Encrypt
- Supports HTTP/3 (QUIC) for improved performance
- Includes security headers and rate limiting
- Automatically discovers and routes to services based on Docker labels

### Hello World Services
- Two example services demonstrating subdomain routing
- Each service displays its container name when accessed
- Accessible via:
  - https://sub1.meco.cfd
  - https://sub2.meco.cfd

## Prerequisites

1. **Docker Swarm**
   ```bash
   # Initialize Docker Swarm if not already done
   docker swarm init
   ```

2. **Networks**
   ```bash
   # The 'host' network is a special network that already exists in Docker
   # We only need to create the 'selfai' network for internal service communication
   docker network create \
     --driver overlay \
     --attachable \
     --opt encrypted \
     selfai
   ```

3. **DNS Configuration**
   - Point your domain (meco.cfd) to your server's IP address
   - Create A records for subdomains:
     - sub1.meco.cfd
     - sub2.meco.cfd

4. **Cloudflare Account** (for DNS challenge)
   - Create an API token with DNS:Edit permissions
   - Note down your API key and email

## Secrets Setup

Create the required Docker secrets:

```bash
# Cloudflare API credentials
echo "your-email@example.com" | docker secret create cf_api_email -
echo "your-cloudflare-api-key" | docker secret create cf_api_key -
```

## Configuration Files

- `docker-compose.yml`: Main service definitions
- `traefik.yml`: Traefik configuration
- `config/middlewares.yml`: Security and routing middleware
- `hello-world/Dockerfile`: Example service container

## Building Images

Before deploying, you need to build the hello-world images. There are two approaches:

### Option 1: Build and Push to Registry (Recommended for Production)
```bash
# Build the images
docker build -t your-registry.com/hello-world:latest ./hello-world

# Push to your registry
docker push your-registry.com/hello-world:latest

# Update docker-compose.yml to use the registry image
# Replace the build section with:
# image: your-registry.com/hello-world:latest
```

### Option 2: Build on Each Node (Development/Testing)
```bash
# Build the images on each swarm node
docker build -t hello-world:latest ./hello-world

# Or use docker-compose to build
docker compose build
```

## Deployment

```bash
# Deploy the stack
docker stack deploy -c docker-compose.yml traefik
```

## Current Configuration Status

### Security Features
- [x] Automatic HTTPS with Let's Encrypt
- [x] HTTP to HTTPS redirection
- [x] Security headers
- [x] Rate limiting
- [x] Docker secrets for sensitive data
- [x] HTTP/3 (QUIC) support
- [x] TLS 1.3 enforcement

### Monitoring
- [ ] Dashboard enabled (commented out)
- [ ] Metrics endpoint (commented out)
- [ ] Prometheus integration (commented out)

### Example Services
- [x] Two hello-world containers
- [x] Subdomain routing
- [x] Container name display

## Adding New Services

To add a new service:

1. Add the service to `docker-compose.yml`
2. Add Traefik labels for routing:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.myservice.rule=Host(`myservice.meco.cfd`)"
     - "traefik.http.routers.myservice.entrypoints=websecure"
     - "traefik.http.routers.myservice.tls=true"
     - "traefik.http.services.myservice.loadbalancer.server.port=80"
   ```

## Troubleshooting

1. **Certificate Issues**
   - Check Cloudflare API credentials
   - Verify DNS records are propagated
   - Check Traefik logs: `docker service logs traefik_traefik`

2. **Service Not Accessible**
   - Verify service is running: `docker service ls`
   - Check service logs: `docker service logs traefik_hello-world-1`
   - Verify Traefik labels are correct

3. **Network Issues**
   - Verify networks exist: `docker network ls`
   - Check service network connectivity: `docker service inspect traefik_traefik`
   - Verify network encryption: `docker network inspect selfai`
   - Check network connectivity between services: `docker service ps traefik_traefik`

4. **Image Issues**
   - Check if images exist: `docker images`
   - Verify image tags match in docker-compose.yml
   - For registry images, ensure all nodes can access the registry

## Maintenance

### Updating Secrets
```bash
# Remove old secret
docker secret rm cf_api_key

# Create new secret
echo "new-api-key" | docker secret create cf_api_key -

# Update the service
docker service update --secret-rm cf_api_key --secret-add cf_api_key traefik_traefik
```

### Viewing Logs
```bash
# Traefik logs
docker service logs traefik_traefik

# Hello world services logs
docker service logs traefik_hello-world-1
docker service logs traefik_hello-world-2
```

## Security Notes

- The configuration uses Docker secrets for sensitive data
- Security headers are enabled by default
- Rate limiting is configured to prevent abuse
- TLS 1.3 is enforced
- The dashboard is disabled by default (commented out)
- Metrics endpoint is disabled by default (commented out)
- Overlay networks are encrypted by default in Swarm mode

## License

This configuration is provided under the MIT License.