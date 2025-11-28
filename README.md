# Terraform + Terragrunt Full Stack Infrastructure

This repository contains Infrastructure as Code (IaC) for deploying a complete full-stack application infrastructure on AWS using Terraform modules managed by Terragrunt.

## Architecture Overview

This infrastructure is designed to support a modern full-stack application with microservices architecture, providing:
- Container orchestration with Kubernetes (EKS)
- Managed databases and caching
- Message queuing and streaming
- Static asset delivery via CDN
- GitOps deployment with ArgoCD
- Service mesh with Istio
- Multi-region deployment support
- Automated CI/CD with GitLab

## AWS Resources Created

### 1. **VPC (Virtual Private Cloud)**
- **Module**: `modules/vpc`
- **Resources**: VPC, Public/Private Subnets, NAT Gateway, Internet Gateway
- **Use Case**: Network isolation and security for all resources
- **Configuration**: 
  - CIDR: 10.0.0.0/16
  - 3 Availability Zones
  - Public subnets for load balancers
  - Private subnets for application workloads

### 2. **EKS (Elastic Kubernetes Service)**
- **Module**: `modules/eks`
- **Resources**: EKS Cluster, Managed Node Groups, IAM Roles
- **Use Case**: Container orchestration for microservices
- **Configuration**:
  - Kubernetes version: 1.31
  - Node type: t3.small (configurable)
  - Auto-scaling: 2-3 nodes
  - Addons: CoreDNS, kube-proxy, VPC-CNI

### 3. **RDS (Relational Database Service)**
- **Module**: `modules/rds`
- **Resources**: PostgreSQL instances, DB Subnet Groups, Security Groups
- **Use Case**: Primary database for application data
- **Configuration**:
  - Engine: PostgreSQL 16
  - Multi-instance support (count configurable)
  - Automated backups enabled
  - Private subnet deployment

### 4. **ElastiCache (Redis)**
- **Module**: `modules/elasticache`
- **Resources**: Redis cluster, Subnet Groups, Security Groups
- **Use Case**: Session management, caching, real-time data
- **Configuration**:
  - Engine: Redis 7.1
  - Node type: cache.t4g.small
  - Private subnet deployment

### 5. **MSK (Managed Streaming for Apache Kafka)**
- **Module**: `modules/msk`
- **Resources**: Kafka cluster, Security Groups
- **Use Case**: Event streaming, message queuing, microservices communication
- **Configuration**:
  - Kafka version: 3.7.x
  - 3 broker nodes (multi-AZ)
  - TLS encryption enabled
  - Instance type: kafka.t3.small

### 6. **Amazon MQ (RabbitMQ)**
- **Module**: `modules/mq`
- **Resources**: RabbitMQ broker, Security Groups
- **Use Case**: Message queuing, task distribution, async processing
- **Configuration**:
  - Engine: RabbitMQ 3.13
  - Deployment: Single instance (dev), Multi-AZ (prod)
  - Instance type: mq.t3.micro

### 7. **S3 + CloudFront**
- **Modules**: `modules/s3`, `modules/cloudfront`
- **Resources**: S3 bucket, CloudFront distribution, Origin Access Control
- **Use Case**: Static asset hosting (React/Angular/Vue frontend)
- **Configuration**:
  - Private S3 bucket
  - CloudFront CDN for global delivery
  - HTTPS redirect enabled
  - Origin Access Control (OAC) for security

### 8. **Helm Apps (ArgoCD + Istio)**
- **Module**: `modules/helm-apps`
- **Resources**: ArgoCD, Istio service mesh
- **Use Case**: GitOps deployment and service mesh
- **Configuration**:
  - ArgoCD: Continuous deployment
  - Istio: Traffic management, security, observability

## Full Stack Application Deployment Guide

### Architecture Pattern
```
Internet → CloudFront → S3 (Frontend)
         ↓
Internet → ALB → EKS (Backend APIs)
         ↓
Backend → RDS (Database)
        → ElastiCache (Cache)
        → MSK (Event Streaming)
        → MQ (Message Queue)
```

