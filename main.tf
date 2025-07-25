# Terraform config to launch a t3.large EC2 instance with Redis installed via user_data

provider "aws" {
  region = "eu-west-2"
}

resource "aws_key_pair" "redis_key" {
  key_name   = "redis-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Allow SSH and Redis"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change for more secure access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "redis_ec2" {
  ami                         = "ami-094d7454c76205ed8" # ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250516
  instance_type               = "t3.large"
  key_name                    = aws_key_pair.redis_key.key_name
  vpc_security_group_ids      = [aws_security_group.redis_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y redis-server
              systemctl enable redis-server
              systemctl stop redis-server
              sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
              sed -i 's/^protected-mode .*/protected-mode no/' /etc/redis/redis.conf
              sed -i 's/^# requirepass .*/requirepass PASSWORD/' /etc/redis/redis.conf
              wget https://s3.eu-west-2.amazonaws.com/tsoru.aksw.org/surface-forms/wikipedia/en/2024-01-18/surface-forms.rdb -O /var/lib/redis/dump.rdb
              chown redis:redis /var/lib/redis/dump.rdb
              systemctl start redis-server
              EOF

  tags = {
    Name = "redis-server"
  }
}

output "public_ip" {
  value = aws_instance.redis_ec2.public_ip
}