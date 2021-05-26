resource "aws_dynamodb_table" "my_table" {
  name           = "devops-activity"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "word"

  attribute {
    name = "word"
    type = "S"
  }

  provisioner "local-exec" {
    command = "bash dynamodb.sh"
  }
}
