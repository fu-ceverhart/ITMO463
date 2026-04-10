# Module 04 Autograder
import boto3
import json
import requests
import hashlib
import sys
import datetime
import os.path
import time
from tqdm import tqdm

# Assignment grand total
grandtotal = 0
totalPoints = 10
assessmentName = "module-04-assessment"
snapshotname                     = "coursera-snapshot"
correctNumberOfDBAcrossSubnets   = 3
correctNumOfDBSubnetGroups       = 1
correctNumberOfSecrets           = 2
correctNumberOfRolePolicies      = 4
correctNumberOfLts               = 1
correctNumberOfSnsTopics         = 1
correctNumberOfTargetGroups      = 1
correctNumberOfAutoScalingGroups = 1
correctNumberOfELBs              = 1
correctNumberOfEBS               = 3
correctNumberOfRDSSnapshots      = 1
correctNumberOfRDSInstances      = 1
correctNumberOfVpcs              = 2
correctNumberOfS3Buckets         = 2
correctNumberOfSGs               = 1
correctNumberOfInternetGateways  = 1
correctNumberOfRouteTables       = 1
correctNumberOfDHCPOptions       = 1
tag = "module-04"

# Function to print out current points progress
def currentPoints():
  print("Current Points: " + str(grandtotal) + " out of " + str(totalPoints) + ".")

# Documentation Links
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2.html
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/elbv2.html
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/autoscaling.html
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rds.html

##############################################################################
# 10 tasks to cover
##############################################################################
# Create 4 AWS IAM Role Policies: S3, RDS, SM, SNS
# Check instance profile to Launch Template
# Check Raw bucket contains Knuth.jpg and vegeta.jpg
# Create SNS topic and tag
# Create RDS instance check for RDS snapshot called coursera-snapshot
# Create aws secret for uname and pword
# Create db_subnet_group called coursera-project
# Check SNS for subscription existence
# Create VPC security group ingress rule for ssh http and 3306 MySQL
# Check custom AMI exists with tag of: Name module-04

clientec2 = boto3.client('ec2')
clientelbv2 = boto3.client('elbv2')
clientasg = boto3.client('autoscaling')
clients3 = boto3.client('s3')
clientrds = boto3.client('rds')
clientiam = boto3.client('iam')
clientsns = boto3.client('sns')
clientsm = boto3.client('secretsmanager')

# EC2 describe images
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_images.html
responseEC2AMI=clientec2.describe_images(    
  Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                tag,
            ]
        },
    ],
)

# Describe security groups
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_security_groups.html
responsesg = clientec2.describe_security_groups(
    Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                tag,
            ]
        },
    ],
)
# List Secrets
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager.html
responsesm = clientsm.list_secrets( Filters=[ { 'Key': 'tag-value','Values': [tag] }] )

# Describe DB Snapshots
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rds/client/describe_db_snapshots.html

responserdssnapshot = clientrds.describe_db_snapshots()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sns/client/list_topics.html

responsesns = clientsns.list_topics()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/iam/client/list_role_policies.html

responseiam = clientiam.list_role_policies(
     RoleName='project_role' 
)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_vpcs.html

responseVPC = clientec2.describe_vpcs()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_subnets.html

responseSubnets = clientec2.describe_subnets(
    Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                tag,
            ]
        },
    ],
)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_route_tables.html

responseRouteTables = clientec2.describe_route_tables(
    Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
            tag,
            ]
        },
    ],
)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_dhcp_options.html

