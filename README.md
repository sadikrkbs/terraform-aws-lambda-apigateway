## NOTES
This project is for:
* Creates a Websocket AWS API GW
* Creates an integration with a Lambda function. A simple "Hello word" 
* Creates a complete JWT authorizer (including Lambda code if necessary)
* CORS should be set to allow all

### JWT Authorizer: 
Update issuer and audience values ​​according to your own JWT configuration.
### CORS Configuration: 
CORS settings are generally not required in the WebSocket API, but are important for the REST API.
### Log Group: 
Check required permissions for CloudWatch Log Group and other resources.
With this Terraform configuration, you can create a structure that includes AWS API Gateway WebSocket API, Lambda function, JWT authorization and CORS settings.

We need to package the Lambda function code into a ZIP file to upload it to AWS Lambda. AWS Lambda imports the function code and its dependencies as a single file. Therefore, we compress the index.js file into ZIP format and use it to create the Lambda function.

Here's a brief summary of why and how we'll do this:

### Why Do We Package Into ZIP File?
Requirement for Lambda Function: AWS Lambda requires the function code and its dependencies to be packaged in a single ZIP file.
Easy Deployment: Installing code and dependencies together as a single file makes deployment and management easier.
Standard Implementation: AWS Lambda considers this method as standard, so it provides compatibility with other methods.
###  In windows ##
```
Compress-Archive -Path .\index.js -DestinationPath .\lambda.zip
```
###  In linux ##
```
zip lambda.zip index.js 
```
## Prerequisites

- AWS CLI configured with appropriate IAM permissions
- Node.js for creating the Lambda function

## Components

1. **IAM Role for Lambda**: Defines a role for the Lambda function with the necessary permissions.
2. **Lambda Function**: A simple Lambda function written in Node.js.
3. **API Gateway WebSocket API**: Configures the WebSocket API with a route selection expression.
4. **JWT Authorizer**: Configures the JWT authorizer for the WebSocket API.
5. **API Gateway Integration**: Integrates the WebSocket API with the Lambda function.
6. **CloudWatch Log Group**: Creates a log group for API Gateway access logs.
7. **IAM Role for API Gateway CloudWatch Logs**: Defines a role and policy for API Gateway to write logs to CloudWatch.
8. **API Gateway Stage**: Sets up the default stage with access log settings.


## Terraform RUN

for initialize state file and install providers
```
terraform init
```
for see changes in your infra (deleted-changed-created)
```
terraform plan 
```
for run your code and apply changes
```
terraform apply 
```
for destroy your infrastructure

```
terraform destroy 
```

## TEST APPLICATION
 open apigateway service in aws console and click "websocket-api" in left side click "stages"and inside stage details  copy @connections URL and send request this url after open" cloudwatch service" and see your access log inside "/aws/apigateway/websocket-access-logs"
curl -X GET "https://psyotgp6ea.execute-api.us-east-1.amazonaws.com/$default/@connections"
