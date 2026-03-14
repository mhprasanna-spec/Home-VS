# Terraform EKS Cluster – Line by Line Explanation

This document explains the **Terraform configuration used to deploy a Kubernetes cluster using Amazon EKS**.
Each block is explained so you understand **what it does and why it is required**.

---

# 1️⃣ AWS Provider Configuration

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

### What this does

This block tells Terraform:

* Use the **AWS provider**
* Deploy infrastructure in the **Mumbai region (`ap-south-1`)**

### Why it is needed

Terraform must know:

* Which **cloud provider** to interact with
* Which **region** to create resources in

Without this block Terraform cannot communicate with AWS.

---

# 2️⃣ Fetch AWS Account Information

```hcl
data "aws_caller_identity" "current" {}
```

### What this does

This retrieves information about the currently authenticated AWS account.

It returns:

* AWS Account ID
* User ARN
* User ID

### Why it is needed

Later in the configuration we dynamically generate an IAM ARN like:

```
arn:aws:iam::<account-id>:root
```

Using a data source prevents **hardcoding the account ID**.

---

# 3️⃣ Create IAM Role for the EKS Cluster

```hcl
resource "aws_iam_role" "cluster" {
  name = "eks-cluster-example"
```

### What this does

Creates an IAM role named:

```
eks-cluster-example
```

### Why it is needed

The EKS control plane must interact with AWS services like:

* EC2
* Load Balancers
* Security Groups
* Networking

This IAM role allows the **EKS control plane to perform these actions**.

---

# 4️⃣ Define the Trust Policy

```hcl
assume_role_policy = jsonencode({
```

### What this does

Defines a **trust relationship policy**.

It determines **who is allowed to assume this IAM role**.

Terraform uses:

```
jsonencode()
```

to convert the Terraform configuration into JSON format required by AWS.

---

```hcl
Version = "2012-10-17"
```

Standard IAM policy version used by AWS.

---

```hcl
Statement = [{
```

Policy statement block.

---

```hcl
Action = ["sts:AssumeRole", "sts:TagSession"]
```

Allows the **EKS service** to assume this role using **AWS Security Token Service (STS)**.

---

```hcl
Effect = "Allow"
```

Grants the permission.

---

```hcl
Principal = {
  Service = "eks.amazonaws.com"
}
```

This means:

> The EKS service can assume this IAM role.

Without this trust relationship the cluster **cannot use the role**.

---

# 5️⃣ Attach the EKS Cluster Policy

```hcl
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy"
```

### What this does

Attaches the AWS managed policy:

```
AmazonEKSClusterPolicy
```

### Why it is needed

This policy allows EKS to:

* Manage networking
* Manage load balancers
* Manage security groups
* Communicate with EC2

---

# 6️⃣ Retrieve the Default VPC

```hcl
data "aws_vpc" "default" {
  default = true
}
```

### What this does

Fetches the **default VPC** that AWS automatically creates in every account.

### Why it is used

For learning environments it is easier to reuse the default VPC instead of creating a new one.

In production environments a **custom VPC is usually created**.

---

# 7️⃣ Retrieve Subnets from the VPC

```hcl
data "aws_subnets" "default" {
```

This block retrieves the **subnets inside the default VPC**.

---

```hcl
filter {
  name   = "vpc-id"
  values = [data.aws_vpc.default.id]
}
```

### What this does

Filters the subnets belonging to the default VPC.

### Why this is needed

EKS clusters and worker nodes must run **inside VPC subnets**.

---

# 8️⃣ Create the EKS Cluster

```hcl
resource "aws_eks_cluster" "cluster" {
```

This creates the **Kubernetes control plane**.

The control plane includes:

* Kubernetes API Server
* Scheduler
* etcd database

AWS manages these components automatically.

---

```hcl
name = "cluster"
```

Name of the Kubernetes cluster.

---

```hcl
role_arn = aws_iam_role.cluster.arn
```

Assigns the IAM role created earlier to the cluster.

This allows the cluster to interact with AWS resources.

---

# 9️⃣ Configure Cluster Authentication

```hcl
access_config {
  authentication_mode = "API"
}
```

### What this does

Uses **API based authentication** for cluster access.

### Why AWS introduced it

Previously access was managed using the **aws-auth ConfigMap**.

API-based access is easier to manage and more secure.

---

# 🔟 Configure Cluster Networking

```hcl
vpc_config {
  subnet_ids = data.aws_subnets.default.ids
}
```

### What this does