### Deployment Steps

#### 1. **Infrastructure Provisioning**

**Manual Deployment:**
```bash
# Deploy dev environment
cd environments/dev
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply

# Deploy test environment
cd ../test
terragrunt run-all apply --terragrunt-non-interactive

# Deploy prod environment
cd ../prod
terragrunt run-all apply --terragrunt-non-interactive
```

**GitLab CI/CD Deployment:**
```bash
# Push to trigger pipeline
git add .
git commit -m "Deploy infrastructure"
git push origin dev    # Auto-deploys to dev environment
git push origin test   # Auto-deploys to test environment
git push origin main   # Requires manual approval for prod

# After manual approval, observability job runs automatically
# Check pipeline for drift detection and monitoring results
```

#### 2. **Frontend Deployment (React/Vue/Angular)**

**Build and deploy to S3:**
```bash
# Build frontend
npm run build

# Upload to S3
aws s3 sync ./build s3://my-react-bucket-dev-2232131/

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <CLOUDFRONT_DISTRIBUTION_ID> \
  --paths "/*"
```

**Access frontend:**
```
https://<cloudfront-domain-name>.cloudfront.net
```

#### 3. **Backend Deployment (Microservices to EKS)**

**Connect to EKS:**
```bash
aws eks update-kubeconfig --name my-eks-dev --region ap-south-1
kubectl get nodes
```

**Deploy microservices using kubectl:**
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
    spec:
      containers:
      - name: api
        image: your-registry/backend-api:latest
        env:
        - name: DATABASE_URL
          value: "postgresql://dbadmin:password@<RDS_ENDPOINT>:5432/devdb"
        - name: REDIS_URL
          value: "redis://<REDIS_ENDPOINT>:6379"
        - name: KAFKA_BROKERS
          value: "<MSK_BOOTSTRAP_SERVERS>"
        - name: RABBITMQ_URL
          value: "amqp://user:password@<MQ_ENDPOINT>:5671"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: backend-api
spec:
  type: LoadBalancer
  selector:
    app: backend-api
  ports:
  - port: 80
    targetPort: 8080
```

**Apply deployment:**
```bash
kubectl apply -f deployment.yaml
kubectl get svc backend-api  # Get LoadBalancer URL
```

#### 4. **GitOps Deployment with ArgoCD**

**Access ArgoCD:**
```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Get ArgoCD LoadBalancer URL
kubectl get svc -n argocd argocd-server

# Login to ArgoCD UI
# URL: http://<argocd-loadbalancer-url>
# Username: admin
# Password: <from above command>
```

**Create ArgoCD Application:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-api
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: main
    path: k8s/backend
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### 5. **Database Setup**

**Connect to RDS:**
```bash
# Get RDS endpoint
cd environments/dev/rds
terragrunt output rds_endpoints

# Connect using psql
psql -h <RDS_ENDPOINT> -U dbadmin -d devdb
```

**Run migrations:**
```bash
# From your application
npm run migrate
# or
python manage.py migrate
```

#### 6. **Kafka Topic Creation**

```bash
# Run Kafka client in EKS
kubectl run kafka-client --rm -it --image=confluentinc/cp-kafka:latest --restart=Never -- bash

# Inside pod
cat > /tmp/client.properties << EOF
security.protocol=SSL
EOF

kafka-topics --create \
  --topic user-events \
  --bootstrap-server <MSK_BOOTSTRAP_SERVERS> \
  --command-config /tmp/client.properties \
  --partitions 3 \
  --replication-factor 3
```

#### 7. **Monitoring and Observability**

**Istio Service Mesh:**
```bash
# Check Istio installation
kubectl get pods -n istio-system

# Enable Istio for namespace
kubectl label namespace default istio-injection=enabled

