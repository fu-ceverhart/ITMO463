##############################################################################
# Create and RDS Mysql database - get dbname, username, and password using the
# ${var} function
# Create Output blocks for the db-name and db-address
# Note this isn't the most secure -- we will fix it in the next modules
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
##############################################################################
resource "aws_db_instance" "project_db" {
  allocated_storage    = 10
  db_name              = var.dbname
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.uname
  password             = var.pass
  skip_final_snapshot  = true

  tags = {
      Name = var.tag-name
  }
}

##############################################################################
# Create 2 S3 buckets - pull their names from the terraform.tfvars using the
# ${var} function
# Use output blocks to display the URL of the buckets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
##############################################################################
resource "aws_s3_bucket" "raw_bucket" {
  bucket = var.raw-bucket

  tags = {
    Name        = var.tag-name
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "finished_bucket" {
  bucket = var.finished-bucket

  tags = {
    Name        = var.tag-name
    Environment = "Dev"
  }
}

output "raw_url" {
  description = "Raw Bucket URL"
  value       = aws_s3_bucket.raw_bucket.bucket
}

##############################################################################
# Create an SNS Topic
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic
##############################################################################
resource "aws_sns_topic" "user_updates" {
  name = var.sns-topic

  tags = {
    Name        = var.tag-name
    Environment = "project"
  }
}


##############################################################################
# Create an SQS Message Queue and print out the URL in an output block
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue
##############################################################################
resource "aws_sqs_queue" "terraform_queue" {
  name = var.sqs


  tags = {
    Name        = var.tag-name
    Environment = "project"
  }
}

##############################################################################
# Create launch template
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/launch_template
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
##############################################################################
resource "aws_launch_template" "lt" {
   image_id = var.imageid
   instance_type = var.instance-type
   key_name = var.key-name
   vpc_security_group_ids = [var.vpc_security_group_ids]

     tags = {
       Name = var.tag-name
     }
    user_data = filebase64("./install-env.sh")
}
  
##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs
##############################################################################
data "aws_vpc" "main" {
  default = true
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
# Gather a list of all subnets per AZ per your region
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Print out to screen a list of subnets
output "list-of-subnets" {
  description = "List of subnets"
  value = data.aws_subnets.public.ids
}

# Get all AZs in a VPC
data "aws_availability_zones" "available" {
  state = "available"
}

# Print out a list of all AZs in your VPC per region
output "list-of-azs" {
  description = "List of AZs"
  value = data.aws_availability_zones.available.names
}

##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
##############################################################################
resource "aws_lb" "lb" {
  name               = var.elb-name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.vpc_security_group_ids]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = {
    Name = var.tag-name
    Environment = "project"
  }
}

# Print the ELB URL to the CLI screen
output "url" {
  value = aws_lb.lb.dns_name
}

##############################################################################
# Create autoscaling group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
##############################################################################
resource "aws_autoscaling_group" "asg" {
  name                      = var.asg-name
  max_size                  = var.max
  min_size                  = var.min
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = var.desired
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.alb-lb-tg.arn]
  availability_zones        = var.az

  launch_template {
    id = aws_launch_template.lt.id
  }  
  
}

##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment
##############################################################################
# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg-attach" {
  # Wait for lb to be running before attaching the ASG
  depends_on = [ aws_lb.lb ]
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn = aws_lb_target_group.alb-lb-tg.arn

}
##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
##############################################################################
resource "aws_lb_target_group" "alb-lb-tg" {
  # Depends on - wait for LB to exist
  depends_on = [ aws_lb.lb ]
  name = var.tg-name
  target_type = "instance"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.main.id
}
##############################################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
##############################################################################
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb-lb-tg.arn
  }
}