responseDHCP = clientec2.describe_dhcp_options(
    Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
            tag,
            ]
        },
    ],
)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_security_groups.html
responseSG = clientec2.describe_security_groups(
    Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                tag,
            ]
        },
    ],
)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_internet_gateways.html
responseIG = clientec2.describe_internet_gateways(
  Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                tag,
            ]
        },
    ],
)
# hello from will
# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_subnets.html
responseSubnets = clientec2.describe_subnets(
  Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                tag,
            ]
        },
    ],
)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_route_tables.html
responseRT = clientec2.describe_route_tables(
  Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                tag,
            ]
        },
    ],
)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_dhcp_options.html
responseDhcpOptions = clientec2.describe_dhcp_options(
  Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                tag,
            ]
        },
    ],
)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_instances.html
responseEC2 = clientec2.describe_instances(
 Filters=[
     {
         'Name': 'instance-state-name',
         'Values':['running']
     }
],
) # End of function

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3/client/list_buckets.html
# Get a Dict of all bucket names
responseS3 = clients3.list_buckets()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/elbv2/client/describe_load_balancers.html
responseELB = clientelbv2.describe_load_balancers()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/elbv2/client/describe_target_groups.html
responseTG = clientelbv2.describe_target_groups()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/autoscaling/client/describe_auto_scaling_groups.html
responseasg = clientasg.describe_auto_scaling_groups()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/autoscaling/client/describe_auto_scaling_instances.html
responseasgi = clientasg.describe_auto_scaling_instances()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/autoscaling/client/describe_auto_scaling_groups.html
responseasg = clientasg.describe_auto_scaling_groups()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_launch_templates.html
responselt = clientec2.describe_launch_templates()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rds/client/describe_db_instances.html
responselistinstances = clientrds.describe_db_instances()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rds/client/describe_db_subnet_groups.html
responsedbsubnet = clientrds.describe_db_subnet_groups()

##############################################################################
print('*' * 79)
print("Begin tests for " + tag + " Assessment...")
##############################################################################

##############################################################################
# Testing Correct number of IAM Policy Roles, 4 are expected
##############################################################################
print('*' * 79)
print("Testing Correct number of IAM Policy Roles, 4 are expected...")

if len(responseiam['PolicyNames']) == correctNumberOfRolePolicies:
  print("Well done! You have the correct number IAM Role Policies: " + str(correctNumberOfRolePolicies) + "...")
  for n in range(0,len(responseiam['PolicyNames'])):
    print("Created and found IAM Role Policy: " + responseiam['PolicyNames'][n] + "...")
  
  grandtotal += 1
  currentPoints()
else:
  print("You have an incorrect number of VPCs, you have: " + str(len(responseiam['PolicyNames'])) + "...")
  print("Perhaps double check that you issued the terraform destroy command from a previous lab...")
  print("Or you may have overlooked adding the IAM Role Policies in the main.tf terraform file...")
  currentPoints()

print('*' * 79)
print("\r")
##############################################################################
# Testing checking for existence of an Instance Profile attached to EC2 
# instances
##############################################################################
print('*' * 79)
print("Testing to see if an IAM Instance profile is attached to each EC2 instance...")
profile_count = 0

print("These are the ARNs of your attached IAM Instance Profiles...")
for n in range(0,len(responseEC2['Reservations'])):
  print(responseEC2['Reservations'][n]['Instances'][0]['IamInstanceProfile']['Arn'] + " for instanceID: " + str(responseEC2['Reservations'][n]['Instances'][0]['InstanceId']))
  if responseEC2['Reservations'][n]['Instances'][0]['IamInstanceProfile']['Arn'] != "":
    profile_count += 1

if len(responseEC2['Reservations']) == profile_count:
  print("Well done! You have an IAM Instance profile per instance... ")
  grandtotal += 1
  currentPoints()
else:
  print("You have an incorrect number of IAM Instance Profiles...") 
  print("These are the ARNs of your attached IAM Instance Profiles...")
  for n in range(0,len(responseEC2['Reservations'])):
    print(str(responseEC2['Reservations'][n]['Instances'][0]['IamInstanceProfile']['Arn']) + " for instanceID: " + str(responseEC2['Reservations'][n]['Instances'][0]['InstanceId']))      
  
  print("Perhaps double check that you added an IAM Instance Profile Value to your Launch Template in the main.tf...")
  print("Or you may need to run terraform destroy to clean up a previous lab...")
  currentPoints()

print('*' * 79)
print("\r")
##############################################################################
# Check to see if two S3 buckets are present and images are present
# knuth.jpg and vegeta.jpg
##############################################################################
print('*' * 79)
correctNumberOfBuckets = False
correctContentOfBuckets = False
print("Testing to see if the correct number of S3 buckets is present... ")
if len(responseS3['Buckets']) == correctNumberOfS3Buckets:
  print("Correct number of S3 buckets present: " + str(correctNumberOfS3Buckets))
  for n in range(0,len(responseS3['Buckets'])):
    print("Bucket Name: " + responseS3['Buckets'][n]['Name'])
    correctNumberOfBuckets = True
  
  print("Content of Raw Bucket...")
  for n in range(len(responseS3['Buckets'])):
    if "raw" in responseS3['Buckets'][n]['Name']:
      responselob = clients3.list_objects(Bucket=responseS3['Buckets'][n]['Name'] )
      for x in range(0,len(responselob['Contents'])):
        print(responselob['Contents'][x]['Key'])
        correctContentOfBuckets = True
  
  if correctNumberOfBuckets == True and correctContentOfBuckets == True:
    grandtotal += 1
    currentPoints()

