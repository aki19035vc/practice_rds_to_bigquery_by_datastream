# シークレットを削除すると同じ名前でしばらく作成できないため、回避策としてランダムな文字列を末尾に加えるための使用する
resource "aws_secretsmanager_secret" "main" {
  name = "${local.app}-${local.env}-${random_id.secretsmanager_id.hex}"
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id
  secret_string = jsonencode({
    DATABASE_HOST     = aws_db_instance.main.address
    DATABASE_USER     = "root"
    DATABASE_PASSWORD = random_password.database_root_user.result
  })
}
