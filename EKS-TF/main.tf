provider "aws" {
  region = "ap-south-1"
}

# --- 1. IAM Role for EKS Cluster ---
resource "aws_iam_role" "cluster" {
  name = "eks-cluster-example"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["sts:AssumeRole", "sts:TagSession"]
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# --- 2. Networking Data ---
data "aws_vpc" "default" { default = true }

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- 3. EKS Cluster ---
resource "aws_eks_cluster" "cluster" {
  name     = "cluster"
  role_arn = aws_iam_role.cluster.arn
  access_config { authentication_mode = "API" }

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy]
}

# --- 4. IAM Role for Worker Nodes ---
resource "aws_iam_role" "node" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" } # Fixed syntax here
    }]
  })
}

# Required Policy 1: Worker Node Policy (Renamed to match your depends_on)
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

# Required Policy 2: CNI Policy
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

# Required Policy 3: ECR Read Only
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# --- 5. EKS Managed Node Group (The Worker Nodes) ---
resource "aws_eks_node_group" "node-ec2" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "worker-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  ami_type       = "AL2023_x86_64_STANDARD"
  instance_types = ["c7i-flex.large"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  # Ensure IAM Policies are attached BEFORE nodes start creating
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}