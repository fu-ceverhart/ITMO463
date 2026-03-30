# Add values
# Find the Ubuntu server 22.04 AMI for your region at this URL
# https://cloud-images.ubuntu.com/locator/ec2/
# Use t2.micro for the AWS Free Tier
imageid                = "ami-00de3875b03809ec5"
instance-type          = "t3.micro"
key-name               = "module-02-key"
vpc_security_group_ids = "sg-082c13fdf90e8bf34"
tag-name               = "module-02"
raw-bucket             = "raw-module-02"
finished-bucket        = "finished-module-02"
sns-topic              = "sns-module-02"
sqs                    = "sqs-module-02"
dbname                 = "dbmodule02"
uname                  = "module02user"
# pass                   = "" this is pulled from a secrets file so it has been commented out.
elb-name               = "elb-module-02"
asg-name               = "asg-module-02"
min                    = 2
max                    = 5
desired                = 3
tg-name                = "tg-module-02"
cnt                    = 1