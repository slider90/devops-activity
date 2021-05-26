resource "aws_iam_role" "api_to_lambda" {
  name = "iam_for_api"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "api_invoke_policy" {
  name = "api_policy"
  role = aws_iam_role.api_to_lambda.id

  policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "lambda:InvokeFunction",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_apigatewayv2_api" "task" {
  name                       = "task-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "task" {
  api_id = aws_apigatewayv2_api.task.id
  name   = "task-stage"
}

resource "aws_apigatewayv2_route" "task" {
  api_id    = aws_apigatewayv2_api.task.id
  route_key = "$default"
  target = "integrations/${aws_apigatewayv2_integration.task.id}"
  route_response_selection_expression = "$default"
}


resource "aws_apigatewayv2_integration" "task" {
  api_id              = aws_apigatewayv2_api.task.id
  credentials_arn     = aws_iam_role.api_to_lambda.arn
  description         = "lamda task"
  integration_type    = "AWS_PROXY"
  #integration_method = "POST"
  integration_uri     = aws_lambda_function.test_lambda.invoke_arn

}

resource "aws_apigatewayv2_deployment" "task" {
  api_id      = aws_apigatewayv2_route.task.api_id
  description = "task deployment"

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.task),
      jsonencode(aws_apigatewayv2_route.task),
    ])))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_route" "get" {
  api_id    = aws_apigatewayv2_api.task.id
  route_key = "get-random-data"
  target = "integrations/${aws_apigatewayv2_integration.get.id}"
}

resource "aws_apigatewayv2_integration" "get" {
  api_id              = aws_apigatewayv2_api.task.id
 credentials_arn      = aws_iam_role.api_to_lambda.arn
  description         = "lamda task"
  integration_type    = "AWS_PROXY"
  integration_uri     = aws_lambda_function.test_lambda.invoke_arn

}

resource "aws_apigatewayv2_integration_response" "task" {
  api_id                   = aws_apigatewayv2_api.task.id
  integration_id           = aws_apigatewayv2_integration.get.id
  integration_response_key = "/200/"
  response_templates       = {}
}

resource "aws_apigatewayv2_route_response" "task" {
  api_id             = aws_apigatewayv2_api.task.id
  route_id           = aws_apigatewayv2_route.get.id
  route_response_key = "$default"
}

# resource "aws_lambda_permission" "lambda_permission" {
#   statement_id  = "AllowMyDemoAPIInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.test_lambda.function_name
#   principal     = "apigateway.amazonaws.com"

#   # The /*/*/* part allows invocation from any stage, method and resource path
#   # within API Gateway REST API.
#   source_arn = "${aws_apigatewayv2_api.task.execution_arn}/*/*/*"
# }

