variable "vpc_cidr" {
  
}

variable "public_subnet_cidrs" {
    type = list(string)
  
}

variable "private_subnet_cidrs" {
    type = list(string)
  
}

varible "availability_zones" {
    type = list(string)
  
}