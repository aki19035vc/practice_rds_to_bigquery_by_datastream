resource "aws_security_group" "rds" {
  description            = "${local.app}-${local.env}-rds"
  name                   = "${local.app}-${local.env}-rds"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = false

  tags = {
    Name = "${local.app}-${local.env}-rds"
  }
}

resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
}

# GCPと接続しやすくするために全公開にする。本来はVPCピアリングなどを利用してセキュアな構成にするべき。
resource "aws_security_group_rule" "rds_ingress" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
}
