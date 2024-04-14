resource "random_id" "secretsmanager_id" {
  byte_length = 4
}

resource "random_password" "database_root_user" {
  length  = 8
  special = false
}
