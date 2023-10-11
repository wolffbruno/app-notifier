data "client" "current" {
  cidr = "0.0.0.0/0"
}

resource "aws_vpc" "rds_vpc" {
  cidr_block           = "172.32.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "rds_vpc"
  }
}

resource "aws_subnet" "rds_subnet_1" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "172.32.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "rds_subnet_1"
  }
}

resource "aws_subnet" "rds_subnet_2" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "172.32.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "rds_subnet_2"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow inbound traffic"

  ingress {
    from_port   = -1
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = [data.client.current.cidr]
  }
}

resource "aws_security_group_rule" "rds_sg_rule" {
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "-1"
  source_security_group_id = aws_security_group.rds_sg.id
  security_group_id        = aws_security_group.rds_sg.id
}

resource "aws_ec2_client_vpn_endpoint" "rds_vpn_endpoint" {
  description            = "rds_vpn_endpoint"
  server_certificate_arn = "arn:aws:acm:us-east-1:798922568248:certificate/478b6cac-bd76-4085-8e5f-d86127c496bf"
  vpc_id                 = aws_vpc.rds_vpc.id
  security_group_ids = [
    aws_security_group.rds_sg.id,
  ]
  client_cidr_block = data.client.current.cidr

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = "arn:aws:acm:us-east-1:798922568248:certificate/37ff8377-5dd9-4c5d-9f31-e8244823ce2c"
  }
  connection_log_options {
    enabled = false
    // cloudwatch_log_group  = "rds_vpn_endpoint"
    // cloudwatch_log_stream = "rds_vpn_endpoint"
  }
}

resource "aws_ec2_client_vpn_network_association" "rds_vpn_subnet_1" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.rds_vpn_endpoint.id
  subnet_id              = aws_subnet.rds_subnet_1.id
}

resource "aws_ec2_client_vpn_network_association" "rds_vpn_subnet_2" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.rds_vpn_endpoint.id
  subnet_id              = aws_subnet.rds_subnet_2.id
}

resource "aws_ec2_client_vpn_authorization_rule" "rds_vpn_auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.rds_vpn_endpoint.id
  target_network_cidr    = data.client.current.cidr
  authorize_all_groups   = true
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.rds_subnet_1.id, aws_subnet.rds_subnet_2.id]
}

resource "aws_db_instance" "rds_instance" {
  identifier             = "rds_instance"
  db_name                = "rds_instance"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "11.5"
  instance_class         = "db.t2.micro"
  username               = "postgres"
  password               = "postgres"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}
