
# Multicontainer Deployment with Minikube

This repository contains all the necessary files to deploy a multi-container environment using Kubernetes and Minikube. The environment includes:
- GLPI
- WordPress (with MySQL)
- Grafana
- Prometheus
- Monitoring tools: cAdvisor and Node Exporter

## Prerequisites
- Minikube installed and running.
- `kubectl` configured for Minikube.

## Installation

1. - Start Minikube:
   ```bash
   - minikube start
   - minikube tunnel
   ==================================
Run the installation script:
bash
./install-env.sh

Uninstallation
To remove all resources:
bash
./uninstall-env.sh


Accessing Applications
GLPI: http://127.0.0.1:81
WordPress: http://127.0.0.1:80
Grafana: http://127.0.0.1:3000
Prometheus: http://127.0.0.1:9090


File Structure
install-env.sh: Script to deploy the environment.
uninstall-env.sh: Script to clean up all resources.
manifests/: Directory containing all Kubernetes YAML files.
Monitoring Tools
cAdvisor: Monitors container-level metrics.
Node Exporter: Monitors node-level metrics.
yaml
