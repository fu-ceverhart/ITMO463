# Add values
# Find the Ubuntu server 22.04 AMI for your region at this URL
# https://cloud-images.ubuntu.com/locator/ec2/
imageid                = "ami-00de3875b03809ec5"
# Use t2.micro for the AWS Free Tier
instance-type          = "t3.micro"
key-name               = "module-03-key"
vpc_security_group_ids = "sg-0f152b921474af6ab"
tag-name               = "module-03" 
user-sns-topic         = "sns-module-03"
elb-name               = "elb-module-03"
tg-name                = "tg-module-03"
asg-name               = "asg-module-03"
desired                = 3
min                    = 2
max                    = 5
number-of-azs          = 2
region                 = "us-east-1"
raw-s3                 = "raw-module-03"
finished-s3            = "finished-module-03"