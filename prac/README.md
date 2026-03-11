# Terraform EC2 Apache Setup using Provisioners

This project demonstrates how to use **Terraform** to create an **EC2 instance** on **AWS** and automatically install **Apache Web Server** using Terraform provisioners.

---

## Architecture

Terraform performs the following steps:

1. Create an EC2 instance.
2. Run a local command on the machine executing Terraform.
3. Copy a shell script to the EC2 instance.
4. Execute the script remotely to install Apache.
5. Deploy a test web page.

---

## Project Structure

```
terraform-apache-setup/
│
├── main.tf
├── apache2.sh
└── README.md
```

---

# Terraform Configuration

File: `main.tf`

```hcl
# Define AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create EC2 Instance
resource "aws_instance" "my_ec2" {
  ami           = "ami-0ecb62995f68bb549"
  instance_type = "t3.micro"
  key_name      = "demo"

  # Local command executed on Terraform machine
  provisioner "local-exec" {
    command = "touch abc.txt"
  }

  # Copy script to EC2
  provisioner "file" {
    source      = "apache2.sh"
    destination = "/home/ubuntu/apache2.sh"
  }

  # Connection configuration
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("demo")
    host        = self.public_ip
  }

  # Execute script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/apache2.sh",
      "sudo bash /home/ubuntu/apache2.sh",
      "touch remote.txt"
    ]
  }

  tags = {
    Name = "MyFirstEC2"
  }
}
```

---

# Apache Installation Script

File: `apache2.sh`

```bash
#!/bin/bash

# Update package list
sudo apt update -y

# Install Apache
sudo apt install -y apache2

# Start Apache service
sudo systemctl start apache2

# Enable Apache on boot
sudo systemctl enable apache2

# Create a simple web page
echo "<h1>Apache installed successfully using Terraform remote-exec</h1>" | sudo tee /var/www/html/index.html

# Check Apache status
sudo systemctl status apache2
```

---

# Make Script Executable

Before running Terraform, ensure the script has execution permissions:

```bash
chmod +x apache2.sh
```

---

# Terraform Execution Steps

Initialize Terraform:

```bash
terraform init
```

Check execution plan:

```bash
terraform plan
```

Create infrastructure:

```bash
terraform apply
```

Confirm by typing:

```
yes
```

---

# Provisioning Flow

1. Terraform creates an EC2 instance.
2. `local-exec` runs on the local machine.

```
touch abc.txt
```

3. The `file` provisioner copies the script.

```
apache2.sh → /home/ubuntu/apache2.sh
```

4. The `remote-exec` provisioner runs commands on the EC2 instance.

```
bash /home/ubuntu/apache2.sh
```

5. Apache Web Server gets installed.

---

# Verify Installation

After Terraform completes, open your browser:

```
http://<EC2-PUBLIC-IP>
```

You should see the message:

```
Apache installed successfully using Terraform remote-exec
```

---

# Destroy Infrastructure

To delete all created resources:

```bash
terraform destroy
```

---

# Notes

* Ensure your **SSH key pair** matches the `key_name` used in Terraform.
* Security groups must allow **port 22 (SSH)** and **port 80 (HTTP)**.
* Provisioners are mainly used for demonstration purposes. In production environments, configuration management tools or `user_data` scripts are preferred.

---


also give the key 