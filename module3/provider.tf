##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
##############################################################################
# Create a VPC
# With a CIDR block of 172.32.0.0/16
# Enable_dns_hostnames
resource "aws_vpc" "project" {

}

# Query the VPC information
data "aws_vpc" "project" {
  id = aws_vpc.project.id
}

# Get all AZs in a VPC
data "aws_availability_zones" "available" {
  state = "available"
}

# Print out a list of Availability Zones
output "list-of-azs" {
  description = "List of AZs"
  value       = data.aws_availability_zones.available.names
}

# Create security group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# Don't forget the egress rules!!!
# 
resource "aws_security_group" "allow_http" {

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = 
  cidr_ipv4         = 
  from_port         = 
  ip_protocol       = 
  to_port           = 
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = 
  cidr_ipv4         = 
  from_port         = 
  ip_protocol       = 
  to_port           = 
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Create VPC DHCP options -- public DNS provided by Amazon
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options
resource "aws_vpc_dhcp_options" "project" {
  domain_name = "${var.region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
  
  tags = {
    Name = var.tag-name
  }
}

# Associate these options with our VPC now
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = 
  dhcp_options_id = 
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = 

  tags = {
    Name = var.tag-name
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "example" {
  depends_on = [ aws_vpc.project ]
  vpc_id = 

  route {
    cidr_block = 
    gateway_id = 
  }

  tags = {
    Name = var.tag-name
  }
}

# Now we need to associate the route_table to subnets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "subnets" {
  # This method is a little hard-coded hack - we use the count feature
  # which acts as a for loop attaching a route table to multiple subnets at once
  # We could do this verbose but this saves us extra coding and will work in any Region
  count = var.number-of-azs
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.example.id
}

# Now make the new route the main associated route
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/main_route_table_association
resource "aws_main_route_table_association" "a" {
  vpc_id         = 
  route_table_id = 
}

# IAM instance policy
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "coursera_profile" {
  # Give it a name
  name = 
  role = 
}

# Creating the policy (rules) for what the role can do
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Creating the role
resource "aws_iam_role" "role" {
  name               = "project_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy
resource "aws_iam_role_policy" "s3_fullaccess_policy" {
  name = "s3_fullaccess_policy"
  role = aws_iam_role.role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# creating a private IPv4 subnet per AZ
# https://stackoverflow.com/questions/63991120/automatically-create-a-subnet-for-each-aws-availability-zone-in-terraform
# https://stackoverflow.com/questions/26706683/ec2-t2-micro-instance-has-no-public-dns
resource "aws_subnet" "private" {
  depends_on = [ aws_vpc.project ]
  count = var.number-of-azs
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id   = data.aws_vpc.project.id
  map_public_ip_on_launch = true
  # https://developer.hashicorp.com/terraform/language/functions/cidrsubnets
  # The 8 represents /24
  cidr_block = cidrsubnet(data.aws_vpc.project.cidr_block, 4, count.index + 3)

  tags = {
    Name = var.tag-name
    Type = "private"
    Zone = data.aws_availability_zones.available.names[count.index]
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    # set of strings required
    values = [data.aws_vpc.project.id]
  }
}

output "aws_subnets" {
    value = [data.aws_vpc.project.id]
}

##############################################################################
# Create launch template
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/launch_template
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
##############################################################################
resource "aws_launch_template" "lt" {
  image_id                             = 
  instance_initiated_shutdown_behavior = 
  instance_type                        = 
  key_name                             = 
  vpc_security_group_ids               = 
  iam_instance_profile {
    name = 
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.tag-name
    }
  }
  user_data = filebase64("./install-env.sh")
}

##############################################################################
# Create autoscaling group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
##############################################################################

resource "aws_autoscaling_group" "asg" {
  name                      = 
  depends_on                = [aws_launch_template.lt]
  desired_capacity          = 
  max_size                  = 
  min_size                  = 
  health_check_grace_period = 300
  health_check_type         = "EC2"
  target_group_arns         = 
  # place in all AZs
  # Use this if you only have the default subnet per AZ
  # availability_zones        =  data.aws_availability_zones.available.names
  # Use this is you have multiple subnets per AZ
  vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]

  tag {
    key                 = "Name"
    value               = var.tag-name
    propagate_at_launch = true
  }

  launch_template {
    id      = 
    version = "$Latest"
  }
}

##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
##############################################################################
resource "aws_lb" "lb" {
  depends_on = [ aws_subnet.private ]
  name               = 
  internal           = false
  load_balancer_type = "application"
  security_groups = 
  # Place across all subnets
  subnets = [for subnet in aws_subnet.private : subnet.id]

  enable_deletion_protection = false

  tags = {
    Name = var.tag-name
  }
}

# output will print a value out to the screen
output "url" {
  value = aws_lb.lb.dns_name
}

##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment
##############################################################################
# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "example" {
  # Wait for lb to be running before attaching to asg
  depends_on  = [aws_lb.lb]
  autoscaling_group_name = 
  lb_target_group_arn    = 
}

output "alb-lb-tg-arn" {
  value = aws_lb_target_group.alb-lb-tg.arn
}

output "alb-lb-tg-id" {
  value = aws_lb_target_group.alb-lb-tg.id
}

##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
##############################################################################

resource "aws_lb_target_group" "alb-lb-tg" {
  # depends_on is effectively a waiter -- it forces this resource to wait until the listed
  # resource is ready
  depends_on  = [aws_lb.lb]
  name        = var.tg-name
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.project.id
}

##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
##############################################################################

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-lb-tg.arn
  }
}

##############################################################################
# Create S3 buckets with policies that allow GetObject
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
# https://stackoverflow.com/questions/65984400/how-to-delete-non-empty-s3-bucket-with-terraform
##############################################################################

resource "aws_s3_bucket" "raw-bucket" {
  # Create bucket name and use force_destroy
}

resource "aws_s3_bucket" "finished-bucket" {
  # Create bucket name and use force_destroy
}

resource "aws_s3_bucket_public_access_block" "allow_access_from_another_account-raw" {
  bucket = 
  depends_on=[data.aws_iam_policy_document.allow_access_from_another_account-raw]

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_public_access_block" "allow_access_from_another_account-finished" {
  bucket = 
  depends_on=[data.aws_iam_policy_document.allow_access_from_another_account-finished]
  

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account-raw" {
  depends_on  = []
  bucket = 
  policy = data.aws_iam_policy_document.allow_access_from_another_account-raw.json
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account-finished" {
  depends_on  = [aws_s3_bucket_public_access_block.allow_access_from_another_account-finished]
  bucket = aws_s3_bucket.finished-bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account-finished.json
}

data "aws_iam_policy_document" "allow_access_from_another_account-raw" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.raw-bucket.arn,
      "${aws_s3_bucket.raw-bucket.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_access_from_another_account-finished" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.finished-bucket.arn,
      "${aws_s3_bucket.finished-bucket.arn}/*",
    ]
  }
}