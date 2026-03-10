resource "aws_launch_template" "lt" {
  name_prefix   = "my-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.instance_sg_id]

  user_data = base64encode(<<EOF
#!/bin/bash
apt update -y
apt install nginx -y
echo "Hello from $HOSTNAME Auto Scaling!" > /var/www/html/index.html
systemctl start nginx
systemctl enable nginx
EOF
)
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = var.subnets
  target_group_arns   = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
}