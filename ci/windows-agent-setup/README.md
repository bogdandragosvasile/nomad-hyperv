# Windows Jenkins Agent Setup for Hyper-V Deployment

This directory contains scripts and instructions to set up a Windows Jenkins agent that can handle Hyper-V operations for the Nomad + Consul cluster deployment.

## 🎯 **Purpose**

The Windows agent will handle the actual Hyper-V VM provisioning and management, while the Linux agent handles planning, validation, and Ansible configuration. This hybrid approach ensures:

- **Linux Agent**: Terraform planning, Ansible configuration, workload deployment
- **Windows Agent**: Hyper-V VM creation, management, and Windows-specific operations

## 📋 **Prerequisites**

- **Windows 10/11** with Hyper-V enabled
- **Administrator privileges** for all installation steps
- **PowerShell 5.1+** or **PowerShell Core 7+**
- **Internet connection** for downloading tools and agents

## 🚀 **Quick Setup (Step-by-Step)**

### **Step 1: Install Java**
```powershell
# Run as Administrator
.\install-java.ps1
```

### **Step 2: Install Required Tools**
```powershell
# Run as Administrator
.\install-tools.ps1
```

### **Step 3: Create Jenkins Agent in Jenkins UI**
1. Open Jenkins: http://localhost:8080
2. Go to **Manage Jenkins** → **Manage Nodes and Clouds**
3. Click **New Node**
4. Configure:
   - **Name**: `windows-hyperv-agent`
   - **Labels**: `windows-hyperv-agent`
   - **Usage**: `Only build jobs with label expressions matching this node`
   - **Launch method**: `Launch agent by connecting it to the master`
   - **Availability**: `Keep this agent online as much as possible`

### **Step 4: Get Agent Secret**
1. After creating the agent, click on it
2. Copy the **secret** from the agent setup page
3. Note the **agent name** (should be `windows-hyperv-agent`)

### **Step 5: Start Windows Agent**
```powershell
# Option A: Manual start
.\start-windows-agent.ps1 -AgentSecret "YOUR_SECRET_HERE"

# Option B: Install as Windows Service (recommended)
.\install-windows-service.ps1 -AgentSecret "YOUR_SECRET_HERE"
```

## 🔧 **Script Details**

### **`install-java.ps1`**
- Downloads and installs OpenJDK 17
- Sets JAVA_HOME environment variable
- Adds Java to PATH

### **`install-tools.ps1`**
- Installs Chocolatey package manager
- Installs: Terraform, Git, Python, Ansible, Nomad, Consul, kubectl
- Verifies all installations

### **`start-windows-agent.ps1`**
- Downloads agent.jar from Jenkins
- Creates workspace directory
- Starts the agent with provided secret
- Manual operation (good for testing)

### **`install-windows-service.ps1`**
- Downloads NSSM (Non-Sucking Service Manager)
- Installs Jenkins agent as Windows service
- Automatic startup on boot
- Runs as Local System user

## 🏷️ **Agent Labels**

The Windows agent uses these labels:
- **Primary**: `windows-hyperv-agent`
- **Capabilities**: `windows`, `hyperv`, `powershell`

## 🔍 **Verification**

After setup, verify the agent is working:

1. **Check Jenkins UI**: Agent should show as "Online"
2. **Check agent logs**: Look for "Connected" message
3. **Test pipeline**: Run a pipeline that uses `agent { label 'windows-hyperv-agent' }`

## 🚨 **Troubleshooting**

### **Java Issues**
- Ensure JAVA_HOME is set correctly
- Restart terminal after Java installation
- Check PATH includes Java bin directory

### **Agent Connection Issues**
- Verify Jenkins URL is accessible
- Check agent secret is correct
- Ensure firewall allows Jenkins communication
- Check agent.jar was downloaded successfully

### **Tool Issues**
- Run `refreshenv` after Chocolatey installations
- Restart terminal for PATH changes
- Verify tools are in PATH: `Get-Command terraform`

### **Service Issues**
- Check Windows Event Viewer for service errors
- Verify NSSM installation
- Check service dependencies

## 📁 **Directory Structure**
```
ci/windows-agent-setup/
├── install-java.ps1           # Java installation script
├── install-tools.ps1          # Tool installation script
├── start-windows-agent.ps1    # Manual agent startup
├── install-windows-service.ps1 # Service installation
└── README.md                  # This file
```

## 🔄 **Next Steps**

After Windows agent setup:
1. **Test the hybrid pipeline** with both agents
2. **Run full deployment** from Linux agent planning to Windows agent execution
3. **Monitor Hyper-V VM creation** through Windows agent
4. **Validate cluster deployment** with both agents working together

## 📞 **Support**

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all prerequisites are met
3. Check Windows Event Viewer for system errors
4. Ensure Hyper-V is properly enabled and configured