Specifies which subnets the cluster should use.

These subnets allow communication between:

* Control plane
* Worker nodes
* Kubernetes pods

---

# 11️⃣ Resource Dependency

```hcl
depends_on = [
  aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
]
```

### What this does

Ensures Terraform attaches the policy **before creating the cluster**.

### Why this is important

Without the policy the cluster would not have required permissions.

---

# 12️⃣ Create IAM Role for Worker Nodes

```hcl
resource "aws_iam_role" "node" {
```

Creates an IAM role used by **EC2 worker nodes**.

Worker nodes run:

* Kubernetes pods
* Containers
* Application workloads

---

```hcl
Principal = {
  Service = "ec2.amazonaws.com"
}
```

Allows EC2 instances to assume the role.

---

# 13️⃣ Attach Worker Node Policies

Worker nodes require several permissions.

---

## AmazonEKSWorkerNodePolicy

Allows worker nodes to communicate with the Kubernetes control plane.

---

## AmazonEKSWorkerNodeMinimalPolicy

Provides minimal permissions following the **principle of least privilege**.

---

## AmazonEKS_CNI_Policy

Required for Kubernetes networking.

It allows pods to receive **IP addresses from the VPC**.

---

## AmazonEC2ContainerRegistryReadOnly

Allows worker nodes to pull container images from **Amazon ECR**.

---

# 14️⃣ Create Managed Node Group

```hcl
resource "aws_eks_node_group" "node-ec2"
```

Creates a **managed node group**.

AWS automatically manages:

* EC2 instances
* Node scaling
* Node lifecycle

---

```hcl
cluster_name = aws_eks_cluster.cluster.name
```

Associates the nodes with the EKS cluster.

---

```hcl
node_group_name = "worker-nodes"
```

Name of the node group.

---

```hcl
node_role_arn = aws_iam_role.node.arn
```

Assigns the IAM role to worker nodes.

---

```hcl
subnet_ids = data.aws_subnets.default.ids
```

Worker nodes run inside the VPC subnets.

---

# 15️⃣ Auto Scaling Configuration

```hcl
scaling_config {
  desired_size = 2
  max_size     = 3
  min_size     = 1
}
```

Controls the number of worker nodes.

| Setting      | Description   |
| ------------ | ------------- |
| min_size     | Minimum nodes |
| desired_size | Default nodes |
| max_size     | Maximum nodes |

---

# 16️⃣ Node Instance Configuration

```hcl
ami_type = "AL2023_x86_64_STANDARD"
```

Uses **Amazon Linux 2023 optimized for Kubernetes**.

---

```hcl
instance_types = ["c7i-flex.large"]
```

EC2 instance type used for worker nodes.

---

```hcl
capacity_type = "ON_DEMAND"
```

Uses standard EC2 pricing instead of spot instances.

---

```hcl
disk_size = 20
```

Each worker node receives **20 GB storage**.

---

# 17️⃣ Node Dependency Control

```hcl
depends_on = [
  aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
  aws_iam_role_policy_attachment.AmazonEKSWorkerNodeMinimalPolicy,
  aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
]
```

Ensures policies attach **before launching worker nodes**.

---

# 18️⃣ Create EKS Access Entry

```hcl
resource "aws_eks_access_entry" "admin"
```

Grants IAM users access to the cluster.

---

```hcl
principal_arn = "arn:aws:iam::<account-id>:root"
```

Allows the AWS account owner to access the cluster.

---

# 19️⃣ Attach Cluster Admin Policy

```hcl
aws_eks_access_policy_association
```

Attaches the policy:

```
AmazonEKSClusterAdminPolicy
```

This gives full administrative control over the Kubernetes cluster.

---

# Final Resource Creation Flow

Terraform creates resources in this order:

```
IAM Roles
   ↓
IAM Policies
   ↓
VPC + Subnets (Data)
   ↓
EKS Cluster
   ↓
Worker Node Role
   ↓
Node Group
   ↓
Cluster Access
```

---

# Connect to the Cluster

After Terraform deployment run:

```
aws eks update-kubeconfig --region ap-south-1 --name cluster
```

Then verify nodes:

```
kubectl get nodes
```

---

# Summary

This Terraform configuration deploys a **fully functional Kubernetes cluster on AWS** with:

* Managed EKS control plane
* Auto scaling worker nodes
* IAM roles and policies
* Networking via VPC subnets
* Secure cluster access

This setup allows developers to **deploy containerized applications using Kubernetes on AWS**.
