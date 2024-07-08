provider "aws" {
  region = "us-east-1"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ],
  })
}

# IAM Policy Attachment
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Lambda Function
resource "aws_lambda_function" "hello_world" {
  filename         = "lambda.zip"
  function_name    = "hello-world"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda.zip")
}

# WebSocket API Gateway
resource "aws_apigatewayv2_api" "websocket_api" {
  name          = "websocket-api"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# JWT Authorizer
resource "aws_apigatewayv2_authorizer" "jwt_authorizer" {
  api_id = aws_apigatewayv2_api.websocket_api.id
  authorizer_uri = aws_lambda_function.hello_world.invoke_arn
  authorizer_type = "REQUEST"
  identity_sources = ["route.request.header.Auth"]

  jwt_configuration {
    issuer = "https://mycompany.com/" //your domain
    audience = ["my-audience"]
  }

  name = "jwt-authorizer"
}

# WebSocket Route
resource "aws_apigatewayv2_route" "connect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Integration with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.hello_world.invoke_arn
}

# CloudWatch Log Group for API Gateway Access Logs
resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/apigateway/websocket-access-logs"
  retention_in_days = 7
}

# IAM Role for API Gateway CloudWatch Logs
resource "aws_iam_role" "apigateway_cloudwatch_logs_role" {
  name = "APIGatewayCloudWatchLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy for API Gateway CloudWatch Logs
resource "aws_iam_policy" "apigateway_cloudwatch_logs_policy" {
  name        = "APIGatewayCloudWatchLogsPolicy"
  description = "Policy for API Gateway to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apigateway_cloudwatch_logs_role_attachment" {
  role       = aws_iam_role.apigateway_cloudwatch_logs_role.name
  policy_arn = aws_iam_policy.apigateway_cloudwatch_logs_policy.arn
}

# Set CloudWatch Logs role ARN in API Gateway account settings
resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch_logs_role.arn
  depends_on          = [aws_iam_role_policy_attachment.apigateway_cloudwatch_logs_role_attachment]
}

# WebSocket Stage
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id = aws_apigatewayv2_api.websocket_api.id
  name   = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
    format          = "$context.requestId $context.identity.sourceIp $context.identity.caller $context.identity.user $context.requestTime $context.httpMethod $context.resourcePath $context.status $context.protocol $context.responseLength"
  }

  depends_on = [
    aws_api_gateway_account.account
  ]
}