else:
  print("Incorrect number of S3 buckets detected: " + str(len(responseS3['Buckets'])))
  print("Check your main.tf file to see if you have logic for the Raw and Finished Buckets...")
  print("Check to make sure you used the provided sample image files: vegeta.jpg and knuth.jpg -- the autograder is looking for those file names...")
  for n in range(0,len(responseS3['Buckets'])):
    print("Bucket Name: " + responseS3['Buckets'][n]['Name'])
  currentPoints()
print('*' * 79)
print("\r")
##############################################################################
# Checking the correct number of SNS topics and tagged correctly
##############################################################################
print('*' * 79)
print("Checking the correct number of SNS topics and tagged correctly...")

correctNumberOfTopics = False
correctValueOfTags = False

if len(responsesns['Topics']) == correctNumberOfSnsTopics:
  print("Well done! You have the correct number of SNS Topics: " + str(correctNumberOfSnsTopics) + "...")
  responsesnstags = clientsns.list_tags_for_resource(
    ResourceArn=responsesns['Topics'][0]['TopicArn']
  )
  correctNumberOfTopics = True

  if responsesnstags['Tags'][0]['Value'] == tag: 
    print("You have the correct Tag for your SNS Topic ARN: ")
    print(str(responsesns['Topics'][0]['TopicArn']) + " with tag: " + str(responsesnstags['Tags'][0]['Value']) + "...")
    correctValueOfTags = True
  else:
    print("You have the incorrect tag for your SNS Topic, expecting:" + tag)
    print("Your SNS Topic is tagged: " + responsesnstags['Tags'][0]['Value'])
    print("Double check your terraform.tfvars file for tag-name...")
    print("Or check you main.tf SNS Topic creation function to make sure it is tagged with: " + tag)
    currentPoints()

else:
  print("You have an incorrect number of SNS Topics, you have: " + str(len(responsesns['Topics'])) + "...")
  print("Perhaps double check that you added the proper terraform function ")
  print("in main.tf to create an SNS topic and tag it with " + tag + " .")
  print("Double check you ran the terraform destroy command from a previous lab...")
  currentPoints()

if correctNumberOfTopics == True and correctValueOfTags == True:
  grandtotal += 1
  currentPoints()

print('*' * 79)
print("\r")
##############################################################################
# Check the existence of an RDS instance tagged module-04 and a snapshot
# named: coursera-snapshot
##############################################################################
print('*' * 79)
print("Check the existence of an RDS instance tagged module-04 and a snapshot named: coursera-snapshot")
snapShotNameMatch = False
countOfRDSInstanceCorrect = False

if len(responserdssnapshot['DBSnapshots']) == correctNumberOfRDSSnapshots and responserdssnapshot['DBSnapshots'][0]['DBSnapshotIdentifier'] == snapshotname:
  print("You have the required number of database snapshots: " + str(len(responserdssnapshot['DBSnapshots'])))
  print("You have the correct required name for your snapshot: " + str(responserdssnapshot['DBSnapshots'][0]['DBSnapshotIdentifier']))
  snapShotNameMatch = True
  if len(responselistinstances['DBInstances']) == correctNumberOfRDSInstances and responselistinstances['DBInstances'][0]['TagList'][0]['Value'] == tag:
    print ("You have the correct number of RDS instances required: " + str(correctNumberOfRDSInstances) + "...")
    print("Your RDS instance: " + str(responselistinstances['DBInstances'][0]['DBInstanceIdentifier']) + " is correctly tagged: " + str(responselistinstances['DBInstances'][0]['TagList'][0]['Value']))
    countOfRDSInstanceCorrect = True
  else:
    print("Double check the terraform.tfvars file to make sure you the tag-name value set properly...")
    print("Double check the main.tf to make sure your RDS instances deployed...")
    print("Double check that you executed the command terraform destroy and cleared out any previous assessments...")
    currentPoints()
