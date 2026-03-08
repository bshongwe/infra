# Cloud Risk Platform - Architecture Documentation

**Version:** 2.0  
**Date:** March 8, 2026  
**Status:** Phase 2 - EKS Platform In Progress 🔄

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Principles](#architecture-principles)
3. [Infrastructure Layers](#infrastructure-layers)
4. [Current Implementation](#current-implementation)
5. [High Availability Strategy](#high-availability-strategy)
6. [Security Architecture](#security-architecture)
7. [Cost Optimization](#cost-optimization)
8. [Next Steps](#next-steps)

---

## Overview

The Cloud Risk Platform is a **production-grade, multi-tenant platform** designed to support:

- Real-time risk assessment and fraud detection
- AI-powered credit scoring and decision engines
- Event-driven microservices architecture
- Kubernetes-based container orchestration
- Scalable data processing and analytics

### Current State: Phase 2 In Progress

**Phase 1** ✅ - Network foundation complete  
**Phase 2** 🔄 - EKS cluster infrastructure started

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                VPC (10.0.0.0/16)                      │  │
│  │                                                        │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │  │
│  │  │   Public     │  │ Private App  │  │    Data    │  │  │
│  │  │   Subnets    │  │   Subnets    │  │  Subnets   │  │  │
│  │  │              │  │              │  │            │  │  │
│  │  │  - ALB       │  │  - EKS ✅    │  │  - RDS 📋  │  │  │
│  │  │  - NAT GW    │  │  - Nodes ✅  │  │  - Redis 📋│  │  │
│  │  │  - Bastion   │  │  - Pods 🔄   │  │  - Kafka 📋│  │  │
│  │  │              │  │              │  │            │  │  │
│  │  │ 3 AZs        │  │ 3 AZs        │  │ 3 AZs      │  │  │
│  │  └──────┬───────┘  └──────┬───────┘  └─────┬──────┘  │  │
│  │         │                  │                │         │  │
│  │    [Internet]         [NAT Only]      [No Internet]  │  │
│  │      Gateway                                          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Legend:**
- ✅ Complete and deployed
- 🔄 In progress
- 📋 Planned

---

## Architecture Principles

### 1. **Cloud-Native Design**
- Immutable infrastructure via Terraform
- Container-first deployment model
- Microservices architecture
- Event-driven communication

### 2. **Security by Design**
- Network segmentation (3-tier architecture)
- Private EKS control plane (no public access)
- IRSA (IAM Roles for Service Accounts)
- IMDSv2 enforced on all nodes
- Principle of least privilege
- Complete audit trails

### 3. **High Availability**
- Multi-AZ deployment across 3 availability zones
- EKS managed control plane (automatic HA)
- Multi-AZ node groups
- Automated failover capabilities

### 4. **Cost Efficiency**
- Environment-based resource provisioning
- Graviton processors (m7g/m6g) for cost savings
- Cluster Autoscaler for dynamic scaling
- Spot instances ready (compute node group)
- VPC endpoints reduce NAT costs

### 5. **Observability**
- EKS control plane logs enabled
- VPC Flow Logs
- Container insights ready
- Metrics and monitoring built-in

### 6. **Scalability**
- Horizontal pod autoscaling
- Cluster autoscaling configured
- Separate node groups for different workloads
- Event-driven architecture ready

---

## Infrastructure Layers

### Layer 1: Network Foundation ✅ COMPLETE

**Components:**
- Amazon VPC (10.0.0.0/16) with Multi-AZ
- 9 subnets across 3 tiers
- NAT gateways (per-AZ in production)
- VPC endpoints (S3, DynamoDB, ECR, CloudWatch, STS)
- VPC Flow Logs
- Security groups

**Status:** Production-ready, fully documented

---

### Layer 2: Kubernetes Platform 🔄 85% COMPLETE

**Implemented Components:**
- ✅ EKS Cluster (v1.31)
  - Private endpoint only
  - IRSA enabled
  - Control plane logging (5 log types)
  
- ✅ Managed Node Groups:
  - **General**: m7g.large/m6g.large (Graviton)
    - Min: 1, Max: 5, Desired: 1 (dev)
    - Auto-scaling ready
    - IMDSv2 enforced
  
  - **Compute**: c7g.2xlarge
    - Min: 0, Max: 5, Desired: 0
    - Tainted for compute-intensive workloads
    - Scales on-demand

- ✅ Cluster Addons Deployed:
  - **Cluster Autoscaler** (IRSA + Helm v9.37.0)
    - Auto-discovery enabled
    - Scale down threshold: 50%
    - Scale down delay: 10 minutes
  
  - **AWS Load Balancer Controller** (IRSA + Helm v1.9.0)
    - Automatic ALB provisioning from Ingress
    - NLB support via Service annotations
    - WAF integration ready
  
  - **ArgoCD** (Helm v7.6.8)
    - GitOps platform deployed
    - Namespace: platform
    - Admin password auto-generated

- ✅ IAM/IRSA Roles:
  - ALB Controller IRSA role
  - Cluster Autoscaler IRSA role
  - Foundation ready for additional services

**Pending Components:**
- 📋 Metrics Server
- 📋 EBS CSI Driver
- 📋 External DNS (optional)
- 📋 Cert Manager (optional)
- 📋 GitOps (ArgoCD)
- 📋 Service mesh (optional)

**Status:** Infrastructure ready, waiting for addons deployment

---

### Layer 3: Data Platform 📋 PLANNED

**Components:**
- Amazon RDS (PostgreSQL) - Multi-AZ
- Amazon ElastiCache (Redis) - Cluster mode
- Amazon MSK (Kafka) - Event streaming
- Amazon S3 - Object storage
- Backup automation

**Purpose:** Managed data services for persistent storage and messaging

**Status:** Network isolated subnets ready, databases pending

---

### Layer 4: Application Services 📋 PLANNED

**Microservices:**
1. API Gateway Service
2. Authentication/Authorization
3. Credit Risk Engine
4. Fraud Detection Service
5. Real-time Scoring Service
6. Data Ingestion Service
7. Analytics Service
8. Notification Service
9. Audit/Compliance Service
10. Admin Portal Service

**Purpose:** Business logic and API layer

---

### Layer 5: AI/ML Platform 📋 PLANNED

**Components:**
- Feature store
- Model serving infrastructure
- Real-time inference endpoints
- MLOps pipelines

**Purpose:** AI-powered risk assessment and decision making

---

### Layer 6: Observability Stack 📋 PLANNED

**Components:**
- Prometheus (metrics)
- Grafana (visualization)
- Loki (log aggregation)
- OpenTelemetry (instrumentation)

**Purpose:** Complete observability solution

---

## Current Implementation

### Terraform Module Structure

```
terraform/
├── modules/
│   ├── vpc/          ✅ Complete
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── eks/          🔄 In Progress
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/
    └── dev/
        └── main.tf   ✅ Updated with EKS
```

---

### EKS Module Design

#### Key Features

**1. Security First**
```hcl
cluster_endpoint_public_access  = false  # Private only
cluster_endpoint_private_access = true
enable_irsa                     = true   # For pod IAM roles

metadata_options {
  http_tokens = "required"  # IMDSv2 enforced
}
```

**2. Graviton Processors**
```hcl
instance_types = ["m7g.large", "m6g.large"]
```
- 20% better price/performance
- Lower power consumption
- Fully compatible with most containers

**3. Multi-Node Group Strategy**
```
General Node Group:   For most workloads
  - Always running
  - Auto-scales 1-5 nodes (dev)
  
Compute Node Group:   For intensive tasks
  - Starts at 0
  - Tainted (requires toleration)
  - Scales on demand
```

**4. Cluster Addons Deployed**
- Cluster Autoscaler with IRSA
- AWS Load Balancer Controller with IRSA
- ArgoCD GitOps platform
- Tags configured for discovery

---

### Cluster Addons Deep Dive

#### 1. Cluster Autoscaler ✅

**Purpose:** Automatically adjusts the number of nodes in the cluster based on pod resource requests.

**Configuration:**
```yaml
Chart: kubernetes/autoscaler v9.37.0
Namespace: kube-system
Scale Down Threshold: 50% utilization
Scale Down Delay: 10 minutes
Auto-Discovery: Enabled via cluster tags
```

**IRSA Role:**
- Role Name: `cloud-risk-platform-cluster-autoscaler-dev`
- Permissions: Autoscaling groups, EC2 describe/terminate
- ServiceAccount: `kube-system:cluster-autoscaler`

**How It Works:**
1. Monitors pods that can't be scheduled (Pending state)
2. Checks if adding a node would help
3. Scales up the appropriate node group
4. Scales down underutilized nodes after 10 minutes at <50% usage

---

#### 2. AWS Load Balancer Controller ✅

**Purpose:** Automatically creates and configures AWS Application Load Balancers from Kubernetes Ingress resources.

**Configuration:**
```yaml
Chart: aws/aws-load-balancer-controller v1.9.0
Namespace: kube-system
Cluster Name: Injected from EKS module
```

**IRSA Role:**
- Role Name: `cloud-risk-platform-alb-controller-dev`
- Permissions: ALB/NLB creation, Target Group management, Security Group management
- ServiceAccount: `kube-system:aws-load-balancer-controller`

**Features:**
- Automatic ALB provisioning from Ingress resources
- NLB support via Service annotations
- Target type: IP mode (for pod IPs)
- WAF integration ready
- TLS termination support

**Example Ingress:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 80
```

---

#### 3. ArgoCD GitOps Platform ✅

**Purpose:** Declarative continuous delivery for Kubernetes applications using Git as the source of truth.

**Configuration:**
```yaml
Chart: argo/argo-cd v7.6.8
Namespace: platform
Service Type: ClusterIP (expose via Ingress later)
Admin Password: Auto-generated (terraform output)
```

**Access ArgoCD:**
```bash
# Get initial admin password
terraform output -raw argocd_initial_admin_password

# Port forward to UI
kubectl port-forward svc/argo-cd-server -n platform 8080:443

# Open browser
https://localhost:8080
# Username: admin
# Password: [from terraform output]
```

**GitOps Workflow:**
1. Developers push code to Git repository
2. ArgoCD detects changes
3. Compares desired state (Git) with actual state (cluster)
4. Automatically syncs differences
5. Provides UI for visualization and manual override

**Benefits:**
- Single source of truth (Git)
- Audit trail of all changes
- Easy rollbacks
- Multi-environment support
- RBAC integration

---

### Development Environment Configuration

```hcl
module "eks" {
  source = "../../modules/eks"
  
  project_name       = "cloud-risk-platform"
  environment        = "dev"
  aws_region         = var.aws_region
  kubernetes_version = "1.31"
  
  # Cost-optimized for dev
  min_nodes_general     = 1
  max_nodes_general     = 5
  desired_nodes_general = 1
}
```

**Cost Profile:**
- 1x m7g.large: ~$0.08/hour = ~$58/month
- VPC + EKS control plane: ~$73/month
- Total: ~$131/month (dev)

---

## High Availability Strategy

### EKS Control Plane
- **Managed by AWS**: Automatic Multi-AZ
- **SLA**: 99.95% uptime guarantee
- **Automatic failover**: No manual intervention

### Worker Nodes
- **Multi-AZ deployment**: Nodes spread across 3 AZs
- **Cluster Autoscaler**: Replaces failed nodes
- **Health checks**: Kubelet + EC2 status checks

### Application Layer
- **Pod replicas**: Multiple replicas across AZs
- **HPA**: Horizontal Pod Autoscaler
- **Readiness/Liveness probes**: Auto-recovery

---

## Security Architecture

### Network Security

```
Internet
    ↓
┌─────────────────┐
│  Public Subnet  │  ← ALB (future)
└────────┬────────┘
         ↓
┌─────────────────┐
│ Private App     │  ← EKS Nodes (private endpoint)
│  - Worker Nodes │  ← No public IPs
│  - Pods         │  ← Security groups + Network policies
└────────┬────────┘
         ↓
┌─────────────────┐
│  Data Subnet    │  ← Databases
│  - RDS          │  ← NO internet access
│  - Redis        │  ← Pod-to-DB only
└─────────────────┘
```

### EKS Security Controls

#### 1. Control Plane Security
- ✅ Private endpoint only
- ✅ TLS 1.3 for all communication
- ✅ Audit logging enabled
- ✅ API server logs enabled

#### 2. Node Security
- ✅ Private subnets only
- ✅ IMDSv2 enforced
- ✅ Security group based access
- ✅ SSM for access (no SSH keys)

#### 3. Pod Security
- 🔄 IRSA for AWS service access
- 📋 Pod Security Standards (next)
- 📋 Network Policies (next)
- 📋 Service Mesh mTLS (optional)

#### 4. IAM Security
- ✅ IRSA enabled (pod-level permissions)
- ✅ No long-lived credentials
- 📋 IRSA roles per service (next)

---

## Cost Optimization

### Environment Comparison

#### Development Environment
```
Component                    Monthly Cost
─────────────────────────────────────────
VPC (NAT disabled)           $0
VPC Endpoints                $36
VPC Flow Logs                $5
EKS Control Plane            $73
m7g.large (1 node)           $58
Data Transfer                $5
─────────────────────────────────────────
Total                        ~$177/month
```

#### Production Environment (Estimated)
```
Component                    Monthly Cost
─────────────────────────────────────────
VPC (3x NAT)                 $108
NAT Data Processing          $45
VPC Endpoints                $36
VPC Flow Logs                $15
EKS Control Plane            $73
m7g.xlarge (6 nodes)         $700
Load Balancers               $50
Data Transfer                $50
─────────────────────────────────────────
Total                        ~$1,077/month
```

### Cost Optimization Strategies

1. **Graviton Processors**: 20% savings vs x86
2. **Cluster Autoscaler**: Scale down during low usage
3. **VPC Endpoints**: Reduce NAT costs
4. **Spot Instances**: 70-90% savings (future)
5. **Reserved Instances**: 40-60% savings (production)

---

## Next Steps

### Immediate (Complete Phase 2)

#### 1. Deploy Cluster Addons
```bash
# AWS Load Balancer Controller
# External DNS
# Metrics Server
# EBS CSI Driver
# Cert Manager
```

#### 2. Setup GitOps
```bash
# Deploy ArgoCD
# Configure app-of-apps pattern
# Connect to Git repository
```

#### 3. Deploy First Application
```bash
# Simple nginx deployment
# Expose via ALB
# Test end-to-end
```

#### 4. Configure IRSA Roles
```bash
# Create service account roles
# Attach policies
# Test pod permissions
```

---

### Phase 3: Data Platform

**Timeline:** 2-3 weeks

1. Deploy RDS PostgreSQL
2. Setup ElastiCache Redis
3. Configure MSK Kafka
4. Implement backup strategies
5. Setup monitoring

---

### Phase 4: Microservices

**Timeline:** 4-6 weeks

1. Deploy 10 core services
2. Implement API gateway
3. Configure service mesh (optional)
4. Setup observability
5. Load testing

---

## Kubernetes Version Strategy

**Current:** 1.31 (latest stable)

**Upgrade Policy:**
- Review new versions within 1 week of release
- Test in dev within 2 weeks
- Deploy to prod within 1 month
- Stay within n-2 versions of latest

---

## Disaster Recovery

### Backup Strategy
- **EKS**: Cluster config in Terraform (IaC)
- **Persistent Volumes**: Snapshots via CSI driver
- **Applications**: GitOps (ArgoCD)
- **Databases**: Automated snapshots (future)

### Recovery Procedures
1. **Infrastructure**: `terraform apply`
2. **Applications**: GitOps auto-sync
3. **Data**: Restore from snapshots

**RTO Target:** < 1 hour  
**RPO Target:** < 5 minutes

---

## Monitoring & Alerting

### Current State
- ✅ EKS control plane logs → CloudWatch
- ✅ VPC Flow Logs → CloudWatch
- 📋 Container Insights (pending)
- 📋 Prometheus/Grafana (pending)

### Planned Metrics
- Cluster health
- Node utilization
- Pod resource usage
- Application metrics
- Cost metrics

---

## Compliance & Governance

### Current Tags
All resources tagged with:
- Project: cloud-risk-platform
- Environment: dev/prod
- ManagedBy: Terraform
- Owner: platform-team
- CostCenter: engineering
- Compliance: sox,pci

### Audit Capabilities
- EKS API audit logs
- VPC Flow Logs
- CloudTrail (AWS API calls)
- Application logs (future)

---

## Technical Specifications

### EKS Cluster
- **Version**: 1.31
- **Endpoint**: Private only
- **IRSA**: Enabled
- **Logging**: All 5 log types
- **Node Groups**: 2 (general, compute)

### Node Specifications

**General Nodes:**
- Instance Type: m7g.large, m6g.large
- vCPU: 2
- Memory: 8 GB
- Network: Up to 12.5 Gbps
- Architecture: ARM64 (Graviton)

**Compute Nodes:**
- Instance Type: c7g.2xlarge
- vCPU: 8
- Memory: 16 GB
- Network: Up to 15 Gbps
- Architecture: ARM64 (Graviton)

---

## Architecture Decisions

### Why Private Endpoint Only?
- ✅ Enhanced security (no internet exposure)
- ✅ Compliance requirement
- ✅ Reduced attack surface
- ✅ Access via VPN/bastion only

### Why Graviton (ARM)?
- ✅ 20% better price/performance
- ✅ Lower power consumption
- ✅ Most containers are compatible
- ✅ Future-proof architecture

### Why Managed Node Groups?
- ✅ Simplified operations
- ✅ Automatic updates
- ✅ Integration with Cluster Autoscaler
- ✅ IMDSv2 enforcement

### Why IRSA?
- ✅ No AWS credentials in pods
- ✅ Fine-grained IAM permissions
- ✅ Audit trail via CloudTrail
- ✅ Principle of least privilege

---

## Conclusion

**Phase 1: Foundation** ✅ Complete  
**Phase 2: EKS Platform** 🔄 75% Complete

### Completed
- ✅ Network infrastructure
- ✅ EKS cluster deployment
- ✅ Multi-AZ node groups
- ✅ Security controls
- ✅ Cost optimization
- ✅ IAM foundation

### Remaining
- 📋 Cluster addons
- 📋 GitOps setup
- 📋 First application deployment
- 📋 IRSA role implementation

The platform is on track to support production workloads within 2-3 weeks.

---

**Document Owner:** Platform Team  
**Last Updated:** March 8, 2026  
**Next Review:** March 15, 2026
