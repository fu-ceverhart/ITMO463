# Generate random password -- this way its never hardcoded into our variables and inserted directly as a secretcheck 
# No one will know what it is!
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_random_password
data "aws_secretsmanager_random_password" "coursera_project" {
  password_length = 30
  exclude_numbers = true
  exclude_punctuation = true
}

# Create the actual secret (not adding a value yet)
# Provides a resource to manage AWS Secrets Manager secret metadata. To manage
# secret rotation, see the aws_secretsmanager_secret_rotation resource. To 
# manage a secret value, see the aws_secretsmanager_secret_version resource.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret
resource "aws_secretsmanager_secret" "coursera_project_username" {
  name = "uname"
  # https://github.com/hashicorp/terraform-provider-aws/issues/4467
  # This will automatically delete the secret upon Terraform destroy 
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "coursera_project_password" {
  name = "pword"
  # https://github.com/hashicorp/terraform-provider-aws/issues/4467
  # This will automatically delete the secret upon Terraform destroy 
  recovery_window_in_days = 0
}

# Provides a resource to manage AWS Secrets Manager secret version including its secret value.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version
# Used to set the value
resource "aws_secretsmanager_secret_version" "coursera_project_username" {
  #depends_on = [ aws_secretsmanager_secret_version.project_username ]
  secret_id     = aws_secretsmanager_secret.coursera_project_username.id
  secret_string = var.username
}

resource "aws_secretsmanager_secret_version" "coursera_project_password" {
  #depends_on = [ aws_secretsmanager_secret_version.project_password ]
  secret_id     = aws_secretsmanager_secret.coursera_project_password.id
  secret_string = data.aws_secretsmanager_random_password.coursera_project.random_password
}

# Retrieve secrets value set in secret manager
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version
# https://github.com/hashicorp/terraform-provider-aws/issues/14322
data "aws_secretsmanager_secret_version" "project_username" {
  depends_on = [ aws_secretsmanager_secret_version.coursera_project_username ]
  secret_id = aws_secretsmanager_secret.coursera_project_username.id
}

data "aws_secretsmanager_secret_version" "project_password" {
  depends_on = [ aws_secretsmanager_secret_version.coursera_project_password ]
  secret_id = aws_secretsmanager_secret.coursera_project_password.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
resource "aws_db_instance" "default" {
  depends_on = [ aws_secretsmanager_secret_version.coursera_project_password, aws_secretsmanager_secret_version.coursera_project_username ]
  allocated_storage    = 10
  db_name              = var.dbname
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  # Retrieve secrets value set in secret manager
  username             = data.aws_secretsmanager_secret_version.project_username.secret_string
  password             = data.aws_secretsmanager_secret_version.project_password.secret_string
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.module_04_rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.module_04_rds_subnet_group.name
  publicly_accessible    = false
  
  tags = {
    Name = var.tag-name
  }
} 

output "db-address" {
  description = "Endpoint URL "
  value = aws_db_instance.default.address
}

output "db-name" {
  description = "DB Name "
  value = aws_db_instance.default.db_name
}

resource "aws_security_group" "module_04_sg" {
  name        = "module_04_sg"
  description = "Allow HTTP and SSH"
  vpc_id = aws_vpc.module_04_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.tag-name
  }
}

resource "aws_security_group" "module_04_rds_sg" {
  name        = "module_04_rds_sg"
  description = "Allow MySQL from EC2 only"
  vpc_id = aws_vpc.module_04_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.module_04_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.tag-name
  }
}

resource "aws_vpc" "module_04_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.tag-name
  }
}

resource "aws_internet_gateway" "module_04_igw" {
  vpc_id = aws_vpc.module_04_vpc.id

  tags = {
    Name = var.tag-name
  }
}

resource "aws_subnet" "module_04_public" {
  vpc_id                  = aws_vpc.module_04_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.az[0]
  map_public_ip_on_launch = true

  tags = {
    Name = var.tag-name
  }
}

