# docker-scripts
Collection of Docker scripts for container health checks, automated backups, cron jobs, and system maintenance tasks.

# 🐳 Docker Container Monitor & Auto-Healer

## 📋 Description
**Automated Docker container management system** that continuously monitors all containers and automatically restarts any that have stopped unexpectedly. Perfect for maintaining 24/7 uptime of your Dockerized applications!

## ⚡ Features
- 🔍 **Automatic Discovery** - Finds ALL Docker containers on the system
- 🚀 **Auto-Restart** - Automatically starts stopped containers
- 📊 **Health Monitoring** - Real-time status checking
- 📧 **Email Alerts** - Instant notifications when containers need restarting
- 📝 **Detailed Logging** - Comprehensive activity logging
- ⏰ **Cron Ready** - Perfect for scheduled execution

## 🛠️ Use Cases
- 🏗️ **Production Environments** - Ensure service availability
- 🏠 **Home Labs** - Keep self-hosted services running
- 🧪 **Development** - Automatically recover during testing
- 📦 **Microservices** - Maintain complex container ecosystems

## 🔧 Technical Details
- **Bash Script** - Lightweight and dependency-free
- **Docker API** - Uses native Docker commands
- **Systemd Compatible** - Works with service managers
- **Cron Integration** - Easy scheduling setup

## 🚀 Quick Start
```bash
chmod +x check_containers.sh
./check_containers.sh
