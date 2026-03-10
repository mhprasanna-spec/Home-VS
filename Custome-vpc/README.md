### Terraform VPC 
code step-by-step so you understand what each block does and how resources connect in AWS networking.

We will go in this order:

- Provider

- Variables

- VPC

- Subnets

- Internet Gateway

- Elastic IP

- NAT Gateway

- Route Tables

- Route Table Associations

- Outputs

How Terraform executes everything

## 1️⃣ Provider Block
provider "aws" {
  region = var.aws_region
}
What this means

This tells Terraform:

“Use the AWS provider and create resources in this region.”

The region value is coming from the variable:

var.aws_region

Later we define:

variable "aws_region" {
  default = "us-east-1"
}

So Terraform will create everything in us-east-1.

## 2️⃣ Variables

Variables make Terraform flexible and reusable.

Example:

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
CIDR Meaning
10.0.0.0/16

This means:

Network range from

10.0.0.0 → 10.0.255.255

Total IPs ≈ 65,536

So this is the main network of the VPC.

Public subnet variables
variable "public_subnet_cidrs" {
  type = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

Here we define multiple subnet CIDRs.

10.0.1.0/24
10.0.2.0/24

Each /24 subnet has:

256 IP addresses
Private subnet variables
variable "private_subnet_cidrs" {
  type = list(string)

  default = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}

These will be private networks.

Used for:

databases

backend servers

internal services

Availability Zones
variable "availability_zones" {
  type = list(string)

  default = [
    "us-east-1a",
    "us-east-1b"
  ]
}

AWS region us-east-1 has multiple availability zones.

Example:

us-east-1a
us-east-1b
us-east-1c

Using multiple AZs improves high availability.

## 3️⃣ VPC Creation
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "My-VPC"
  }
}

This creates the Virtual Private Cloud.

Think of VPC as:

Your private network inside AWS

Inside this network you will create:

subnets

instances

load balancers

databases

The tag:

Name = My-VPC

just labels the resource in AWS console.

## 4️⃣ Public Subnets
resource "aws_subnet" "public_subnet" {

  count = length(var.public_subnet_cidrs)
What count does

count tells Terraform:

create multiple resources

Here:

public_subnet_cidrs = 2 values

So Terraform creates:

2 public subnets
Subnet properties
vpc_id = aws_vpc.main_vpc.id

This attaches the subnet to the VPC.

cidr_block = var.public_subnet_cidrs[count.index]

This selects the CIDR based on index.

Example:

index	CIDR
0	10.0.1.0/24
1	10.0.2.0/24
availability_zone = var.availability_zones[count.index]

So:

Subnet	AZ
subnet1	us-east-1a
subnet2	us-east-1b
Public IP setting
map_public_ip_on_launch = true

This means:

Any EC2 launched here automatically gets a public IP

This is required for internet-facing instances.

## 5️⃣ Private Subnets
resource "aws_subnet" "private_subnet"

This is similar to public subnet but without:

map_public_ip_on_launch

Meaning:

Instances here do NOT get public IPs.

Used for:

databases

internal services

## 6️⃣ Internet Gateway
resource "aws_internet_gateway" "igw"

This enables:

VPC → Internet

Without IGW:

Instances cannot access the internet
## 7️⃣ Elastic IP
resource "aws_eip" "nat_eip"

Elastic IP = static public IP

Used by the NAT Gateway.

Reason:

Private instances need internet access but should not have public IPs.

## 8️⃣ NAT Gateway
resource "aws_nat_gateway" "nat"

Purpose:

Private subnet → Internet

But incoming internet traffic is blocked.

Flow:

Private EC2
   ↓
NAT Gateway
   ↓
Internet
Important line
subnet_id = aws_subnet.public_subnet[0].id

NAT Gateway must be inside a public subnet.

## 9️⃣ Route Tables

Route tables control network traffic routing.

Public Route Table
resource "aws_route_table" "public_rt"

Route rule:

0.0.0.0/0 → Internet Gateway

Meaning:

All internet traffic → IGW
Private Route Table
resource "aws_route_table" "private_rt"

Route rule:

0.0.0.0/0 → NAT Gateway

Meaning:

Private instances → NAT → Internet
## 🔟 Route Table Associations

Route tables must be attached to subnets.

Public:

resource "aws_route_table_association" "public_assoc"

Attach:

Public subnet → Public route table

Private:

resource "aws_route_table_association" "private_assoc"

Attach:

Private subnet → Private route table
## 1️⃣1️⃣ Outputs

Outputs show useful values after deployment.

Example:

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

After terraform apply you will see:

vpc_id = vpc-xxxxxx

Same for:

public subnet IDs
private subnet IDs
nat gateway ID
## 🔁 Full Architecture Created

Terraform builds this architecture:

                INTERNET
                    │
            Internet Gateway
                    │
           ---------------------
           |                   |
      Public Subnet A     Public Subnet B
           |                   |
        NAT Gateway
             │
       -----------------
       |               |
 Private Subnet A  Private Subnet B
       |               |
    Private EC2     Private EC2
---