else:
  print("You may have the incorrect number of RDS instances:" + str(correctNumberOfRDSInstances) + " is required...")
  print("You have " + str(len(responserdssnapshot['DBSnapshots'])) + " instance(s)...")
  print("You may be missing your RDS Snapshot or the snapshot is")
  print("not named:" + snapshotname + "...")
  currentPoints()

if snapShotNameMatch is True and countOfRDSInstanceCorrect is True:
  grandtotal += 1
  currentPoints()
else:
  currentPoints()

print('*' * 79)
print("\r")
##############################################################################
# Checking for the existence of two secrets: uname and pword 
##############################################################################
print('*' * 79)
print("Testing for the existence of two secrets: uname and pword... ")
numOfSec = False
nameOfSec = False

if len(responsesm['SecretList']) == correctNumberOfSecrets:
 print("You have the correct number of AWS secrets: " + str(len(responsesm['SecretList'])))
 print("and they are tagged correctly: " + tag + "...")
 numOfSec = True
else:
  print("You have the incorrect number of secrets: " + + str(len(responsesm['SecretList'])))
  print("They are tagged:")
  for x in range(len(responsesm['SecretList'])):
    print(responsesm['SecretList'][x]['tags'][0]['Values'])

if responsesm['SecretList'][0]['Name'] == 'pword' or responsesm['SecretList'][1]['Name'] == 'pword' and responsesm['SecretList'][1]['Name'] == 'uname' or responsesm['SecretList'][0]['Name'] == 'uname': 
  print("You have the correct secrets created...")
  for n in range(len(responsesm['SecretList'])):
    print(responsesm['SecretList'][n]['Name']) 
  nameOfSec = True 
else:
  print("Your secrets are not created with the correct name: uname and pword...")
  print("Double check your main.tf and make sure that you have assigned the required names...") 

if numOfSec == True and nameOfSec == True:
  grandtotal += 1
  currentPoints()
else:
  currentPoints()
  
print('*' * 79)
print("\r")
##############################################################################
# Checking to see if the Database Subnet Group was created
##############################################################################
print('*' * 79)
print("Testing to see if the Database Subnet Group was created...")
nameOfDBSubnetGroups = False
locOfDBSubnetGroups = False

for n in range(0,len(responsedbsubnet['DBSubnetGroups'])):
    if responsedbsubnet['DBSubnetGroups'][n]['DBSubnetGroupName'] == 'coursera-project':
      print("Found Correct DB subnet group name: " + str(responsedbsubnet['DBSubnetGroups'][n]['DBSubnetGroupName']))
      nameOfDBSubnetGroups = True
    else:
      break

if len(responsedbsubnet['DBSubnetGroups'][0]['Subnets']) >= correctNumberOfDBAcrossSubnets: 
  print("Your DB subnet groups are located in the following AZs...")
  for n in range(0,len(responsedbsubnet['DBSubnetGroups'][0]['Subnets'])):
    print(responsedbsubnet['DBSubnetGroups'][0]['Subnets'][n]['SubnetAvailabilityZone']['Name'])
  
  locOfDBSubnetGroups = True
else:
  print("Your number of subnets that your db subnet group covers is not correct...")
  print("Your region should have at least 3 AZs and therefore 3 subnets one per AZ...")
  print("You have: " + len(responsedbsubnet['DBSubnetGroups'][0]['Subnets']) + " db subnet groups...")
  print("Located in...")
  for n in range(0,len(responsedbsubnet['DBSubnetGroups'][0]['Subnets'])):
    print(responsedbsubnet['DBSubnetGroups'][0]['Subnets'][n]['SubnetAvailabilityZone']['Name'])
  
if nameOfDBSubnetGroups is True and locOfDBSubnetGroups is True:
  grandtotal += 1
  currentPoints()
else:
  print("Did not find correct DB subnet group name: " + str(responsedbsubnet['DBSubnetGroups'][n]['DBSubnetGroupName']))
  print("Double check your main.tf in the section where you created your db subnet group and the name you assigned...")
  currentPoints()

print('*' * 79)
print("\r")
##############################################################################
# Check for SNS subscriptions 
##############################################################################
print('*' * 79)
print("Testing to if your SNS topic has a subscription...")
numTopics = False
subTopics = False

