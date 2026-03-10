# Cloud Risk Platform - Infrastructure

**Production-Grade Platform Engineering**

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-purple?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Multi--AZ-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> A principal-engineer-level infrastruc---

### 🔄 Phase 2: EKS Platform (IN PROGRESS - 85%)
**Duration:** 2-3 weeks  
**Status:** 🔄 Core addons deployed, remaining addons pending

**Completed:**
- [x] EKS cluster (v1.31, private endpoint)
- [x] IRSA enabled
- [x] Multi-AZ node groups (Graviton)
- [x] Control plane logging
- [x] IMDSv2 enforcement
- [x] Cluster Autoscaler (IRSA + Helm)
- [x] Separate compute node group
- [x] AWS Load Balancer Controller (IRSA + Helm)
- [x] ArgoCD GitOps platform

**In Progress:**
- [ ] Metrics Server
- [ ] EBS CSI Driver
- [ ] External DNS for Route53
- [ ] Cert Manager for TLSeal-time risk assessment, fraud detection, and AI-powered decision engines.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Current Status](#current-status)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Infrastructure Components](#infrastructure-components)
- [Cost Estimates](#cost-estimates)
- [Documentation](#documentation)
- [Roadmap](#roadmap)

---

## 🎯 Overview

This repository contains the complete infrastructure-as-code for a **production-grade cloud platform** designed to run:

- **Real-time risk assessment** and fraud detection services
- **AI/ML inference pipelines** for credit scoring
- **Event-driven microservices** architecture (10+ services)
- **Kubernetes-based** container orchestration
- **Enterprise-grade** security and compliance

### Key Features

✅ **Multi-AZ High Availability** - Survives AZ failures  
✅ **Cost-Optimized** - Environment-based resource provisioning  
✅ **Security-First** - Network segmentation, VPC endpoints, flow logs  
✅ **Fully Automated** - Complete IaC with Terraform  
✅ **Production-Ready** - Enterprise tagging, monitoring, compliance  
✅ **Modular Design** - Reusable Terraform modules  

---

## 🏗️ Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Region                           │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │                VPC (10.0.0.0/16)                   │    │
│  │                                                     │    │
│  │   ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │    │
│  │   │   Public    │  │ Private App │  │   Data   │ │    │
│  │   │   Subnets   │  │   Subnets   │  │ Subnets  │ │    │
│  │   │             │  │             │  │          │ │    │
│  │   │ • ALB       │  │ • EKS       │  │ • RDS    │ │    │
│  │   │ • NAT GW    │  │ • Services  │  │ • Redis  │ │    │
│  │   │             │  │ • Workers   │  │          │ │    │
│  │   │ 3 AZs       │  │ 3 AZs       │  │ 3 AZs    │ │    │
│  │   └─────────────┘  └─────────────┘  └──────────┘ │    │
│  │                                                     │    │
│  │   VPC Endpoints: S3 • DynamoDB • ECR • Logs • STS │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Three-Tier Architecture:**
- **Public Tier**: Internet-facing resources (ALB, NAT)
- **Private App Tier**: Application workloads (EKS, microservices)
- **Data Tier**: Databases (RDS, Redis, Kafka) - NO internet access

---

## 📊 Current Status

### Phase 1: Foundation ✅ COMPLETE

| Component | Status | Details |
|-----------|--------|---------|
| VPC | ✅ | 10.0.0.0/16, Multi-AZ |
| Subnets | ✅ | 9 subnets (3 tiers × 3 AZs) |
| NAT Gateways | ✅ | Per-AZ, dev toggle |
| VPC Endpoints | ✅ | S3, DynamoDB, ECR, Logs, STS |
| Security Groups | ✅ | Baseline + endpoints |
| VPC Flow Logs | ✅ | 30-day retention |
| Route Tables | ✅ | Isolated data tier |
| Tagging | ✅ | Enterprise standards |

### Phase 2: EKS Platform 🔄 IN PROGRESS (85% Complete)

| Component | Status | Details |
|-----------|--------|---------|
| EKS Cluster | ✅ | v1.31, private endpoint |
| Control Plane Logs | ✅ | All 5 log types enabled |
| IRSA | ✅ | Enabled, foundation ready |
| Node Groups | ✅ | General + Compute (Graviton) |
| Cluster Autoscaler | ✅ | IRSA + Helm deployed |
| IMDSv2 | ✅ | Enforced on all nodes |
| AWS Load Balancer Controller | ✅ | IRSA + Helm deployed |
| GitOps (ArgoCD) | ✅ | Deployed to platform namespace |
| Metrics Server | 📋 | Pending |
| EBS CSI Driver | 📋 | Pending |
| External DNS | 📋 | Pending |
| Cert Manager | 📋 | Pending |
| First App | 📋 | Planned |

### Future Phases

- **Phase 3**: Data platform (RDS, Redis, Kafka)
- **Phase 4**: Microservices (10 services)
- **Phase 5**: AI/ML platform
- **Phase 6**: Observability stack

---

## 🚀 Quick Start

### Prerequisites

- AWS Account with admin access
- Terraform 1.6+ installed
- AWS CLI configured
- `jq` for JSON parsing

### 1. Bootstrap Backend

First, create the S3 bucket and DynamoDB table for Terraform state:

```bash
cd bootstrap
./create-backend.sh
```

This creates:
- S3 bucket for state storage
- DynamoDB table for state locking
- Encryption enabled

### 2. Deploy Infrastructure

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply
```

### 3. Verify Deployment

```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=cloud-risk-platform-vpc-dev"

# Check subnets
aws ec2 describe-subnets --filters "Name=tag:Project,Values=cloud-risk-platform"

# Check VPC endpoints
aws ec2 describe-vpc-endpoints --filters "Name=tag:Project,Values=cloud-risk-platform"
```

---

## 📁 Project Structure

```
infra/
├── README.md                    # This file
├── PHASE1_ASSESSMENT.md         # Detailed Phase 1 analysis
├── bootstrap/
│   └── create-backend.sh        # Creates S3 + DynamoDB backend
├── docs/
│   ├── architecture.md          # Complete architecture guide
│   └── networking.md            # Detailed networking docs
└── terraform/
    ├── common/
    │   ├── backend.tf           # Terraform backend config
    │   ├── providers.tf         # AWS provider setup
    │   └── variables.tf         # Common variables
    ├── modules/
    │   ├── vpc/                 # ✅ Phase 1 Complete
    │   │   ├── main.tf          # VPC resources
    │   │   ├── variables.tf     # Module inputs
    │   │   └── outputs.tf       # Module outputs
    │   └── eks/                 # 🔄 Phase 2 - 85% Complete
    │       ├── main.tf          # EKS cluster + node groups
    │       ├── variables.tf     # Module inputs
    │       ├── outputs.tf       # Cluster outputs
    │       ├── autoscaler.tf    # Cluster Autoscaler + IRSA
    │       ├── alb_controller.tf # ALB Controller + IRSA
    │       └── argocd.tf        # ArgoCD GitOps platform
    └── environments/
        └── dev/
            └── main.tf          # Dev environment (VPC + EKS)
```

---

## 🔧 Infrastructure Components

### VPC Module

**Location:** `terraform/modules/vpc/`

**Features:**
- Multi-AZ deployment (3 availability zones)
- Three-tier subnet architecture
- Per-AZ NAT gateways (HA mode)
- VPC endpoints for cost optimization
- VPC Flow Logs for security
- Comprehensive tagging

**Usage:**

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name    = "cloud-risk-platform"
  environment     = "dev"
  vpc_cidr        = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_app_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  data_subnets        = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway = false  # true for prod

  tags = {
    Owner        = "platform-team"
    CostCenter   = "engineering"
    BusinessUnit = "risk-management"
    Compliance   = "sox,pci"
  }
}
```

---

### EKS Module

**Location:** `terraform/modules/eks/`

**Features:**
- EKS v1.31 cluster with private endpoint
- IRSA enabled for pod IAM roles
- Multi-AZ managed node groups
- Graviton (ARM) processors for cost savings
- IMDSv2 enforced on all nodes
- Control plane logging (all 5 types)
- Cluster Autoscaler (IRSA + Helm deployed)
- AWS Load Balancer Controller (IRSA + Helm deployed)
- ArgoCD GitOps platform (Helm deployed)
- Separate compute node group with taints

**Usage:**

```hcl
module "eks" {
  source = "../../modules/eks"

  project_name       = "cloud-risk-platform"
  environment        = "dev"
  aws_region         = "us-east-1"
  kubernetes_version = "1.31"

  # Node group sizing
  min_nodes_general     = 1
  max_nodes_general     = 5
  desired_nodes_general = 1
}
```

**Node Groups:**

1. **General** (m7g.large/m6g.large)
   - Always-on workloads
   - Auto-scales based on demand
   - Graviton processors

2. **Compute** (c7g.2xlarge)
   - Starts at 0 replicas
   - Scales for compute-intensive workloads
   - Tainted (requires toleration)

**Cluster Addons:**
- **Cluster Autoscaler** - Automatic node scaling (50% threshold, 10min delay)
- **AWS Load Balancer Controller** - Automatic ALB/NLB provisioning from Ingress
- **ArgoCD** - GitOps continuous delivery platform

**Outputs:**
- `cluster_endpoint` - For kubectl configuration
- `oidc_provider_arn` - For IRSA role creation
- `cluster_autoscaler_policy_arn` - For autoscaler IRSA role
- `argocd_initial_admin_password` - Initial ArgoCD password (sensitive)

---

## 💰 Cost Estimates

### Development Environment

```
Component                    Monthly Cost
─────────────────────────────────────────
VPC                          Free
Subnets                      Free
Internet Gateway             Free
NAT Gateways                 $0 (disabled)
VPC Endpoints (Interface)    $36
VPC Flow Logs                $5
EKS Control Plane            $73
m7g.large (1 node)           $58
Data Transfer                $5
─────────────────────────────────────────
Total                        ~$177/month
```

### Production Environment (Estimated)

```
Component                    Monthly Cost
─────────────────────────────────────────
VPC                          Free
NAT Gateways (3x)            $108
NAT Data Processing          $45
VPC Endpoints (Interface)    $36
VPC Endpoint Data            $10
VPC Flow Logs                $15
EKS Control Plane            $73
m7g.xlarge (6 nodes)         $700
Load Balancers               $50
Cross-AZ Data Transfer       $20
─────────────────────────────────────────
Total                        ~$1,057/month
```

**Note:** RDS, Redis, Kafka, and application costs not included above.

### Cost Optimization Features

1. **NAT Gateway Toggle**: Disable in dev ($100/month savings)
2. **VPC Endpoints**: Reduce NAT data processing ($50-150/month savings)
3. **Multi-AZ Optimization**: Per-AZ NAT prevents cross-AZ charges
4. **Graviton Processors**: 20% cost savings vs x86 instances
5. **Cluster Autoscaler**: Scale down during low usage
6. **Spot Instances**: Ready for 70-90% savings (compute node group)
7. **Environment-Based Sizing**: Right-size resources per environment

---

## 📚 Documentation

Comprehensive documentation is available in the `docs/` directory:

### [Architecture Guide](docs/architecture.md)
- Complete system architecture
- Infrastructure layers
- Security architecture
- High availability strategy
- Future roadmap

### [Networking Documentation](docs/networking.md)
- VPC design and addressing
- Subnet architecture
- Routing strategies
- VPC endpoints configuration
- Network troubleshooting
- Cost optimization

### [Phase 1 Assessment](PHASE1_ASSESSMENT.md)
- Principal engineer validation
- Completion checklist
- Cost analysis
- Security posture
- Recommendations

---

## 🗺️ Roadmap

### ✅ Phase 1: Foundation (COMPLETE)
**Duration:** 2 weeks  
**Status:** ✅ Production-ready

- [x] Multi-AZ VPC architecture
- [x] Three-tier subnet design
- [x] NAT gateways with HA
- [x] VPC endpoints for AWS services
- [x] Security groups and flow logs
- [x] Enterprise tagging
- [x] Comprehensive documentation

---

### 🔄 Phase 2: EKS Platform (IN PROGRESS - 75%)
**Duration:** 2-3 weeks  
**Status:** � Infrastructure deployed, addons pending

**Completed:**
- [x] EKS cluster (v1.31, private endpoint)
- [x] IRSA enabled
- [x] Multi-AZ node groups (Graviton)
- [x] Control plane logging
- [x] IMDSv2 enforcement
- [x] Cluster Autoscaler IAM policy
- [x] Separate compute node group

**In Progress:**
- [ ] AWS Load Balancer Controller
- [ ] External DNS for Route53
- [ ] Cert Manager for TLS
- [ ] Metrics Server
- [ ] EBS CSI Driver
- [ ] GitOps with ArgoCD
- [ ] Deploy first application

**Deliverables:**
- ✅ `terraform/modules/eks/`
- ✅ EKS cluster in private subnets
- ✅ Graviton node pools
- 🔄 Cluster addons (pending)
- 🔄 GitOps setup (pending)

---

### 📋 Phase 3: Data Platform
**Duration:** 2 weeks  
**Status:** 📋 Planned

- [ ] RDS PostgreSQL (Multi-AZ)
- [ ] ElastiCache Redis (cluster mode)
- [ ] Amazon MSK (Kafka)
- [ ] Backup and restore automation
- [ ] Database monitoring

**Deliverables:**
- `terraform/modules/rds/`
- `terraform/modules/redis/`
- `terraform/modules/kafka/`

---

### 📋 Phase 4: Microservices
**Duration:** 4-6 weeks  
**Status:** 📋 Planned

Deploy 10 microservices:
1. API Gateway
2. Authentication/Authorization
3. Credit Risk Engine
4. Fraud Detection Service
5. Real-time Scoring
6. Data Ingestion
7. Analytics Service
8. Notification Service
9. Audit/Compliance
10. Admin Portal

**Deliverables:**
- Kubernetes manifests
- Helm charts
- Service mesh (Istio/Linkerd)
- API definitions

---

### 📋 Phase 5: AI/ML Platform
**Duration:** 3-4 weeks  
**Status:** 📋 Planned

- [ ] Feature store
- [ ] Model serving infrastructure
- [ ] Real-time inference pipelines
- [ ] MLOps automation
- [ ] Model monitoring

---

### 📋 Phase 6: Observability
**Duration:** 2 weeks  
**Status:** 📋 Planned

- [ ] Prometheus + Grafana
- [ ] Loki for logs
- [ ] Tempo for tracing
- [ ] OpenTelemetry
- [ ] Alerting and SLOs

---

## 🔐 Security

### Network Security
- **VPC Flow Logs**: All traffic logged and retained for 30 days
- **Security Groups**: Least-privilege firewall rules
- **Network Segmentation**: Three-tier isolation
- **No Internet Access**: Data tier completely isolated
- **VPC Endpoints**: Private AWS service access

### EKS Security
- **Private Endpoint**: No public cluster access
- **IRSA**: Pod-level IAM roles (no credentials in pods)
- **IMDSv2**: Enforced on all nodes
- **Control Plane Logs**: 5 log types enabled
- **Managed Node Groups**: Automatic security patches
- **Security Groups**: Pod-level network policies ready

### Compliance
- **SOX**: Financial data controls
- **PCI DSS**: Payment card security ready
- **Enterprise Tagging**: Complete resource governance
- **Audit Trail**: CloudTrail + Flow Logs + EKS logs

---

## 🤝 Contributing

This is a portfolio/demonstration project. For production use:

1. Review and customize for your requirements
2. Adjust CIDR ranges to avoid conflicts
3. Configure backend state storage
4. Update tagging to match your standards
5. Implement additional security controls as needed

---

## 📄 License

MIT License - See LICENSE file for details

---

## 👤 Author

**Ernest Bongwe Shongwe**  
Platform Engineer | Cloud Architect

- GitHub: [@bshongwe](https://github.com/bshongwe)
- LinkedIn: [Ernest Shongwe](https://linkedin.com/in/ernest-shongwe)

---

## 🌟 Acknowledgments

This project demonstrates **principal-level platform engineering practices**:

- ✅ Production-grade architecture (Multi-AZ, HA)
- ✅ Modern Kubernetes platform (EKS v1.31)
- ✅ Cost optimization strategies (Graviton, autoscaling, VPC endpoints)
- ✅ Enterprise security controls (IRSA, IMDSv2, private endpoints)
- ✅ Complete documentation
- ✅ Infrastructure as Code best practices
- ✅ Real-world design patterns

Built to showcase the complete infrastructure foundation for a modern, cloud-native, production-ready platform.


---

# Reference Repos

1. **Infra:** https://github.com/bshongwe/infra
2. **Fraud Detection ML System:** https://github.com/bshongwe/ml
3. **Services:** https://github.com/bshongwe/services