# View service mesh
istioctl dashboard kiali
```

## Environment Structure

```
environments/
├── dev/          # Development environment
├── test/         # Testing environment
└── prod/         # Production environment
```

Each environment contains:
- `vpc/` - Network infrastructure
- `eks/` - Kubernetes cluster
- `rds/` - PostgreSQL databases
- `elasticache/` - Redis cache
- `msk/` - Kafka cluster
- `mq/` - RabbitMQ broker
- `s3/` - Static assets bucket
- `cloudfront/` - CDN distribution
- `helm-apps/` - ArgoCD + Istio

## Use Case: Full Stack E-commerce Application

### Frontend (React)
- Hosted on S3 + CloudFront
- Global CDN delivery
- HTTPS enabled

### Backend (Node.js/Python/Java Microservices)
- **API Gateway Service**: Routes requests (EKS)
- **User Service**: Authentication, profiles (EKS + RDS + Redis)
- **Product Service**: Catalog management (EKS + RDS + ElastiCache)
- **Order Service**: Order processing (EKS + RDS + MSK)
- **Payment Service**: Payment processing (EKS + RDS)
- **Notification Service**: Email/SMS (EKS + MQ)
- **Analytics Service**: Event processing (EKS + MSK)

### Data Flow
1. User accesses frontend via CloudFront
2. Frontend calls backend APIs via ALB
3. APIs authenticate using Redis sessions
4. APIs read/write to RDS databases
5. APIs publish events to Kafka (MSK)
6. Background workers consume from RabbitMQ (MQ)
7. Analytics service processes Kafka streams

## GitLab CI/CD Pipeline

### Pipeline Stages
1. **scan**: Test pipeline functionality (always runs)
2. **init**: Terragrunt initialization with cache cleanup
3. **validate**: Terraform validation
4. **security**: IaC security scanning (Checkov, tfsec)
5. **plan**: Terraform plan generation and policy checks
6. **apply**: Multi-region deployment with manual approval for prod
7. **observability**: Post-deployment monitoring, drift detection, and security checks

### Multi-Region Configuration

Set these variables in GitLab CI/CD settings (Group or Project level):

```bash
# Development regions (comma-separated)
AWS_REGIONS_DEV="ap-south-1"

# Test regions (comma-separated)
AWS_REGIONS_TEST="ap-south-1,us-east-1"

# Production regions (comma-separated)
AWS_REGIONS_PROD="ap-south-1,us-east-1,eu-west-1"

# AWS credentials
AWS_ACCESS_KEY_ID="<your-access-key>"
AWS_SECRET_ACCESS_KEY="<your-secret-key>"
```

### Branch-Based Deployment

- **dev branch** → Deploys to dev environment (auto-approve)
- **test branch** → Deploys to test environment (auto-approve)
- **main branch** → Deploys to prod environment (manual approval required)

### Resource Naming for Multi-Region

Resources with region suffixes:
- S3 buckets: `my-react-bucket-dev-2232131-ap-south-1`
- ElastiCache: `my-redis-dev-ap-south-1`
- CloudFront OAC: Derived from S3 bucket name

Region-scoped resources (no suffix needed):
- EKS clusters
- RDS instances
- MSK clusters
- Amazon MQ brokers

### Pipeline Features

- **Test Job**: Always-running pipeline health check
- **Security Scanning**: Checkov and tfsec for IaC vulnerabilities
- **Policy Checks**: OPA/Conftest policy validation on plans
- **Multi-Region Deployment**: Automatic deployment across configured regions
- **Observability**: Post-deployment drift detection, EKS monitoring, security posture checks
- **Artifact Storage**: Plan outputs, drift reports, and deployment reports stored for 7-30 days
- **Manual Destroy**: Separate destroy jobs for each environment
- **Error Handling**: Resilient observability checks with graceful failure handling

### Pipeline Job Details

#### Apply Jobs
- **Dev**: Auto-approve, 7-day artifact retention
- **Test**: Auto-approve, 14-day artifact retention  
- **Prod**: Manual approval required, 30-day artifact retention

#### Observability Job
- **Dependencies**: Runs after `terragrunt-apply-prod` completes
- **Features**: 
  - EKS cluster health checks
  - Infrastructure drift detection
  - Security posture validation
  - S3 state bucket access verification
- **Error Handling**: Graceful failure with detailed logging
- **Artifacts**: Drift reports and logs stored for 30 days

### Triggering Deployments

**Automatic triggers** (on file changes):
```bash
# Changes to modules or environment configs trigger pipeline
modules/**/*
environments/{dev,test,prod}/**/*
```

**Manual actions**:
- **Production Deploy**: Manual approval required in GitLab UI
- **Destroy Jobs**: Navigate to GitLab CI/CD → Pipelines → Manual Jobs → Click "Play"

## Configuration Management

### Terragrunt Variables
- Regions: Configured via GitLab CI/CD variables
- Environment: `dev`, `test`, `prod`
- Instance sizes: Configurable per environment
- RDS count: Configurable (default: 1 for dev, 2 for test, 3 for prod)

### State Management
- Backend: S3 (per region)
- State locking: DynamoDB (per region)
- Bucket pattern: `my-terraform-states-<region>`
- Lock table: `terraform-locks`

## Prerequisites

### Local Development
1. AWS CLI configured with credentials
2. Terraform >= 1.0
3. Terragrunt >= 0.68.5
4. kubectl installed
5. helm installed

### GitLab CI/CD
1. GitLab Runner with Docker executor
2. AWS credentials configured in GitLab CI/CD variables
3. Region variables set (AWS_REGIONS_DEV, AWS_REGIONS_TEST, AWS_REGIONS_PROD)

### AWS Resources (per region)
1. S3 bucket for state: `my-terraform-states-<region>`
2. DynamoDB table: `terraform-locks` (Partition key: `LockID`)

## Getting Started

### Option 1: GitLab CI/CD (Recommended)

```bash
# 1. Clone repository
git clone <repo-url>
cd aws-resource-creation-iaac

