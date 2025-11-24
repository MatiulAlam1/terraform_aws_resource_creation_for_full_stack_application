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

## Configuration Management

### Terragrunt Variables
- Region: `ap-south-1` (configurable)
- Environment: `dev`, `test`, `prod`
- Instance sizes: Configurable per environment
- RDS count: Configurable (default: 1 for dev, 2 for test, 3 for prod)

### State Management
- Backend: S3
- State locking: DynamoDB
- Bucket: `my-terraform-states-ap-south-1`
- Lock table: `terraform-locks`

## Prerequisites

1. AWS CLI configured with credentials
2. Terraform >= 1.0
3. Terragrunt installed
4. kubectl installed
5. helm installed
6. S3 bucket for state: `my-terraform-states-ap-south-1`
7. DynamoDB table: `terraform-locks` (Partition key: `LockID`)

## Getting Started

```bash
# Clone repository
git clone <repo-url>
cd terraform-terragrunt-eks-vpc-setup-

# Create S3 bucket for state
aws s3 mb s3://my-terraform-states-ap-south-1 --region ap-south-1

# Create DynamoDB table for locking
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

```bash
# Destroy all resources
cd environments/dev
terragrunt run-all destroy
```

## Security Best Practices

- All resources in private subnets (except ALB)
- S3 buckets are private with CloudFront OAC
- RDS, ElastiCache, MSK, MQ only accessible from VPC
- EKS uses IAM roles for service accounts
- TLS encryption enabled for MSK
- Security groups restrict traffic to VPC CIDR

## Cost Optimization

- Single NAT Gateway for dev/test
- t3.small instances for dev
- Auto-scaling enabled
- Spot instances can be configured for non-prod

## Support

For issues or questions, please open an issue in the repository.
