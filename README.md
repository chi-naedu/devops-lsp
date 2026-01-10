LinkSnap: End-to-End DevSecOps Platform on AWS EKS

LinkSnap is a modern microservices application deployed on a production-ready Kubernetes cluster. 
It features a fully automated GitOps pipeline using Jenkins, ArgoCD, and SonarQube, with comprehensive observability via Prometheus and Grafana.

---

## Architecture
* **Infrastructure:** AWS EKS (Managed Kubernetes), EC2 Nodes, Application Load Balancer (ALB).
* **Application:** Python Flask (Backend) + React (Frontend) + Redis (Cache).
* **Security:** AWS Security Groups, Private Networking, IAM Roles.

---

## Tech Stack

| Category | Tools Used |
| :--- | :--- |
| **Orchestration** | Kubernetes (EKS), Helm, Kubectl |
| **CI / Build** | Jenkins, Kaniko, Docker |
| **CD / GitOps** | ArgoCD |
| **Quality** | SonarQube (Static Analysis, Quality Gates) |
| **Monitoring** | Prometheus, Grafana |
| **Registry** | AWS ECR (Elastic Container Registry) |
| **IaC** | Terraform / eksctl |

---

## The Pipeline (CI/CD)

The project implements a "Separation of Concerns" workflow:

### 1. Continuous Integration (Jenkins)
* **Code Commit:** Developer pushes code to GitHub.
* **Quality Check:** Jenkins triggers SonarQube analysis. If the Quality Gate fails (e.g., bugs detected), the pipeline stops.
* **Build:** Kaniko builds Docker images inside the cluster (daemonless build).
* **Push:** Images are pushed to AWS ECR with a unique version tag (`v${BUILD_NUMBER}`).
* **Manifest Update:** Jenkins updates the Kubernetes YAML files in Git with the new image tag.

### 2. Continuous Delivery (ArgoCD)
* **Drift Detection:** ArgoCD detects the change in the Git manifest.
* **Sync:** ArgoCD automatically syncs the new configuration to the EKS cluster.
* **Self-Healing:** If manual changes occur in the cluster, ArgoCD reverts them to match Git.

---

## Observability
The cluster is monitored using the **Kube-Prometheus Stack**.
* **Prometheus:** Scrapes metrics from Nodes, Pods, and Services.
* **Grafana:** Visualizes CPU/Memory usage and network traffic.
* **Alerting:** Configured to track High Availability and Load spikes.

---

## Key Achievements
* **Zero-Downtime Deployment:** Rolling updates managed by Kubernetes.
* **Security First:** Private subnets for nodes; Security Groups strictly scoped between ALB and Nodes.
* **Cost Optimization:** Used shared alb to reduce AWS costs.