resource "aws_subnet" "module_04_public_2" {
  vpc_id                  = aws_vpc.module_04_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = var.az[1]
  map_public_ip_on_launch = true

  tags = {
    Name = var.tag-name
  }
}

resource "aws_subnet" "module_04_public_3" {
  vpc_id                  = aws_vpc.module_04_vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = var.az[2]
  map_public_ip_on_launch = true

  tags = {
    Name = var.tag-name
  }
}

resource "aws_subnet" "module_04_private_1" {
  vpc_id            = aws_vpc.module_04_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.az[1]

  tags = {
    Name = var.tag-name
  }
}

resource "aws_subnet" "module_04_private_2" {
  vpc_id            = aws_vpc.module_04_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.az[2]

  tags = {
    Name = var.tag-name
  }
}

resource "aws_route_table" "module_04_public_rt" {
  vpc_id = aws_vpc.module_04_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.module_04_igw.id
  }

  tags = {
    Name = var.tag-name
  }
}

resource "aws_route_table_association" "module_04_public_rta" {
  subnet_id      = aws_subnet.module_04_public.id
  route_table_id = aws_route_table.module_04_public_rt.id
}

resource "aws_route_table_association" "module_04_public_2_rta" {
  subnet_id      = aws_subnet.module_04_public_2.id
  route_table_id = aws_route_table.module_04_public_rt.id
}

resource "aws_route_table_association" "module_04_public_3_rta" {
  subnet_id      = aws_subnet.module_04_public_3.id
  route_table_id = aws_route_table.module_04_public_rt.id
}

resource "aws_db_subnet_group" "module_04_rds_subnet_group" {
  name       = "module_04_rds_subnet_group"
  subnet_ids = [aws_subnet.module_04_private_1.id, aws_subnet.module_04_private_2.id]

  tags = {
    Name = var.tag-name
  }
}

resource "aws_lb" "lb" {
  depends_on = [ aws_internet_gateway.module_04_igw]
  name               = var.elb-name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.module_04_sg.id]
  subnets            = [aws_subnet.module_04_public.id, aws_subnet.module_04_public_2.id, aws_subnet.module_04_public_3.id]

  enable_deletion_protection = false

  tags = {
    Name = var.tag-name
  }
}

# output will print a value out to the screen
output "url" {
  value = aws_lb.lb.dns_name
}

resource "aws_lb_target_group" "alb-lb-tg" {
  # depends_on is effectively a waiter -- it forces this resource to wait until the listed
  # resource is ready
  depends_on  = [aws_lb.lb]
  name        = var.tg-name
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.module_04_vpc.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-lb-tg.arn
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = var.asg-name
  depends_on                = [aws_launch_template.lt]
  desired_capacity          = var.desired
  max_size                  = var.max
  min_size                  = var.min
  health_check_grace_period = 300
  health_check_type         = "EC2"
  target_group_arns         = [aws_lb_target_group.alb-lb-tg.arn]
 vpc_zone_identifier = [aws_subnet.module_04_public.id, aws_subnet.module_04_public_2.id, aws_subnet.module_04_public_3.id]

  tag {
    key                 = "Name"
    value               = var.tag-name
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
}

resource "aws_s3_bucket" "raw" {
  bucket = var.raw-s3-bucket

  tags = {
    Name = var.tag-name
  }
}

resource "aws_s3_bucket" "finished" {
  bucket = var.finished-s3-bucket

  tags = {
    Name = var.tag-name
  }
}

resource "aws_sns_topic" "updates" {
  name = var.user-sns-topic
  
  tags = {
    Name = var.tag-name
  }
}

resource "aws_launch_template" "lt" {
  image_id                             = var.imageid
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance-type
  key_name                             = var.key-name
  vpc_security_group_ids               = [aws_security_group.module_04_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.coursera_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.tag-name
    }
  }
  user_data = filebase64("./install-env.sh")
}