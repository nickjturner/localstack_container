
awslocal sns create-topic \
    --name input-topic

awslocal sqs create-queue \
    --queue-name input-queue

awslocal sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:input-topic \
    --protocol sqs \
    --notification-endpoint http://localhost:4566/queue/input-queue \
    --attributes '{"RawMessageDelivery":"true"}'

awslocal s3api create-bucket \
    --bucket test-bucket \
    --acl public-read-write

awslocal s3 cp /localstack_files/test.pdf s3://test-bucket

awslocal lambda create-function \
    --function-name test-lambda \
    --runtime go1.x \
    --handler main \
    --role test \
    --zip-file fileb:///localstack_files/test-lambda.zip \
    --environment Variables="{OUTPUT_SNS_ARN=arn:aws:sns:us-east-1:000000000000:output-topic,S3_BUCKET=test-bucket}"

awslocal lambda create-event-source-mapping \
    --function-name test-lambda \
    --event-source-arn arn:aws:sqs:us-east-1:000000000000:input-queue

awslocal sns create-topic \
    --name output-topic

awslocal sqs create-queue \
    --queue-name output-queue

awslocal sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:output-topic \
    --protocol sqs \
    --notification-endpoint http://localhost:4566/queue/output-queue \
    --attributes '{"RawMessageDelivery":"true"}'

echo "Ready"