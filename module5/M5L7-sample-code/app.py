import boto3
import mysql.connector
from io import BytesIO
from PIL import Image
import logging
from botocore.exceptions import ClientError
import os
from botocore.config import Config

messagesInQueue = False

# https://stackoverflow.com/questions/40377662/boto3-client-noregionerror-you-must-specify-a-region-error-only-sometimes
region = 'us-east-2'

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs.html
clientSQS = boto3.client('sqs',region_name=region)
clientRDS = boto3.client('rds',region_name=region)
clientSM = boto3.client('secretsmanager',region_name=region)
# https://github.com/boto/boto3/issues/1644
# Needed to help generate pre-signed URLs
clientS3 = boto3.client('s3', region_name=region,config=Config(s3={'addressing_style': 'path'}, signature_version='s3v4') )

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
    QueueUrl=responseURL['QueueUrls'][0],
    VisibilityTimeout=180
)

# Check to see if the queue is empty
try:
  responseMessages['Messages']
  messagesInQueue = True
except:
  print("No messages found on the queue -- try to upload one image to your app...")
  exit(0) 

if messagesInQueue == True:
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
    for (ID, RecordNumber, CustomerName, Email, Phone, Stat, RAWS3URL, FINSIHEDS3URL) in cursor:
        print("ID: " + str(ID) + " RecordNumber: " + str(RecordNumber) + " CustomerName: " + CustomerName )
        print("Email: " + Email + " Phone: " + str(Phone) + " Status: " + str(Stat))
        print("Raw S3 URL: " + str(RAWS3URL) + " Finished URL: " + str(FINSIHEDS3URL))

    cursor.close()
    cnx.close()
    #######################################################################
    # Hack to skip first blank first record
    if str(RAWS3URL) == "http://":
      # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs/client/delete_message.html
      print("Now deleting the initial blank record off of the queue...")
      responseDelMessage = clientSQS.delete_message(
        QueueUrl=responseURL['QueueUrls'][0],
        ReceiptHandle=responseMessages['Messages'][0]['ReceiptHandle']
      )
      exit(0)

    # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3/client/list_buckets.html
    responseS3 = clientS3.list_buckets()

    for n in range(0,len(responseS3['Buckets'])):
        if "raw" in responseS3['Buckets'][n]['Name']:
            BUCKET_NAME = responseS3['Buckets'][n]['Name']

    # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3/client/list_objects.html
    responseS3Object = clientS3.list_objects(
        Bucket=BUCKET_NAME 
        )

    OBJECT_NAME = responseS3Object['Contents'][0]['Key']

    # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3/client/get_object.html
    responseGetObject = clientS3.get_object(
        Bucket=BUCKET_NAME,
        Key=OBJECT_NAME
    )

    # Saving S3 stream to a local byte stream
    print("Saving S3 byte stream to local byte stream...")
    file_byte_string = responseGetObject['Body'].read()

    # Convert byte stream to an Image object and pass it to PIL
    print("Converting local byte stream to an image...")
    im = Image.open(BytesIO(file_byte_string))

    print("Printing Image size meta-data...")
    print(im.format, im.size, im.mode)

    # https://pythonexamples.org/pillow-convert-image-to-grayscale/
    print("Converting image to grayscale...")
    # Convert the image to grayscale
    im = im.convert("L")
    print("Saving newly created image to disk...")
    # Save the grayscale image
    file_name = "/tmp/grayscale-" + OBJECT_NAME 
    im.save(file_name)

    print("Printing Grayscale Image size meta-data...")
    print(im.format, im.size, im.mode)
    ##############################################################################
    # Uploading Files to S3
    # https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-uploading-files.html
    # Upload the file
    ##############################################################################
    print("Pushing modified image to Finished S3 bucket...")
    for n in range(0,len(responseS3['Buckets'])):
      if "finished" in responseS3['Buckets'][n]['Name']:
        FIN_BUCKET_NAME = responseS3['Buckets'][n]['Name']

    try:
        responseS3Put = clientS3.upload_file(file_name, FIN_BUCKET_NAME, OBJECT_NAME)
    except ClientError as e:
        logging.error(e)
    ##############################################################################
    # Generate Presigned URL - that allows a time delimited public access to our edited image
    # https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-presigned-urls.html
    ##############################################################################
    print("Generating presigned S3 URL...")
    try:
        responsePresigned = clientS3.generate_presigned_url('get_object', Params={'Bucket': FIN_BUCKET_NAME,'Key': OBJECT_NAME},ExpiresIn=7200)
    except ClientError as e:
        logging.error(e)

    print(str(responsePresigned))
    
    # Update Finished URL to RDS Entry
    ##############################################################################
    # Connect to Mysql database Update record with Finished URL
    # https://dev.mysql.com/doc/connector-python/en/connector-python-example-cursor-select.html
    ##############################################################################
    print("Connecting to the RDS instances, and updating the Finished URL for record: " + str(ID) + "...")
    cnx = mysql.connector.connect(host=hosturl, user=uname, password=pword, database='company')
    cursor = cnx.cursor()

    update = ("UPDATE entries SET FINSIHEDS3URL = '" + str(responsePresigned) + "' WHERE ID = " + str(ID) + ";")
    print(update)

    print("Executing the UPDATE command against the DB...")
    cursor.execute(update)
    cnx.commit()

    cursor.close()
    cnx.close()

    ############################################################################
    # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs/client/delete_message.html
    print("Now deleting the message off of the queue...")
    responseDelMessage = clientSQS.delete_message(
        QueueUrl=responseURL['QueueUrls'][0],
        ReceiptHandle=responseMessages['Messages'][0]['ReceiptHandle']
    )

    print(responseDelMessage)
