job "example-service" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 3

    network {
      port "http" {
        static = 8080
        to     = 8080
      }
    }

    service {
      name = "example-service"
      port = "http"
      
      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
      
      tags = [
        "web",
        "example",
        "v1"
      ]
    }

    task "web" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        ports = ["http"]
        
        mount {
          type   = "bind"
          target = "/usr/share/nginx/html"
          source = "local/index.html"
          readonly = true
        }
      }

      resources {
        cpu    = 500
        memory = 256
      }

      template {
        data = <<EOH
<!DOCTYPE html>
<html>
<head>
    <title>Example Service</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .status { padding: 10px; border-radius: 5px; margin: 20px 0; }
        .healthy { background-color: #d4edda; color: #155724; }
        .info { background-color: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Example Service</h1>
        <div class="status healthy">
            <strong>Status:</strong> Healthy
        </div>
        <div class="info">
            <p><strong>Node:</strong> {{ env "NOMAD_NODE_NAME" }}</p>
            <p><strong>Allocation:</strong> {{ env "NOMAD_ALLOC_ID" }}</p>
            <p><strong>Task:</strong> {{ env "NOMAD_TASK_NAME" }}</p>
            <p><strong>Region:</strong> {{ env "NOMAD_REGION" }}</p>
            <p><strong>Datacenter:</strong> {{ env "NOMAD_DC" }}</p>
        </div>
        <div class="info">
            <p><strong>Timestamp:</strong> {{ timestamp }}</p>
            <p><strong>Request ID:</strong> {{ random_uuid }}</p>
        </div>
    </div>
</body>
</html>
EOH
        destination = "local/index.html"
      }
    }
  }

  group "api" {
    count = 2

    network {
      port "api" {
        static = 9090
        to     = 9090
      }
    }

    service {
      name = "example-api"
      port = "api"
      
      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
      
      tags = [
        "api",
        "example",
        "v1"
      ]
    }

    task "api" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:latest"
        args  = [
          "-listen", ":9090",
          "-text", "Hello from Example API!",
          "-text", "Node: {{ env \"NOMAD_NODE_NAME\" }}",
          "-text", "Allocation: {{ env \"NOMAD_ALLOC_ID\" }}"
        ]
        ports = ["api"]
      }

      resources {
        cpu    = 300
        memory = 128
      }
    }
  }

  group "cache" {
    count = 1

    network {
      port "redis" {
        static = 6379
        to     = 6379
      }
    }

    service {
      name = "example-cache"
      port = "redis"
      
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
      
      tags = [
        "cache",
        "redis",
        "example"
      ]
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:alpine"
        ports = ["redis"]
        
        mount {
          type   = "bind"
          target = "/data"
          source = "local/redis.conf"
          readonly = true
        }
      }

      resources {
        cpu    = 200
        memory = 256
      }

      template {
        data = <<EOH
# Redis configuration for example service
bind 0.0.0.0
port 6379
timeout 0
tcp-keepalive 300
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data
maxmemory 128mb
maxmemory-policy allkeys-lru
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
EOH
        destination = "local/redis.conf"
      }
    }
  }
}
