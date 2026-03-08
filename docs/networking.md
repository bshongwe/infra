# Networking Architecture

**Cloud Risk Platform - Phase 1**  
**Date:** March 8, 2026

---

## Table of Contents

1. [Network Overview](#network-overview)
2. [VPC Design](#vpc-design)
3. [Subnet Architecture](#subnet-architecture)
4. [Routing Strategy](#routing-strategy)
5. [VPC Endpoints](#vpc-endpoints)
6. [Security Groups](#security-groups)
7. [Network Flow](#network-flow)
8. [High Availability](#high-availability)
9. [Cost Optimization](#cost-optimization)
10. [Troubleshooting](#troubleshooting)

---

## Network Overview

### Design Principles

1. **Multi-Tier Architecture**: Separate public, private, and data layers
2. **Multi-AZ Deployment**: Spread across 3 availability zones
3. **Zero-Trust Model**: No implicit trust between tiers
4. **Least Privilege**: Minimum necessary network access
5. **Defense in Depth**: Multiple security layers

### Network Topology

```
                         Internet
                            |
                    [Internet Gateway]
                            |
        ┌───────────────────┼───────────────────┐
        |                   |                   |
   ┌────────┐          ┌────────┐          ┌────────┐
   │  AZ-a  │          │  AZ-b  │          │  AZ-c  │
   └────────┘          └────────┘          └────────┘
        |                   |                   |
   ┌────────┐          ┌────────┐          ┌────────┐
   │ Public │          │ Public │          │ Public │
   │Subnet  │          │Subnet  │          │Subnet  │
   │  .1/24 │          │  .2/24 │          │  .3/24 │
   └────┬───┘          └────┬───┘          └────┬───┘
        |                   |                   |
    [NAT GW]            [NAT GW]            [NAT GW]
        |                   |                   |
   ┌────────┐          ┌────────┐          ┌────────┐
   │Private │          │Private │          │Private │
   │  App   │          │  App   │          │  App   │
   │ .11/24 │          │ .12/24 │          │ .13/24 │
   └────┬───┘          └────┬───┘          └────┬───┘
        |                   |                   |
   ┌────────┐          ┌────────┐          ┌────────┐
   │  Data  │          │  Data  │          │  Data  │
   │Subnet  │          │Subnet  │          │Subnet  │
   │ .21/24 │          │ .22/24 │          │ .23/24 │
   └────────┘          └────────┘          └────────┘
        |                   |                   |
    [No Internet]      [No Internet]      [No Internet]
        |                   |                   |
    VPC Endpoints      VPC Endpoints      VPC Endpoints
```

---

## VPC Design

### VPC Configuration

```hcl
CIDR Block:      10.0.0.0/16
Total IPs:       65,536
Region:          us-east-1
DNS Support:     Enabled
DNS Hostnames:   Enabled
Flow Logs:       Enabled (CloudWatch)
```

### Address Allocation

| Block | CIDR | Size | Purpose | Status |
|-------|------|------|---------|--------|
| 10.0.0.0/20 | 10.0.0.0 - 10.0.15.255 | 4,096 | Public & Private Subnets | ✅ In Use |
| 10.0.16.0/20 | 10.0.16.0 - 10.0.31.255 | 4,096 | Reserved for expansion | 🔒 Reserved |
| 10.0.32.0/19 | 10.0.32.0 - 10.0.63.255 | 8,192 | Reserved for future | 🔒 Reserved |
| 10.0.64.0/18 | 10.0.64.0 - 10.0.127.255 | 16,384 | Reserved for future | 🔒 Reserved |
| 10.0.128.0/17 | 10.0.128.0 - 10.0.255.255 | 32,768 | Reserved for future | 🔒 Reserved |

---

## Subnet Architecture

### Three-Tier Subnet Model

#### 1. Public Subnets (DMZ)

**Purpose:** Internet-facing resources

```
Name:           cloud-risk-platform-public-{az}
CIDR:           10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
IPs per AZ:     256 (251 usable)
Internet:       Direct via Internet Gateway
```

**Hosted Resources:**
- Application Load Balancers (ALB)
- NAT Gateways
- Bastion hosts (if needed)
- Future: Network Load Balancers

**Kubernetes Labels:**
```
kubernetes.io/role/elb = "1"  # For AWS Load Balancer Controller
```

---

#### 2. Private App Subnets

**Purpose:** Application workloads (EKS nodes, containers)

```
Name:           cloud-risk-platform-private-app-{az}
CIDR:           10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
IPs per AZ:     256 (251 usable)
Internet:       Outbound via NAT Gateway
```

**Hosted Resources:**
- EKS worker nodes
- Kubernetes pods
- Application containers
- Batch processing workloads

**Kubernetes Labels:**
```
kubernetes.io/role/internal-elb = "1"  # For internal load balancers
```

**Security Features:**
- No direct internet access
- All outbound traffic via NAT Gateway
- VPC endpoints for AWS services
- Security group-based access control

---

#### 3. Data Subnets (Isolated)

**Purpose:** Persistent data storage

```
Name:           cloud-risk-platform-data-{az}
CIDR:           10.0.21.0/24, 10.0.22.0/24, 10.0.23.0/24
IPs per AZ:     256 (251 usable)
Internet:       NONE - Completely isolated
```

**Hosted Resources:**
- RDS databases (PostgreSQL)
- ElastiCache (Redis)
- MSK (Kafka)
- Amazon MQ (if needed)

**Security Features:**
- ❌ **NO internet access** (not even via NAT)
- ✅ VPC endpoints for AWS service access
- ✅ Only accessible from Private App subnets
- ✅ Encryption at rest required
- ✅ Separate route tables with no default route

---

## Routing Strategy

### 1. Public Route Table

**Name:** `cloud-risk-platform-public-rt`

| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | VPC-internal traffic |
| 0.0.0.0/0 | igw-xxxxx | Internet access |

**Associated Subnets:**
- 10.0.1.0/24 (public-us-east-1a)
- 10.0.2.0/24 (public-us-east-1b)
- 10.0.3.0/24 (public-us-east-1c)

**VPC Endpoints:**
- S3 (Gateway)
- DynamoDB (Gateway)

---

### 2. Private Route Tables (One per AZ)

**Names:** `cloud-risk-platform-private-rt-{az}`

#### us-east-1a Route Table
| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | VPC-internal traffic |
| 0.0.0.0/0 | nat-xxxxx-1a | Internet via NAT in 1a |

#### us-east-1b Route Table
| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | VPC-internal traffic |
| 0.0.0.0/0 | nat-xxxxx-1b | Internet via NAT in 1b |

#### us-east-1c Route Table
| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | VPC-internal traffic |
| 0.0.0.0/0 | nat-xxxxx-1c | Internet via NAT in 1c |

**Associated Subnets:**
- 10.0.11.0/24 (private-app-us-east-1a)
- 10.0.12.0/24 (private-app-us-east-1b)
- 10.0.13.0/24 (private-app-us-east-1c)

**VPC Endpoints:**
- S3 (Gateway)
- DynamoDB (Gateway)

**Why AZ-specific routing?**
- ✅ Eliminates cross-AZ NAT data transfer costs
- ✅ Improves resilience (AZ failure doesn't affect other AZs)
- ✅ Reduces latency

---

### 3. Data Route Tables (One per AZ)

**Names:** `cloud-risk-platform-data-rt-{az}`

| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | VPC-internal traffic ONLY |

**⚠️ Critical: NO DEFAULT ROUTE**

Databases cannot reach the internet. Period.

**Associated Subnets:**
- 10.0.21.0/24 (data-us-east-1a)
- 10.0.22.0/24 (data-us-east-1b)
- 10.0.23.0/24 (data-us-east-1c)

**VPC Endpoints:**
- S3 (Gateway) - for backups
- DynamoDB (Gateway) - if needed

---

## VPC Endpoints

### Why VPC Endpoints?

Without endpoints:
```
Private Subnet → NAT Gateway → Internet → AWS Service
💰 Expensive (NAT data processing fees)
🐌 Slower (extra hops)
🔓 Less secure (traffic leaves VPC)
```

With endpoints:
```
Private Subnet → VPC Endpoint → AWS Service
✅ Free (Gateway) or cheap (Interface)
✅ Faster (direct connection)
✅ Secure (traffic stays in VPC)
```

---

### Gateway Endpoints (Free!)

#### S3 Endpoint
```
Type:           Gateway
Service:        com.amazonaws.us-east-1.s3
Cost:           FREE
Route Tables:   All (public, private, data)
```

**Use Cases:**
- Application S3 access
- Database backups to S3
- Log shipping to S3
- Container image storage (when used with ECR)

---

#### DynamoDB Endpoint
```
Type:           Gateway
Service:        com.amazonaws.us-east-1.dynamodb
Cost:           FREE
Route Tables:   All (public, private, data)
```

**Use Cases:**
- Application DynamoDB access
- Terraform state locking
- Session storage
- Metadata storage

---

### Interface Endpoints (Charged)

**Cost:** ~$7.20/month per endpoint + data processing ($0.01/GB)

#### ECR API Endpoint
```
Service:        com.amazonaws.us-east-1.ecr.api
Purpose:        ECR authentication and management
Subnets:        Private App subnets
Private DNS:    Enabled
```

#### ECR DKR Endpoint
```
Service:        com.amazonaws.us-east-1.ecr.dkr
Purpose:        Docker image pulls
Subnets:        Private App subnets
Private DNS:    Enabled
```

**Together enable:** Kubernetes nodes to pull container images without NAT

---

#### CloudWatch Logs Endpoint
```
Service:        com.amazonaws.us-east-1.logs
Purpose:        Log shipping
Subnets:        Private App subnets
Private DNS:    Enabled
```

#### CloudWatch Monitoring Endpoint
```
Service:        com.amazonaws.us-east-1.monitoring
Purpose:        Metrics publishing
Subnets:        Private App subnets
Private DNS:    Enabled
```

---

#### STS Endpoint
```
Service:        com.amazonaws.us-east-1.sts
Purpose:        IAM role assumption (IRSA for EKS)
Subnets:        Private App subnets
Private DNS:    Enabled
```

**Critical for:** Kubernetes pods assuming IAM roles

---

### VPC Endpoint Security Group

```hcl
Name:           cloud-risk-platform-vpc-endpoints-sg

Ingress:
  - Port 443 (HTTPS) from 10.0.0.0/16

Egress:
  - All traffic allowed
```

---

## Security Groups

### Baseline Security Group

**Name:** `cloud-risk-platform-sg-outbound`

```hcl
Ingress:  None (deny all inbound by default)
Egress:   All traffic allowed (0.0.0.0/0)
```

**Purpose:** Default outbound-only security group

---

### Future Security Groups (Phase 2+)

#### ALB Security Group
```
Ingress:  80, 443 from 0.0.0.0/0
Egress:   Dynamic ports to EKS nodes
```

#### EKS Node Security Group
```
Ingress:  From ALB, from other nodes, from control plane
Egress:   All (for downloading images, accessing AWS APIs)
```

#### Database Security Group
```
Ingress:  5432 (PostgreSQL) from private app subnets only
Egress:   None (databases don't initiate connections)
```

#### Redis Security Group
```
Ingress:  6379 from private app subnets only
Egress:   None
```

---

## Network Flow

### Inbound Internet Traffic

```
User Request (HTTPS)
    ↓
Internet Gateway
    ↓
Public Subnet (ALB)
    ↓
Private App Subnet (EKS Pod)
    ↓
Data Subnet (Database)
    ↓
Response flows back
```

**Security Layers:**
1. AWS Shield (DDoS protection)
2. Security Group (ALB)
3. Network ACL (subnet-level)
4. Security Group (Pod)
5. Network Policy (Kubernetes)
6. Application firewall (WAF)

---

### Outbound Internet Traffic

```
EKS Pod (Private Subnet)
    ↓
Private Route Table
    ↓
NAT Gateway (Public Subnet)
    ↓
Internet Gateway
    ↓
Internet
```

**Cost:** NAT data processing: $0.045/GB

---

### AWS Service Access (via Endpoints)

```
EKS Pod (Private Subnet)
    ↓
VPC Endpoint (Interface or Gateway)
    ↓
AWS Service (S3, ECR, CloudWatch, etc.)
```

**Cost:** Gateway endpoints: FREE, Interface: $7.20/mo + $0.01/GB

---

### Database Access

```
EKS Pod (Private App Subnet: 10.0.11.0/24)
    ↓
Security Group Check
    ↓
RDS (Data Subnet: 10.0.21.0/24)
```

**Security:**
- ✅ VPC-internal traffic only
- ✅ Security group restricted
- ✅ Database subnet has NO internet
- ✅ Encrypted in transit (TLS)
- ✅ Encrypted at rest (KMS)

---

## High Availability

### NAT Gateway Strategy

**Production (HA Mode):**
```
enable_nat_gateway = true

Result:
  - NAT Gateway in us-east-1a
  - NAT Gateway in us-east-1b
  - NAT Gateway in us-east-1c

Cost: ~$96/month (3 × $0.045/hour)
```

**Benefits:**
- ✅ AZ failure doesn't affect other AZs
- ✅ No cross-AZ data transfer costs
- ✅ Better performance (local routing)

**Development (Cost-Optimized):**
```
enable_nat_gateway = false

Result:
  - No NAT Gateways deployed
  - Private subnets cannot reach internet
  - Use VPC endpoints for AWS services

Cost: $0
Limitation: Cannot download from internet
```

---

### Failure Scenarios

#### Scenario 1: AZ-1a Fails

```
❌ us-east-1a
    - NAT Gateway down
    - Subnets unreachable

✅ us-east-1b
    - Still operational
    - Uses own NAT Gateway

✅ us-east-1c
    - Still operational
    - Uses own NAT Gateway

Impact: 1/3 capacity lost, no full outage
```

---

#### Scenario 2: Single NAT Gateway (Wrong Design)

```
If you had ONE NAT Gateway:

❌ us-east-1a NAT fails
    ↓
All private subnets lose internet
    ↓
Complete outage
```

**Never do this in production!**

---

## Cost Optimization

### Monthly Cost Breakdown

#### Development Environment
```
NAT Gateways:         $0     (disabled)
VPC Endpoints:        $36    (5 interface endpoints)
Data Transfer:        $2     (minimal)
CloudWatch Logs:      $5     (VPC flow logs)
────────────────────────────
Total:                ~$43/month
```

#### Production Environment
```
NAT Gateways:         $108   (3 × $0.045/hr)
NAT Data Processing:  $45    (varies with traffic)
VPC Endpoints:        $36    (5 interface endpoints)
Endpoint Data:        $10    (varies)
Data Transfer:        $20    (cross-AZ, etc.)
CloudWatch Logs:      $15    (higher volume)
────────────────────────────
Total:                ~$234/month
```

---

### Cost Optimization Strategies

#### 1. VPC Endpoints
**Savings:** $50-150/month

Replace:
```
Pod → NAT ($0.045/GB) → AWS Service
```

With:
```
Pod → VPC Endpoint ($0.01/GB or free) → AWS Service
```

---

#### 2. Cross-AZ Data Transfer
**Cost:** $0.01/GB between AZs

**Optimization:**
- Keep pod → database traffic in same AZ
- Use topology-aware routing
- Implement pod affinity rules

---

#### 3. NAT Gateway Optimization
**For Dev:**
- Disable NAT completely
- Use VPC endpoints for AWS services
- Pull container images once, cache locally

**For Prod:**
- Keep NAT for HA
- Minimize internet-bound traffic
- Use CloudFront for static assets

---

## VPC Flow Logs

### Configuration

```hcl
Traffic Type:    ALL (accept + reject)
Destination:     CloudWatch Logs
Log Group:       /vpc/cloud-risk-platform-dev
Retention:       30 days
Format:          Default
```

### Log Fields

```
version account-id interface-id srcaddr dstaddr srcport dstport 
protocol packets bytes start end action log-status
```

### Use Cases

1. **Security Analysis**
   - Detect unusual traffic patterns
   - Identify port scans
   - Find unauthorized access attempts

2. **Network Troubleshooting**
   - Debug connectivity issues
   - Verify security group rules
   - Analyze performance problems

3. **Compliance**
   - Audit network access
   - Generate compliance reports
   - Forensic investigation

---

## Troubleshooting

### Common Issues

#### Issue 1: Pod Can't Access Internet

**Symptoms:**
```
curl: (6) Could not resolve host: example.com
```

**Checklist:**
- [ ] Is NAT Gateway enabled? (`enable_nat_gateway = true`)
- [ ] Is pod in private subnet?
- [ ] Does private route table have default route to NAT?
- [ ] Does security group allow outbound traffic?
- [ ] Is DNS working? (check `enable_dns_support`)

---

#### Issue 2: Pod Can't Pull ECR Images

**Symptoms:**
```
Failed to pull image: connection timeout
```

**Checklist:**
- [ ] Are ECR endpoints deployed?
- [ ] Is private DNS enabled on endpoints?
- [ ] Is endpoint security group allowing 443 from pod subnet?
- [ ] Is S3 endpoint present? (ECR uses S3 for layers)

---

#### Issue 3: Database Connection Timeout

**Symptoms:**
```
Error: could not connect to server: Connection timed out
```

**Checklist:**
- [ ] Is database in data subnet?
- [ ] Does database security group allow traffic from app subnet?
- [ ] Is RDS in same VPC?
- [ ] Is correct port used (5432 for PostgreSQL)?

---

#### Issue 4: High NAT Gateway Costs

**Diagnosis:**
```bash
# Check NAT Gateway data processing
aws cloudwatch get-metric-statistics \
  --namespace AWS/NATGateway \
  --metric-name BytesOutToSource \
  --dimensions Name=NatGatewayId,Value=nat-xxxxx \
  --start-time 2026-03-01T00:00:00Z \
  --end-time 2026-03-08T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

**Solutions:**
- Add more VPC endpoints
- Cache external API responses
- Use CloudFront for static content
- Review logs to identify high-traffic sources

---

## Network Testing

### Connectivity Tests

#### Test 1: Internet Access from Private Subnet
```bash
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
/ # ping -c 3 8.8.8.8
/ # curl -I https://www.google.com
```

#### Test 2: S3 Access via Endpoint
```bash
kubectl run aws-cli --image=amazon/aws-cli --restart=Never -- \
  s3 ls s3://my-bucket
```

#### Test 3: Database Connectivity
```bash
kubectl run psql --image=postgres:15 --restart=Never -- \
  psql -h db.example.internal -U admin -d mydb -c "SELECT 1"
```

---

## Network Monitoring

### Key Metrics

| Metric | Threshold | Action |
|--------|-----------|--------|
| NAT Gateway Data Processing | > 100 GB/day | Review VPC endpoints |
| VPC Flow Logs Rejected | > 1000/hour | Check security groups |
| Cross-AZ Data Transfer | > 50 GB/day | Review pod placement |
| Endpoint Data Processing | Baseline | Normal ops |

---

## Next Steps

### Phase 1 Complete ✅
- [x] VPC deployed
- [x] Multi-AZ subnets
- [x] NAT Gateways configured
- [x] VPC endpoints created
- [x] Flow logs enabled
- [x] Security groups configured

### Phase 2: EKS Integration
- [ ] Deploy EKS cluster in private subnets
- [ ] Configure pod networking (CNI)
- [ ] Setup load balancer controller
- [ ] Test end-to-end connectivity
- [ ] Implement network policies

---

**Document Owner:** Platform Team  
**Last Updated:** March 8, 2026  
**Next Review:** April 8, 2026
