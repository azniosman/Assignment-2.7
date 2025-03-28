data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Azni_VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Azni_Public_Subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Azni_IGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Azni_Public_Route_Table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_instance" "my_ec2" {
  ami               = data.aws_ami.amazon_linux_2.id
  instance_type     = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[0]
  subnet_id         = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_egress.id]

  tags = {
    Name = "Azni_EC2_Instance"
  }
}

resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = aws_instance.my_ec2.availability_zone
  size              = 1
  type              = "gp2"

  tags = {
    Name = "Azni_Extra_Volume"
  }
}

resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/sdh" # Or another available device name
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.my_ec2.id
}

resource "aws_security_group" "allow_egress" {
  name        = "allow_egress"
  description = "Allow outbound traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Azni_Security_Group"
  }
}

output "ebs_volume_id" {
  value = aws_ebs_volume.ebs_volume.id
}
