# Add values
# Use the AMI of the custom Ec2 image you previously created
imageid                = "ami-021769d848635b6f4"
# Use t2.micro for the AWS Free Tier
instance-type          = "t3.micro"
key-name               = "module-04"
# vpc_security_group_ids = "sg-0fafd233da91b97bd"
tag-name               = "module-04"
user-sns-topic         = "cde-updates"
elb-name               = "cde-elb"
tg-name                = "cde-tg"
asg-name               = "cde-asg"
desired                = 3
min                    = 2
max                    = 5
number-of-azs          = 3
region                 = "us-east-1"
raw-s3-bucket          = "cde-raw-bucket"
finished-s3-bucket     = "cde-finished-bucket"
dbname                 = "company"
username               = "controller"
