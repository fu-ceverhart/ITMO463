# Add values
# Use the AMI of the custom Ec2 image you previously created
imageid                = "ami-0597054c32c573a80"
# Use t2.micro for the AWS Free Tier
instance-type          = "t2.micro"
key-name               = "module-05"
vpc_security_group_ids = ""
tag-name               = "module-05"
user-sns-topic         = "cde-updates"
elb-name               = "module-05-elb"
tg-name                = "module-05-tg"
asg-name               = "module-05-asg"
desired                = 3
min                    = 2
max                    = 5
number-of-azs          = 3
region                 = "us-east-1"
raw-s3-bucket          = "fu-ceverhart-raw-m5"
finished-s3-bucket     = "fu-ceverhart-finished-m5"
dbname                 = "company"
snapshot_identifier    = "coursera-snapshot"
sqs-name               = "cde-queue"
username               = "controller"
