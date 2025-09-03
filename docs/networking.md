# Networking Strategy

## Network Architecture

This document describes the networking strategy for the Nomad + Consul cluster running on Hyper-V.

## 🌐 Network Topology

### Physical Network
- **Host Network**: Windows 11 host with Hyper-V
- **External Switch**: Bridged to physical network adapter
- **IP Range**: 192.168.1.0/24 (typical home/office network)

### Virtual Network Layout
```
┌─────────────────────────────────────────────────────────────────┐
│                    Windows 11 Host                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                Hyper-V External Switch                     │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │ │
│  │  │ Consul      │  │ Nomad       │  │ Nomad       │        │ │
│  │  │ Server 1    │  │ Server 1    │  │ Client 1    │        │ │
│  │  │ 192.168.1.100│  │ 192.168.1.103│  │ 192.168.1.106│        │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │ │
│  │  │ Consul      │  │ Nomad       │  │ Nomad       │        │ │
│  │  │ Server 2    │  │ Server 2    │  │ Client 2    │        │ │
│  │  │ 192.168.1.101│  │ 192.168.1.104│  │ 192.168.1.107│        │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │ │
│  │  │ Consul      │  │ Nomad       │  │ Nomad       │        │ │
│  │  │ Server 3    │  │ Server 3    │  │ Client 3    │        │ │
│  │  │ 192.168.1.102│  │ 192.168.1.105│  │ 192.168.1.108│        │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                Jenkins (Docker)                            │ │
│  │                Host: localhost:8080                        │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Network Configuration

### Hyper-V External Switch
- **Switch Type**: External
- **Physical Adapter**: Bridged to host network adapter
- **VLAN ID**: None (default)
- **Management OS**: Enabled for host connectivity

### IP Address Assignment
| Service | Node | IP Address | Purpose |
|---------|------|------------|---------|
| Consul | Server 1 | 192.168.1.100 | Consul HA quorum |
| Consul | Server 2 | 192.168.1.101 | Consul HA quorum |
| Consul | Server 3 | 192.168.1.102 | Consul HA quorum |
| Nomad | Server 1 | 192.168.1.103 | Nomad cluster management |
| Nomad | Server 2 | 192.168.1.104 | Nomad cluster management |
| Nomad | Server 3 | 192.168.1.105 | Nomad cluster management |
| Nomad | Client 1 | 192.168.1.106 | Job execution |
| Nomad | Client 2 | 192.168.1.107 | Job execution |
| Nomad | Client 3 | 192.168.1.108 | Job execution |

### Network Settings
- **Subnet**: 192.168.1.0/24
- **Gateway**: 192.168.1.1
- **DNS**: 8.8.8.8, 8.8.4.4
- **MTU**: 1500 (default)

## 🌍 Service Discovery

### Consul Service Registration
- **HTTP API**: 8500
- **HTTPS API**: 8501
- **LAN Serf**: 8301
- **WAN Serf**: 8302
- **Server RPC**: 8300

### Nomad Service Registration
- **HTTP API**: 4646
- **HTTPS API**: 4647
- **RPC**: 4648

### Service Communication
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   App 1     │    │   App 2     │    │   App 3     │
│             │    │             │    │             │
│ 192.168.1.110│    │ 192.168.1.111│    │ 192.168.1.112│
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
              ┌─────────────────┐
              │   Consul        │
              │   (192.168.1.100│
              │   -102)         │
              └─────────────────┘
```

## 🔒 Network Security

### Firewall Configuration
- **Host Firewall**: Windows Defender Firewall
- **VM Firewall**: UFW (Ubuntu)
- **Port Restrictions**: Only necessary ports open

### Access Control
- **Internal Communication**: All VMs can communicate
- **External Access**: Limited to specific services
- **Management Access**: SSH from host only

### Security Groups
```
┌─────────────────────────────────────────────────────────────┐
│                    Security Groups                         │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Consul        │  │   Nomad         │  │   Client    │ │
│  │   Servers       │  │   Servers       │  │   Nodes     │ │
│  │                 │  │                 │  │             │ │
│  │ • 8300-8302     │  │ • 4646-4648     │  │ • 4646     │ │
│  │ • 8500-8501     │  │ • 8500          │  │ • 8500     │ │
│  │ • SSH (22)      │  │ • SSH (22)      │  │ • SSH (22) │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📡 Network Troubleshooting

### Common Issues
1. **VM Cannot Reach Host**: Check external switch configuration
2. **VMs Cannot Communicate**: Verify IP addressing and firewall rules
3. **External Access Fails**: Check port forwarding and firewall rules

### Diagnostic Commands
```bash
# From host
Get-VMSwitch
Get-VMNetworkAdapter

# From VMs
ip addr show
ping 192.168.1.1
nslookup google.com
netstat -tlnp
```

### Network Validation
```bash
# Test connectivity between nodes
for ip in 192.168.1.{100..108}; do
  echo "Testing $ip..."
  ping -c 1 $ip
done

# Test service ports
for port in 8500 4646 22; do
  echo "Testing port $port..."
  telnet 192.168.1.100 $port
done
```

## 🚀 Network Scaling

### Horizontal Scaling
- **Additional Nodes**: Extend IP range (192.168.1.109+)
- **Load Balancing**: HAProxy/Nginx for external access
- **Network Segmentation**: VLANs for different environments

### Performance Optimization
- **Jumbo Frames**: MTU 9000 for high-throughput scenarios
- **Network Isolation**: Separate switches for different tiers
- **Bandwidth Management**: QoS policies for critical services

## 📋 Network Checklist

### Pre-deployment
- [ ] Verify external switch configuration
- [ ] Confirm IP address availability
- [ ] Test host network connectivity
- [ ] Validate DNS resolution

### Post-deployment
- [ ] Test inter-VM communication
- [ ] Verify service discovery
- [ ] Check external accessibility
- [ ] Monitor network performance
- [ ] Document network topology
