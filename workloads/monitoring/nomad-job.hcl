job "monitoring" {
  datacenters = ["dc1"]
  type        = "service"

  group "prometheus" {
    count = 1

    network {
      port "prometheus" {
        static = 9090
        to     = 9090
      }
    }

    service {
      name = "prometheus"
      port = "prometheus"
      
      check {
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
      
      tags = [
        "monitoring",
        "prometheus",
        "metrics"
      ]
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:latest"
        ports = ["prometheus"]
        
        mount {
          type   = "bind"
          target = /etc/prometheus
          source = "local/prometheus.yml"
          readonly = true
        }
        
        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.console.libraries=/etc/prometheus/console_libraries",
          "--web.console.templates=/etc/prometheus/consoles",
          "--storage.tsdb.retention.time=200h",
          "--web.enable-lifecycle"
        ]
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      template {
        data = <<EOH
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "first_rules.yml"
  - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'consul'
    consul_sd_configs:
      - server: '{{ env "NOMAD_ADDR_consul" | default "localhost:8500" }}'
        services: ['consul']
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: job

  - job_name: 'nomad'
    static_configs:
      - targets: ['{{ env "NOMAD_ADDR" | default "localhost:4646" }}']

  - job_name: 'node-exporter'
    consul_sd_configs:
      - server: '{{ env "NOMAD_ADDR_consul" | default "localhost:8500" }}'
        services: ['node-exporter']
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: job

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']

  - job_name: 'example-service'
    consul_sd_configs:
      - server: '{{ env "NOMAD_ADDR_consul" | default "localhost:8500" }}'
        services: ['example-service']
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: job
EOH
        destination = "local/prometheus.yml"
      }
    }
  }

  group "grafana" {
    count = 1

    network {
      port "grafana" {
        static = 3000
        to     = 3000
      }
    }

    service {
      name = "grafana"
      port = "grafana"
      
      check {
        type     = "http"
        path     = "/api/health"
        interval = "10s"
        timeout  = "2s"
      }
      
      tags = [
        "monitoring",
        "grafana",
        "dashboard"
      ]
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:latest"
        ports = ["grafana"]
        
        mount {
          type   = "bind"
          target = /etc/grafana/provisioning
          source = "local/grafana"
          readonly = true
        }
        
        env {
          GF_SECURITY_ADMIN_PASSWORD = "admin"
          GF_USERS_ALLOW_SIGN_UP = "false"
          GF_INSTALL_PLUGINS = "grafana-clock-panel,grafana-simple-json-datasource"
        }
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      template {
        data = <<EOH
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://{{ env "NOMAD_ADDR_prometheus" | default "localhost:9090" }}
    isDefault: true

  - name: Consul
    type: prometheus
    access: proxy
    url: http://{{ env "NOMAD_ADDR_consul" | default "localhost:8500" }}/v1/agent/metrics
    jsonData:
      metrics: true

  - name: Nomad
    type: prometheus
    access: proxy
    url: http://{{ env "NOMAD_ADDR" | default "localhost:4646" }}/v1/metrics
    jsonData:
      metrics: true
EOH
        destination = "local/grafana/datasources/prometheus.yml"
      }
    }
  }

  group "alertmanager" {
    count = 1

    network {
      port "alertmanager" {
        static = 9093
        to     = 9093
      }
    }

    service {
      name = "alertmanager"
      port = "alertmanager"
      
      check {
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
      
      tags = [
        "monitoring",
        "alertmanager",
        "alerts"
      ]
    }

    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager:latest"
        ports = ["alertmanager"]
        
        mount {
          type   = "bind"
          target = /etc/alertmanager
          source = "local/alertmanager.yml"
          readonly = true
        }
        
        args = [
          "--config.file=/etc/alertmanager/alertmanager.yml",
          "--storage.path=/alertmanager"
        ]
      }

      resources {
        cpu    = 300
        memory = 512
      }

      template {
        data = <<EOH
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOH
        destination = "local/alertmanager.yml"
      }
    }
  }

  group "cadvisor" {
    count = 1

    network {
      port "cadvisor" {
        static = 8080
        to     = 8080
      }
    }

    service {
      name = "cadvisor"
      port = "cadvisor"
      
      check {
        type     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
      }
      
      tags = [
        "monitoring",
        "cadvisor",
        "containers"
      ]
    }

    task "cadvisor" {
      driver = "docker"

      config {
        image = "gcr.io/cadvisor/cadvisor:latest"
        ports = ["cadvisor"]
        
        mount {
          type   = "bind"
          target = /var/run
          source = /var/run
          readonly = true
        }
        
        mount {
          type   = "bind"
          target = /sys
          source = /sys
          readonly = true
        }
        
        mount {
          type   = "bind"
          target = /var/lib/docker
          source = /var/lib/docker
          readonly = true
        }
        
        args = [
          "--docker_only",
          "--disable_metrics=disk,diskIO"
        ]
      }

      resources {
        cpu    = 300
        memory = 512
      }
    }
  }
}
