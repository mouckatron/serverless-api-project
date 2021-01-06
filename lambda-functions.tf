
resource "aws_lambda_function" "lambda" {
  count = length(var.lambda_functions)

  function_name = "${var.appname}-${var.lambda_functions[count.index].name}"

  s3_bucket = aws_s3_bucket.lambda.id
  s3_key    = "${var.lambda_functions[count.index].name}.zip"

  handler = var.lambda_functions[count.index].handler
  runtime = var.lambda_functions[count.index].runtime

  role = aws_iam_role.lambda.arn

  tags = {
    appname = var.appname
  }
}

resource "aws_lambda_permission" "apigateway-latest" {
  count = length(var.lambda_functions)

  statement_id  = "APIGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
  function_name = aws_lambda_function.lambda[count.index].function_name
}

resource "aws_lambda_permission" "apigateway-production" {
  count = length(var.lambda_functions)

  statement_id  = "APIGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
  function_name = aws_lambda_function.lambda[count.index].function_name
  qualifier     = "production"
}

resource "aws_lambda_alias" "production" {
  count = length(var.lambda_functions)

  name             = "production"
  function_name    = aws_lambda_function.lambda[count.index].function_name
  function_version = var.lambda_functions[count.index].version

}
