# LocalStack Container

[LocalStack](https://github.com/localstack/localstack) provides an easy-to-use framework for developing and testing in the AWS cloud stack.

It allows you to spin up any AWS components locally.

## Setup

This example creates a Dockerized LocalStack flow linking some SNS topics, SQS queues, a lambda and an S3 bucket.

It takes an SNS event with a JSON message e.g. `{"key": "test.pdf"}`, checks if that file exists in the S3 bucket, and outputs the result to an SQS queue.

![test-flow](https://user-images.githubusercontent.com/67937058/86827733-fd257680-c057-11ea-9a56-ba9b4f861038.png)

To test this example:

1. Clone the repo
2. Install [Docker](https://www.docker.com/)
3. Run `docker-compose up` to launch the container
4. Send the following message to the container:

```
docker-compose exec localstack \
awslocal sns publish --topic-arn arn:aws:sns:us-east-1:000000000000:input-topic --message '{"key":"test.pf"}'
```

You will see `Message:  {"validDoc": true}` in the logs. Or to view all messages the lambda has output run:

```
docker-compose exec localstack \
awslocal sqs receive-message --queue-url http://localhost:4566/queue/output-queue --max-number-of-messages 10
```

If you change the key to another document you will receive: `Message:  {"validDoc": false}`

## How It Works

There are 3 key components to the example.

### Lambdas

In the example the compiled and zipped lambda can be found at `localstack_files/test-lambda.zip`.

To test with other lambdas, either place them in this file or update the `docker-compose.yml` to replicate the folder where your lambda can be found (see below for more on docker-compose).

### Docker-Compose

There are 2 main parts in the `docker-compose.yml` that you may need to update.

1. Services

The example is using SNS, SQS, Lambdas and S3. These APIs are created in the `docker-compose.yml` using this line:

```
SERVICES=lambda,sns,sqs,s3
```

Other available APIs can be found in the [LocalStack repo](https://github.com/localstack/localstack)

2. Volumes

Volumes are files/folders that are replicated between the container and the local machine.

Compiled Lambas and other files being used are being replicated using this command:

```
./localstack_files:/localstack_files
```

If your lambda is in another folder is can be added to the container in a similar way.

The script to create the AWS components is added to the container here:

```
./setup.sh:/docker-entrypoint-initaws.d/setup.sh
```

LocalStack is set up to automatically run any scripts in the `docker-entrypoint-initaws.d` folder when it is launched.

### setup.sh

This script runs commands from the [AWS CLI](https://aws.amazon.com/cli/).

In the example it is creating some topics, queues, an S3 bucket and the lambda. It is then using the AWS CLI to set the subscriptions between these components.

## Additional Notes

### AWS Endpoint

By default AWS sessions call the real AWS environment. This can be overwritten locally to keep the process inside the container.

In a Go application, the LocalStack hostname is available at `os.Getenv("LOCALSTACK_HOSTNAME")`.

You can use this when creating an AWS Session with:

```
localStack := os.Getenv("LOCALSTACK_HOSTNAME")
sess, _ := session.NewSession(&aws.Config{
  Endpoint:         aws.String(fmt.Sprintf("%s:4566", localStack)),
  DisableSSL:       aws.Bool(true),
})
```

To call the container from an application outside of the container you can add similar code to the above, but for the endpoint you would use `http://localhost:4566`

### Sending Commands

To send any AWS CLI commands to the container after the setup script, prefix any commands with `docker-compose exec localstack`.

e.g.
```
docker-compose exec localstack \
awslocal sns publish --topic-arn arn:aws:sns:us-east-1:000000000000:input-topic --message '{"key":"test.pf"}'
```
