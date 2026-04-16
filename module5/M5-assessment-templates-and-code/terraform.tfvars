# Add values
# Use the AMI of the custom Ec2 image you previously created
imageid                = ""
# Use t2.micro for the AWS Free Tier
instance-type          = "t2.micro"
key-name               = ""
vpc_security_group_ids = ""
tag-name               = ""
user-sns-topic         = ""
elb-name               = ""
tg-name                = ""
asg-name               = ""
desired                = 3
min                    = 2
max                    = 5
number-of-azs          = 3
region                 = ""
raw-s3-bucket          = ""
finished-s3-bucket     = ""
dbname                 = ""
snapshot_identifier    = ""
sqs-name               = ""
username               = ""
