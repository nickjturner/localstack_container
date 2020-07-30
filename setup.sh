
# Create an SNS topic
awslocal sns create-topic \
    --name input-topic

# Create an SQS Queue
awslocal sqs create-queue \
    --queue-name input-queue

# Create a subscription from the SNS topic to the SQS Queue
awslocal sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:input-topic \
    --protocol sqs \
    --notification-endpoint http://localhost:4566/queue/input-queue \
    --attributes '{"RawMessageDelivery":"true"}'

# Create a bucket
awslocal s3api create-bucket \
    --bucket test-bucket \
    --acl public-read-write

# Add a file to the bucket
awslocal s3 cp /localstack_files/test.pdf s3://test-bucket

# Create a lambda function from the zipped lambda
awslocal lambda create-function \
    --function-name test-lambda \
    --runtime go1.x \
    --handler main \
    --role test \
    --zip-file fileb:///localstack_files/test-lambda.zip \
    --environment Variables="{OUTPUT_SNS_ARN=arn:aws:sns:us-east-1:000000000000:output-topic,S3_BUCKET=test-bucket}"

# Set the lambda to trigger for an SQS Event
awslocal lambda create-event-source-mapping \
    --function-name test-lambda \
    --event-source-arn arn:aws:sqs:us-east-1:000000000000:input-queue

# Create an SNS Topic
awslocal sns create-topic \
    --name output-topic

# Create an SQS Queue
awslocal sqs create-queue \
    --queue-name output-queue

# Create a subscription from the SNS topic to the SQS Queue
awslocal sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:output-topic \
    --protocol sqs \
    --notification-endpoint http://localhost:4566/queue/output-queue \
    --attributes '{"RawMessageDelivery":"true"}'

echo "Ready"
