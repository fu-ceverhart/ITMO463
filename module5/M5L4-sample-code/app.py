import boto3
import mysql.connector

# https://stackoverflow.com/questions/40377662/boto3-client-noregionerror-you-must-specify-a-region-error-only-sometimes
region = 'us-east-2'

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs.html
clientSQS = boto3.client('sqs',region_name=region)
clientRDS = boto3.client('rds',region_name=region)
clientSM = boto3.client('secretsmanager',region_name=region)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager/client/get_secret_value.html
print("Retrieving username SecretString...")
responseUNAME = clientSM.get_secret_value(
    SecretId='uname'
)
print("Retrieving password SecretString...")
responsePWORD = clientSM.get_secret_value(
    SecretId='pword'
)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rds/client/describe_db_instances.html
print("Retrieving RDS instance information...")
responseRDS = clientRDS.describe_db_instances()

##############################################################################
# Set database credentials
##############################################################################
hosturl = responseRDS['DBInstances'][0]['Endpoint']['Address']
uname = responseUNAME['SecretString']
pword = responsePWORD['SecretString']

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs/client/list_queues.html
print("Getting a list of SQS queues...")
responseURL = clientSQS.list_queues()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs/client/receive_message.html
print("Retrieving the message on the queue...")
responseMessages = clientSQS.receive_message(
    QueueUrl=responseURL['QueueUrls'][0]
)
print("Message body content: " + str(responseMessages['Messages'][0]['Body']) + "...")

print("Proceeding assuming there are messages on the queue...")
##############################################################################
# Connect to Mysql database to retrieve SQS queue record
# https://dev.mysql.com/doc/connector-python/en/connector-python-example-cursor-select.html
##############################################################################
print("Connecting to the RDS instances and retrieving the record with the ID passed via the SQS message...")
cnx = mysql.connector.connect(host=hosturl, user=uname, password=pword, database='company')
cursor = cnx.cursor()

query = ("SELECT * FROM entries WHERE ID = %s")

print("Message Body: " + str(responseMessages['Messages'][0]['Body']))
print("Executing the SQL query against the DB to retrieve all field of the record...")
cursor.execute(query, [(responseMessages['Messages'][0]['Body'])])

print("Printing out all the fields in the record...")
for (ID, RecordNumber, CustomerName, Email, Phone, Stat, RAWS3URL, FINISHEDURL) in cursor:
    print(RAWS3URL)

cursor.close()
cnx.close()

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs/client/delete_message.html
print("Now deleting the message off of the queue...")
responseDelMessage = clientSQS.delete_message(
    QueueUrl=responseURL['QueueUrls'][0],
    ReceiptHandle=responseMessages['Messages'][0]['ReceiptHandle']
)

print(responseDelMessage)
