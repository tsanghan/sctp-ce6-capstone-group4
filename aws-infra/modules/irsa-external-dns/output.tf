output "external_dns_role_arn" {
  value = aws_iam_role.this[0].arn
}