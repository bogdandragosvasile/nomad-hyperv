# Example Service Workload

This is an example workload that demonstrates a multi-tier application deployment on Nomad.

## Architecture

The example service consists of three components:

1. **Web Tier** - Nginx web server serving static HTML content
2. **API Tier** - Simple HTTP echo service
3. **Cache Tier** - Redis cache service

## Components

### Web Tier
- **Service**: `example-service`
- **Port**: 8080
- **Replicas**: 3
- **Image**: `nginx:alpine`
- **Health Check**: HTTP `/health` endpoint

### API Tier
- **Service**: `example-api`
- **Port**: 9090
- **Replicas**: 2
- **Image**: `hashicorp/http-echo:latest`
- **Health Check**: HTTP `/health` endpoint

### Cache Tier
- **Service**: `example-cache`
- **Port**: 6379
- **Replicas**: 1
- **Image**: `redis:alpine`
- **Health Check**: TCP port check

## Deployment

### Prerequisites
- Nomad cluster running and healthy
- Docker available on client nodes
- Consul service discovery enabled

### Deploy the Job
```bash
# Deploy the job
nomad job run nomad-job.hcl

# Check job status
nomad job status example-service

# View job logs
nomad alloc logs <allocation-id>
```

### Access the Services

#### Web Service
```bash
# Get service endpoints
consul catalog service example-service

# Access web service
curl http://<node-ip>:8080
```

#### API Service
```bash
# Get service endpoints
consul catalog service example-api

# Access API service
curl http://<node-ip>:9090
```

#### Cache Service
```bash
# Get service endpoints
consul catalog service example-cache

# Test Redis connection
redis-cli -h <node-ip> -p 6379 ping
```

## Service Discovery

All services are automatically registered with Consul and can be discovered:

```bash
# List all services
consul catalog services

# Get service details
consul catalog service example-service

# Get service health
consul health service example-service
```

## Monitoring

### Health Checks
- Web service: HTTP health check on `/health`
- API service: HTTP health check on `/health`
- Cache service: TCP port check on 6379

### Metrics
- Service metrics available via Consul
- Node metrics via Node Exporter (port 9100)
- Nomad metrics via Nomad API (port 4646)

## Scaling

### Scale Web Tier
```bash
# Scale web tier to 5 replicas
nomad job scale example-service web 5
```

### Scale API Tier
```bash
# Scale API tier to 3 replicas
nomad job scale example-service api 3
```

## Troubleshooting

### Check Job Status
```bash
nomad job status example-service
```

### View Logs
```bash
# Get allocation IDs
nomad job allocations example-service

# View logs for specific allocation
nomad alloc logs <allocation-id>
```

### Check Service Health
```bash
# Check Consul service health
consul health service example-service

# Check Nomad job health
nomad job status example-service
```

### Common Issues
1. **Port conflicts**: Ensure ports 8080, 9090, and 6379 are available
2. **Docker images**: Verify Docker can pull required images
3. **Resource constraints**: Check if nodes have sufficient CPU/memory
4. **Network connectivity**: Verify inter-service communication

## Customization

### Environment Variables
Add environment-specific variables to the job specification:

```hcl
task "web" {
  env {
    NODE_ENV = "production"
    LOG_LEVEL = "info"
  }
}
```

### Resource Limits
Adjust resource allocations based on requirements:

```hcl
resources {
  cpu    = 1000    # 1 CPU core
  memory = 512     # 512 MB RAM
}
```

### Service Tags
Add custom tags for routing and filtering:

```hcl
tags = [
  "web",
  "example",
  "v1",
  "production"
]
```

## Cleanup

### Stop the Job
```bash
nomad job stop example-service
```

### Purge the Job
```bash
nomad job purge example-service
```

## Next Steps

1. **Add Load Balancing**: Use Consul Connect or external load balancer
2. **Implement TLS**: Add HTTPS support for web and API services
3. **Add Monitoring**: Integrate with Prometheus and Grafana
4. **Implement CI/CD**: Automate deployment via Jenkins pipeline
5. **Add Backup**: Implement Redis persistence and backup strategy
