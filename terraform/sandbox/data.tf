data "aws_subnets" "public" {
  filter {
    name = "subnet-id"
    values = [
      aws_subnet.public_a.id,
      aws_subnet.public_c.id
    ]
  }
}