# 2. Configure GitLab CI/CD variables
# Go to GitLab → Settings → CI/CD → Variables
# Add: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
# Add: AWS_REGIONS_DEV, AWS_REGIONS_TEST, AWS_REGIONS_PROD

# 3. Setup multi-region backends (run once)
bash scripts/setup-multi-region-backend.sh "ap-south-1,us-east-1,eu-west-1"

# 4. Push to trigger deployment
git checkout -b dev
git add .
git commit -m "Initial deployment"
git push origin dev
```

### Option 2: Manual Deployment

```bash
# Clone repository
git clone <repo-url>
cd aws-resource-creation-iaac

# Create S3 bucket for state (per region)
aws s3 mb s3://my-terraform-states-ap-south-1 --region ap-south-1

# Create DynamoDB table for locking (per region)
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1

# Deploy infrastructure
cd environments/dev
terragrunt run-all apply
```

## Cleanup

### GitLab CI/CD
```bash
# Navigate to GitLab → CI/CD → Pipelines
# Find latest pipeline → Manual Jobs
# Click "Play" on destroy-dev/destroy-test/destroy-prod
```

### Manual
```bash
# Destroy all resources
cd environments/dev
terragrunt run-all destroy

# For multi-region cleanup
for region in ap-south-1 us-east-1 eu-west-1; do
  export AWS_REGION=$region
  cd environments/dev
  terragrunt run-all destroy --terragrunt-non-interactive
done
```

## Security Best Practices

### Infrastructure Security
- All resources in private subnets (except ALB)
- S3 buckets are private with CloudFront OAC
- RDS, ElastiCache, MSK, MQ only accessible from VPC
- EKS uses IAM roles for service accounts
- TLS encryption enabled for MSK
- Security groups restrict traffic to VPC CIDR

### CI/CD Security
- Secrets scanning with Gitleaks
- IaC security scanning (Checkov, tfsec)
- AWS credentials stored as protected variables
- Manual approval required for production
- State files encrypted in S3
- DynamoDB state locking prevents concurrent modifications

## Cost Optimization

- Single NAT Gateway for dev/test
- t3.small instances for dev
- Auto-scaling enabled
- Spot instances can be configured for non-prod

## Support

For issues or questions, please open an issue in the repository.