if len(responsesns['Topics'])  == correctNumberOfSnsTopics:
  print("You have the correct number of SNS topics: " + str(len(responsesns['Topics'])))
  print("With a Topic Arn of: " + responsesns['Topics'][0]['TopicArn'])
  numTopics = True
  responselbt=clientsns.list_subscriptions_by_topic(TopicArn=responsesns['Topics'][0]['TopicArn'])
  if len(responselbt['Subscriptions']) != 0:
    print("You have an SNS topic subscription...")
    print(responselbt['Subscriptions'][0]['SubscriptionArn'])
    print("Over this protocol: " + responselbt['Subscriptions'][0]['Protocol'])
    print("To this endpoint: " + responselbt['Subscriptions'][0]['Endpoint'])
    subTopics = True
else:
  print("Double check your main.tf to make sure you have an SNS topic created...")

if numTopics is True and subTopics is True:
  grandtotal += 1
  currentPoints()
else:
  currentPoints()

print('*' * 79)
print("\r")
##############################################################################
# Check to see that there are three Security Group Rules for 80,22,and 3306
##############################################################################
print('*' * 79)
print("Testing to see that there are three Security Group Rules...")

if responsesg['SecurityGroups'] == 0:
  print("There are no security groups created and tagged with: " + tag + "...")
  print("Double check your main.tf file that the vpc security groups were defined properly...")

if len(responsesg['SecurityGroups'][0]['IpPermissions']) == 3:
  print("You have the correct number of security groups with the correct ports open...")
  for n in range(0,len(responsesg['SecurityGroups'][0]['IpPermissions'])):
    print("To port: " + str(responsesg['SecurityGroups'][0]['IpPermissions'][n]['ToPort']))
  
  grandtotal += 1
  currentPoints()

else: 
  print("You have these security group ports open...")
  print("Double check your main.tf and your vpc security group rules declaration and")
  print("make sure you have all three required: 80, 22, and 3306...")
  for n in range(0,len(responsesg['SecurityGroups'][0]['IpPermissions'])):
    print("To port: " + str(responsesg['SecurityGroups'][0]['IpPermissions'][n]['ToPort']))
  
  currentPoints()

print('*' * 79)
print("\r")
##############################################################################
# Check that a custom AMI exists with tag of: Name module-04 
# ##############################################################################
print('*' * 79)
print("Testing to see if a custom AMI exists with the tag of: " + tag + "...")

if len(responseEC2AMI['Images']) != 0:
  print("Your custom AMI has an ImageId of: " + responseEC2AMI['Images'][0]['ImageId'])
  print("Your custom AMI has an OwnerId of: " + responseEC2AMI['Images'][0]['OwnerId'])
  print("Your custom AMI has a State of: " + responseEC2AMI['Images'][0]['State'])
  grandtotal += 1
  currentPoints()
else:
  print("You need to go back and check the recordings... creating a custom AMI was a")
  print("manual process, not part of the terraform main.tf...")
  currentPoints()

print('*' * 79)
print("\r")
##############################################################################
# Print out the grandtotal and the grade values to result.txt
##############################################################################
print('*' * 79)
print("Your result is: " + str(grandtotal) + " out of " + str(totalPoints) + " points.")
print("You can retry any items that need adjustment and retest...")

# Write results to a text file for import to the grade system
# https://www.geeksforgeeks.org/sha-in-python/
f = open('module-04-results.txt', 'w', encoding="utf-8")

# Gather sha256 of module-name and grandtotal
# https://stackoverflow.com/questions/70498432/how-to-hash-a-string-in-python
# Create datetime timestamp
dt='{:%Y%m%d%H%M%S}'.format(datetime.datetime.now())
resultToHash=(assessmentName + str(grandtotal/totalPoints) + dt)
h = hashlib.new('sha256')
h.update(resultToHash.encode())

resultsdict = {
  'Name': assessmentName,
  'gtotal' : grandtotal/totalPoints,
  'datetime': dt,
  'sha': h.hexdigest() 
}

listToHash=[assessmentName,grandtotal,dt,h.hexdigest()]
print("Writing assessment grade to text file...")
json.dump(resultsdict,f)
print("Write successful! Ready to submit your Assessment...")
print("You should now see a module-04-results.txt file has been generated on your CLI...")
print("Submit this to Coursera as your deliverable...")
f.close
print('*' * 79)
print("\r")
