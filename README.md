# 🏦 Microservices Project — Internet Banking on Kubernetes

A hands-on project that deploys an **internet banking concept application** built on a microservices architecture using Kubernetes. This repo contains Kubernetes manifests, shell automation scripts, and setup tooling to get a multi-service banking application running in a cluster quickly and cleanly.

---

## 📌 What This Project Is About

Modern banking applications are not a single monolith — they're made up of independent services that each handle a specific domain (user accounts, transactions, notifications, etc.). This project demonstrates how such a microservices-based banking system can be deployed and managed in Kubernetes, with shell scripts to automate the otherwise tedious setup steps.

---

## 🗂️ Project Structure

```
Microservices_project/
├── k8s/                                    # Kubernetes manifests for all services
│   └── *.yaml                              # Deployments, Services, ConfigMaps, etc.
├── internet-banking-concept-microservices  # Core microservices reference/config
├── check.sh                                # Health check script for deployed services
├── one.sh                                  # One-shot deployment/setup automation script
└── README.md                               # Project documentation
```

---

## 🔧 Tech Stack

| Technology     | Role                                           |
|----------------|------------------------------------------------|
| Kubernetes     | Container orchestration for all microservices  |
| Shell (Bash)   | Deployment automation and health checks        |
| Docker         | Containerization of individual services        |

---

## 🛠️ How to Deploy

### Prerequisites

- A running Kubernetes cluster (minikube, kind, EKS, GKE, etc.)
- `kubectl` configured and pointed at your cluster
- Docker installed (if building images locally)

### Option 1 — One-Shot Deployment

Use the automated script to deploy everything at once:

```bash
chmod +x one.sh
./one.sh
```

This script sets up all the required Kubernetes resources in the correct order.

### Option 2 — Manual Kubernetes Deployment

Apply the manifests from the `k8s/` directory:

```bash
kubectl apply -f k8s/
```

### Check Service Health

After deployment, run the health check script to verify all services are up:

```bash
chmod +x check.sh
./check.sh
```

This will report the status of each microservice running in the cluster.

---

## 🏛️ Architecture Overview

The application follows a microservices pattern where each banking domain runs as an independent Kubernetes Deployment with its own Service. The services communicate with each other inside the cluster and are exposed externally through Kubernetes Ingress or LoadBalancer Services.

```
                        [ Kubernetes Cluster ]
                        
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │  User Service│    │  Account Svc │    │ Transactions │
  │  (Pod/Svc)   │◄──►│  (Pod/Svc)   │◄──►│  (Pod/Svc)   │
  └──────────────┘    └──────────────┘    └──────────────┘
          ▲                   ▲                   ▲
          └───────────────────┴───────────────────┘
                        Ingress / LB
                        (External Access)
```

---

## 📋 Prerequisites

- Kubernetes cluster (1.20+)
- `kubectl` CLI installed
- At least 4 CPUs and 8GB RAM available on the cluster nodes (microservices can be resource-intensive)

---

## 👤 Author

**Sudhakar** — [GitHub Profile](https://github.com/Sudhakar20000)
