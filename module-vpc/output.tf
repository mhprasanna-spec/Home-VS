output "vpc_id" {
  
  value = module.vpc_network.vpc_id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}