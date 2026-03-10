# Terraform AWS VPC Infrastructure (Using Modules)

This project demonstrates how to create a **production-style AWS networking infrastructure** using **Infrastructure as Code** with **Terraform**.

The Terraform configuration provisions the following AWS networking components:

* VPC
* Public Subnets
* Private Subnets
* Internet Gateway
* Elastic IP
* NAT Gateway
* Route Tables
* Route Table Associations

The infrastructure is deployed on **AWS** using reusable **Terraform modules**.

---

# Architecture Overview

The infrastructure created looks like the following:

```
VPC
│
├── Internet Gateway
│
├── Public Subnets
│     └── NAT Gateway
│
├── Private Subnets
│
├── Public Route Table
│     └── Route → Internet Gateway
│
└── Private Route Table
      └── Route → NAT Gateway
```

Public subnets allow internet access while private subnets route outbound traffic through a NAT Gateway.

---

# Project Structure

```
terraform-vpc
│
├── main.tf
├── variables.tf
├── outputs.tf
│
└── modules
    └── vpc
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

Root files call the module while the **module folder contains the reusable infrastructure code**.

---

# Root Module Explanation

## main.tf

```
provider "aws" {
  region = var.aws_region
}

module "vpc_network" {

  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}
```

### Explanation

**provider "aws"**

Specifies that Terraform will manage infrastructure in AWS.

```
region = var.aws_region
```

The AWS region is obtained from a variable instead of being hardcoded.

Example:

```
us-east-1
```

---

### Module Block

```
module "vpc_network"
```

This block calls the **VPC module**.

```
source = "./modules/vpc"
```

Terraform loads the infrastructure code from the module directory.

---

### Input Variables Passed to the Module

```
vpc_cidr = var.vpc_cidr
```

Defines the VPC network range.

Example:

```
10.0.0.0/16
```

---

```
public_subnet_cidrs = var.public_subnet_cidrs
```

Defines CIDR ranges for public subnets.

Example:

```
10.0.1.0/24
10.0.2.0/24
10.0.5.0/24
10.0.6.0/24
```

---

```
private_subnet_cidrs = var.private_subnet_cidrs
```

Defines CIDR ranges for private subnets.

Example:

```
10.0.3.0/24
10.0.4.0/24
```

---

```
availability_zones = var.availability_zones
```

Defines which Availability Zones the subnets will be deployed into.

Example:

```
us-east-1a
us-east-1b
us-east-1c
us-east-1d
```

---

# Variables

## variables.tf

```
variable "aws_region" {
  default = "us-east-1"
}
```

Defines the AWS region where resources will be deployed.

---

```
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
```

Defines the main CIDR block for the VPC.

---

```
variable "public_subnet_cidrs"
```

List of CIDR blocks for public subnets.

---

```
variable "private_subnet_cidrs"
```

List of CIDR blocks for private subnets.

---

```
variable "availability_zones"
```

List of availability zones used for subnet placement.

---

# Outputs

## outputs.tf

```
output "vpc_id" {
  value = module.vpc_network.vpc_id
}
```

Displays the created VPC ID.

Example output:

```
vpc-123abc
```

---

```
output "public_subnet_ids" {
  value = module.vpc_network.public_subnet_ids
}
```

Displays IDs of the public subnets.

---

```
output "private_subnet_ids" {
  value = module.vpc_network.private_subnet_ids
}
```

Displays IDs of the private subnets.

---

# Module: VPC

The module located at:

```
modules/vpc
```

contains the actual AWS resource definitions.

---

# Resources Created in Module

## VPC

```
resource "aws_vpc" "main_vpc"
```

Creates a Virtual Private Cloud.

```
cidr_block = var.vpc_cidr
```

Defines the network range of the VPC.

---

# Public Subnets

```
resource "aws_subnet" "public_subnet"
```

Creates multiple public subnets.

```
count = length(var.public_subnet_cidrs)
```

Creates a subnet for each CIDR provided.

```
map_public_ip_on_launch = true
```

Ensures instances launched in public subnets receive public IP addresses.

---

# Private Subnets

```
resource "aws_subnet" "private_subnet"
```

Creates private subnets.

These do **not receive public IP addresses**.

Private subnets are typically used for:

* Databases
* Backend services
* Internal APIs

---

# Internet Gateway

```
resource "aws_internet_gateway" "igw"
```

Allows communication between the VPC and the public internet.

---

# Elastic IP

```
resource "aws_eip" "nat_eip"
```

Allocates a static public IP address used by the NAT Gateway.

---

# NAT Gateway

```
resource "aws_nat_gateway" "nat"
```

Allows instances in private subnets to access the internet.

Example use case:

```
Private EC2 instance → Download software updates
```

Traffic flow:

```
Private Subnet → NAT Gateway → Internet
```

---

# Route Tables

## Public Route Table

```
resource "aws_route_table" "public_rt"
```

Routes traffic from public subnets to the Internet Gateway.

```
0.0.0.0/0 → IGW
```

---

## Private Route Table

```
resource "aws_route_table" "private_rt"
```

Routes internet traffic from private subnets through the NAT Gateway.

```
0.0.0.0/0 → NAT Gateway
```

---

# Route Table Associations

Route table associations link subnets to route tables.

```
aws_route_table_association
```

Without these associations, routing rules would not apply to the subnets.

---

# How to Deploy

Initialize Terraform:

```
terraform init
```

Check the execution plan:

```
terraform plan
```

Apply the configuration:

```
terraform apply
```

Terraform will then create all AWS networking resources automatically.

---

# Key Terraform Concepts Demonstrated

This project demonstrates important Terraform concepts including:

* Infrastructure as Code
* Terraform Modules
* Input Variables
* Output Values
* Resource Dependencies
* AWS Networking Infrastructure

---

# Future Improvements

Possible improvements for production usage:

* Remote state storage using S3
* State locking with DynamoDB
* Environment separation (dev, stage, prod)
* Security groups and network ACLs
* Automated CI/CD deployment

---

# Author
**Prasanna Waghmare**
Created as a **Terraform networking project for learning DevOps and AWS infrastructure automation**.
