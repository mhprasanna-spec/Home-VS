# 🚀 Terraform EKS Cluster Setup (AWS)

This project provisions an **Amazon Elastic Kubernetes Service (EKS)** cluster using **Terraform**.
It automatically creates:

* IAM roles for the cluster and worker nodes
* Policy attachments required by EKS
* Uses the default VPC and subnets
* Creates an EKS control plane
* Creates a managed node group (EC2 worker nodes)

The infrastructure is deployed in **ap-south-1 (Mumbai region)**.

---

# 📌 Architecture Overview

Terraform will provision the following resources:

```
AWS
│
├── IAM
│   ├── EKS Cluster Role
│   └── Worker Node Role
│
├── VPC
│   └── Default VPC (Data Source)
│
├── Subnets
│   └── Default VPC Subnets (Data Source)
│
└── EKS
    ├── EKS Cluster
    └── Managed Node Group
        ├── EC2 Worker Nodes
        └── Auto Scaling
```

---

# 📂 Project Structure

```
.
├── main.tf
└── README.md
```

---

# ⚙️ Prerequisites

Before running this project ensure you have:

* **Terraform installed**
* **AWS CLI configured**
* An AWS account with sufficient permissions

Tools required:

* Terraform ≥ 1.3
* AWS CLI ≥ 2.x
* kubectl (optional for cluster access)

---

# 🔑 Provider Configuration

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

This configures Terraform to use the **AWS provider** in the **Mumbai region**.

---

# 🧑‍💻 IAM Role for EKS Cluster

```hcl
resource "aws_iam_role" "cluster" {
  name = "eks-cluster-example"
```

Creates an **IAM role** used by the EKS control plane.

The `assume_role_policy` allows the **EKS service** to assume the role.

```
Principal = { Service = "eks.amazonaws.com" }
```

---

# 📎 Attach EKS Cluster Policy

```hcl
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy"
```

Attaches the required AWS managed policy:

```
AmazonEKSClusterPolicy
```

This policy allows EKS to:

* Manage cluster infrastructure
* Communicate with other AWS services

---

# 🌐 Fetch Default VPC

```hcl
data "aws_vpc" "default" {
  default = true
}
```

Instead of creating a new VPC, Terraform fetches the **existing default VPC** from AWS.

---

# 📡 Fetch Subnets from the Default VPC

```hcl
data "aws_subnets" "default"
```

This retrieves all **subnets associated with the default VPC**.

These subnets are used by:

* EKS Control Plane
* Worker Nodes

---

# ☸️ Create the EKS Cluster

```hcl
resource "aws_eks_cluster" "cluster"
```

This resource provisions the **Kubernetes control plane**.

### Key Settings

**Cluster Name**

```
cluster
```

**Authentication Mode**

```
authentication_mode = "API"
```

This allows API based authentication.

**VPC Configuration**

```
subnet_ids = data.aws_subnets.default.ids
```

The cluster will run inside the default VPC subnets.

---

# 🖥️ IAM Role for Worker Nodes

```hcl
resource "aws_iam_role" "node"
```

Creates an IAM role used by **EC2 worker nodes**.

The role trust policy allows **EC2 instances** to assume the role.

```
Principal = { Service = "ec2.amazonaws.com" }
```

---

# 🔐 Worker Node Policies

Three policies are attached to the worker node role.

## 1️⃣ AmazonEKSWorkerNodePolicy

Allows EC2 instances to communicate with the EKS cluster.

```
AmazonEKSWorkerNodePolicy
```

---

## 2️⃣ AmazonEKS_CNI_Policy

Allows Kubernetes networking through the **AWS VPC CNI plugin**.

```
AmazonEKS_CNI_Policy
```

---

## 3️⃣ AmazonEC2ContainerRegistryReadOnly

Allows worker nodes to pull container images from **Amazon ECR**.

```
AmazonEC2ContainerRegistryReadOnly
```

---

# ⚙️ EKS Managed Node Group

```hcl
resource "aws_eks_node_group" "node-ec2"
```

Creates a **managed node group** containing EC2 instances that run Kubernetes workloads.

---

## Node Group Configuration

### Instance Type

```
c7i-flex.large
```

### AMI Type

```
AL2023_x86_64_STANDARD
```

Uses **Amazon Linux 2023 optimized for EKS**.

---

### Storage

```
disk_size = 20
```

Each node has a **20GB root volume**.

---

### Capacity Type

```
ON_DEMAND
```

Nodes are launched using **on-demand pricing**.

---

# 📈 Auto Scaling Configuration

```hcl
scaling_config {
  desired_size = 2
  max_size     = 3
  min_size     = 1
}
```

This means:

| Setting      | Description           |
| ------------ | --------------------- |
| min_size     | Minimum nodes         |
| desired_size | Default running nodes |
| max_size     | Maximum nodes allowed |

---

# ⛓️ Dependency Management

Terraform ensures that IAM policies are attached **before nodes start launching**.

```hcl
depends_on = [
  aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
  aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
]
```

This prevents **permission errors during node creation**.

---

# ▶️ How to Deploy

### 1️⃣ Initialize Terraform

```bash
terraform init
```

---

### 2️⃣ Preview Infrastructure

```bash
terraform plan
```

---

### 3️⃣ Deploy Infrastructure

```bash
terraform apply
```

Confirm by typing:

```
yes
```

---

# 🧹 Destroy Infrastructure

To delete everything:

```bash
terraform destroy
```

---

# 📊 Resources Created

| Resource    | Description              |
| ----------- | ------------------------ |
| IAM Role    | EKS Control Plane Role   |
| IAM Role    | Worker Node Role         |
| EKS Cluster | Kubernetes Control Plane |
| Node Group  | EC2 Worker Nodes         |
| VPC         | Uses default AWS VPC     |
| Subnets     | Uses default VPC subnets |

---

# 📚 Useful Commands After Deployment

Update kubeconfig to access your cluster:

```bash
aws eks update-kubeconfig --region ap-south-1 --name cluster
```

Check nodes:

```bash
kubectl get nodes
```

Check pods:

```bash
kubectl get pods -A
```

---

# 🏁 Summary

This Terraform configuration automates the deployment of a **production-ready Amazon EKS cluster** including:

* IAM roles
* Networking
* Kubernetes control plane
* Managed worker nodes

Using Terraform ensures the infrastructure is **repeatable, version-controlled, and easy to manage**.

---

⭐ If this project helped you, consider giving it a star on GitHub.
