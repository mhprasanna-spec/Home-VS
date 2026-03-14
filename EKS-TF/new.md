# 🚀 Terraform EKS Cluster Setup (AWS)

This project provisions a **Kubernetes cluster on AWS** using Terraform and **Amazon Elastic Kubernetes Service (EKS)**.
It automatically creates the infrastructure required to run containerized applications in Kubernetes.

The configuration deploys:

* IAM roles for the EKS control plane
* IAM roles for worker nodes
* Required IAM policies
* EKS cluster
* Managed node group
* Access configuration for cluster administration
* Default VPC networking

Region used: **ap-south-1 (Mumbai)**

---

# 📦 Services Used

This project uses the following AWS services:

* Amazon Elastic Kubernetes Service (EKS)
* IAM (Identity and Access Management)
* EC2 Worker Nodes
* VPC (Default AWS VPC)
* ECR access for container images

---

# 🏗 Architecture Overview

```
AWS
│
├── IAM
│   ├── EKS Cluster Role
│   └── Worker Node Role
│
├── Networking
│   ├── Default VPC
│   └── Default Subnets
│
└── EKS
    ├── Kubernetes Control Plane
    └── Managed Node Group
        ├── EC2 Instances
        └── Auto Scaling
```

---

# 📂 Project Structure

```
terraform-eks
│
├── main.tf
└── README.md
```

---

# ⚙️ Prerequisites

Before running this project ensure the following tools are installed:

| Tool      | Purpose                     |
| --------- | --------------------------- |
| Terraform | Infrastructure provisioning |
| AWS CLI   | Authenticate with AWS       |
| kubectl   | Manage Kubernetes cluster   |

---

# 🔑 Configure AWS Credentials

Configure AWS CLI:

```bash
aws configure
```

Provide:

```
AWS Access Key
AWS Secret Key
Region: ap-south-1
Output format: json
```

---

# ☸️ Install kubectl

kubectl is the command-line tool used to interact with Kubernetes clusters.

### Install kubectl on Linux

```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

Verify installation:

```
kubectl version --client
```

---

Verify installation:

```
kubectl version --client
```

---

# 🛠 Terraform Workflow

Terraform follows a standard workflow:

### Initialize Terraform

```
terraform init
```

Downloads the AWS provider and initializes the project.

---

### Validate Configuration

```
terraform validate
```

Ensures the Terraform syntax and configuration are correct.

---

### Preview Infrastructure Changes

```
terraform plan
```

Shows the execution plan before resources are created.

---

### Deploy Infrastructure

```
terraform apply
```

Creates the infrastructure.

Confirm with:

```
yes
```

---

# ☸️ Configure Kubernetes Access

After the cluster is created, configure kubeconfig.

```
aws eks update-kubeconfig --region ap-south-1 --name cluster
```

This command allows **kubectl to communicate with the EKS cluster**.

---

# 🔎 Verify Cluster

Check if worker nodes joined the cluster:

```
kubectl get nodes
```

Expected output:

```
NAME                         STATUS   ROLES
ip-10-0-x-x                  Ready    <none>
ip-10-0-x-x                  Ready    <none>
```

Check all running pods:

```
kubectl get pods -A
```

---

# ⚙️ Infrastructure Components

The Terraform configuration creates the following resources:

### 1️⃣ EKS Cluster Role

Allows the EKS control plane to manage AWS resources.

Policies attached:

* AmazonEKSClusterPolicy

---

### 2️⃣ Worker Node Role

Allows EC2 instances to function as Kubernetes worker nodes.

Policies attached:

* AmazonEKSWorkerNodePolicy
* AmazonEKSWorkerNodeMinimalPolicy
* AmazonEKS_CNI_Policy
* AmazonEC2ContainerRegistryReadOnly

---

### 3️⃣ Default VPC

Instead of creating a new network, the configuration retrieves the **default AWS VPC and subnets**.

---

### 4️⃣ EKS Cluster

Creates the Kubernetes control plane managed by AWS.

Key configuration:

```
name = "cluster"
authentication_mode = "API"
```

---

### 5️⃣ Managed Node Group

Creates EC2 worker nodes that automatically join the cluster.

Configuration:

| Setting       | Value          |
| ------------- | -------------- |
| Instance Type | c7i-flex.large |
| Disk Size     | 20 GB          |
| Capacity Type | On-Demand      |
| Desired Nodes | 2              |
| Max Nodes     | 3              |
| Min Nodes     | 1              |

---

### 6️⃣ Cluster Access Entry

Grants IAM principals permission to access the Kubernetes cluster.

This allows administrators to manage the cluster using **kubectl**.

---

# 🧹 Destroy Infrastructure

To delete all resources:

```
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
| VPC         | Default AWS VPC          |
| Subnets     | Default AWS Subnets      |

---

# 🎯 Summary

This Terraform project automates the deployment of a **production-ready Kubernetes cluster on AWS using EKS**.

Features:

* Infrastructure as Code using Terraform
* Managed Kubernetes control plane
* Auto-scaling worker nodes
* IAM-based authentication
* kubectl integration

---

# ⭐ Future Improvements

Possible enhancements:

* Custom VPC with public and private subnets
* NAT Gateway
* Load Balancer Controller
* Helm deployment
* CI/CD pipeline integration
* Terraform modules

---

# 📚 References

* Terraform Documentation
* AWS EKS Documentation
* Kubernetes Documentation
