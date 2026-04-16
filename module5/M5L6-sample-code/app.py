import boto3
import mysql.connector
from io import BytesIO
from PIL import Image

messagesInQueue = False

# https://stackoverflow.com/questions/40377662/boto3-client-noregionerror-you-must-specify-a-region-error-only-sometimes
region = 'us-east-2'

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs.html
clientSQS = boto3.client('sqs',region_name=region)
clientRDS = boto3.client('rds',region_name=region)
clientSM = boto3.client('secretsmanager',region_name=region)
clientS3 = boto3.client('s3', region_name=region)

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
    im.save("/tmp/grayscale-" + OBJECT_NAME)

    print("Printing Grayscale Image size meta-data...")
    print(im.format, im.size, im.mode)

    # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs/client/delete_message.html
    print("Now deleting the message off of the queue...")
    responseDelMessage = clientSQS.delete_message(
        QueueUrl=responseURL['QueueUrls'][0],
        ReceiptHandle=responseMessages['Messages'][0]['ReceiptHandle']
    )

    print(responseDelMessage)
