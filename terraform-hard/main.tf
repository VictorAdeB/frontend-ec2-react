
############################
# KEY PAIR GENERATION
############################

resource "tls_private_key" "react_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "react-ec2-key"
  public_key = tls_private_key.react_key.public_key_openssh

  tags = {
    Name = "react-terraform-key"
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.react_key.private_key_pem
  filename        = "${path.module}/react-ec2-key.pem"
  file_permission = "0600"
}

############################
# NETWORKING
############################

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

############################
# SECURITY GROUP
############################

resource "aws_security_group" "web_sg" { 
  name   = "react-web-sg"
  vpc_id = aws_vpc.main.id

  # HTTP / Apache
  ingress {
    description = "Apache"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom SSH on port 2222
  ingress {
    description = "SSH from my IP"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # e.g., "203.0.113.25/32"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# IAM ROLE FOR SSM
############################

resource "aws_iam_role" "ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

############################
# EC2 INSTANCE
############################

resource "aws_instance" "react_server" {
  ami                         = "ami-0eb260c4d5475b901"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = aws_key_pair.generated_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true

  tags = {
    Name = "React-Hardened-Server"
  }
}

# Elastic IP for EC2
resource "aws_eip" "react_eip" {
  instance = aws_instance.react_server.id
   domain   = "vpc" 
  depends_on = [aws_instance.react_server]
}

############################
# CLOUDFRONT DISTRIBUTION
############################

resource "aws_cloudfront_distribution" "react_cdn" {
  enabled = true
  comment = "React App CDN"

  # Use your Elastic IP public DNS as the origin
  origin {
    domain_name = aws_eip.react_eip.public_dns
    origin_id   = "reactEC2"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "reactEC2"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    compress = true
  }

  # Handle React Router: return index.html for 404s
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  # SSL
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Global access
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Depends on EIP to be ready first
  depends_on = [aws_eip.react_eip]
}