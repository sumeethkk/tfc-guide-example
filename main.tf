resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  #refrencing vpc id
}

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Prod RT"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    name = "Prod Subnet"
  }
}

resource "aws_route_table_association" "connection-RT-subnet" {
  subnet_id = aws_subnet.subnet.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_security_group" "sg" {
  name = "security_group"
  description = "Allow Web inbound traffic"
  vpc_id = aws_vpc.vpc.id
  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags = {
    Name = " security_group"
  }
}

resource "aws_network_interface" "server-nic" {
  subnet_id = aws_subnet.subnet.id
  private_ips = [
    "10.0.1.50"]
  security_groups = [
    aws_security_group.sg.id]
}

resource "aws_eip" "one" {
  vpc = true
  network_interface = aws_network_interface.server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.igw]
}

resource "aws_key_pair" "ec2-ke" {
  key_name   = "ec2-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCq/RPzjeykbSQ8e35cLtjnaKIPw43LHImgFdv9ezO8csdVkv7kLqTYM99zhUchQdHIvzXpS6xzDwToJ0gj1nIkz4TiUnrrGCgA728GyWKsKR21HaLbZVJLcEmbSaNRCpMgtT0WgEMIXd5c1PVBF5F5tBklSQhIn4b+Iw7CuPXlCzjx0djGHgMGwoAvMpmSsAKZS6Ra3LptGtFvaB0oGuIegyDI7qNU6z6jXZRRCcNCEKV9JsgQzDNt/TtTtthom3rYziSIlU1yK7i+xDTGC/uK+4IY6EpTYLCKN61w+xn0N3SlqgZjLgHRGMuoV2OGQ5nEVgwAAko+oU3BfQWv/sLqb0NZdEmGVBo6ibGTUFn2y7HJPXzw6bgH8RUzUGGWiz3scAOeyGFcCrT4gSgnhpDGB1RTIcLf0aXuhyXddGqM4NoTq2GVjGrk7G5gBIpRNwTd1HuIQWSBipiZVcuCDafpQC4hmvBRf/IPTuE9XtHaj5mUy3DqGpQVkU9MY1vbrUk= sumee@LAPTOP-LP5RLUPM"
}

output "app_keypair" {
  description = "The ARN of the key"
  value       = aws_key_pair.ec2-ke.key_name
}

resource "aws_instance" "server-instance" {
  ami = "ami-0663b059c6536cac8"
  instance_type = "t2.micro"
  availability_zone = "us-west-2a"
  key_name = "ec2-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.server-nic.id
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c echo my very first web server > /var/www/html/index.html'
                EOF

  tags = {
    Name = "my-web-server"
  }
}
