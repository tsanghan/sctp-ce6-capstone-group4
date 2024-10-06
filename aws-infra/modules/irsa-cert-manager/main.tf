locals {
  create_role = var.create && var.create_role

  account_id = try(data.aws_caller_identity.current[0].account_id, "*")
  partition  = try(data.aws_partition.current[0].partition, "*")

  role_name                    = try(coalesce(var.role_name, var.name), "")
  role_name_condition          = var.role_name_use_prefix ? "${local.role_name}-*" : local.role_name
  cert_manager_service_account = try(var.cert_manager.service_account_name, "cert-manager")
  create_cert_manager_irsa     = var.enable_cert_manager && length(var.cert_manager_route53_hosted_zone_arns) > 0
  cert_manager_namespace       = try(var.cert_manager.namespace, "cert-manager")

  namespace = try(coalesce(var.namespace, "default")) # Need to explicitly set default for use with IRSA
}

################################################################################
# IAM Role for Service Account(s) (IRSA)
################################################################################

data "aws_partition" "current" {
  count = local.create_role ? 1 : 0
}
data "aws_caller_identity" "current" {
  count = local.create_role ? 1 : 0
}

data "aws_iam_policy_document" "assume" {
  count = local.create_role ? 1 : 0

  dynamic "statement" {
    # https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/
    for_each = var.allow_self_assume_role ? [1] : []

    content {
      sid     = "ExplicitSelfRoleAssumption"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = ["arn:${local.partition}:iam::${local.account_id}:role${var.role_path}${local.role_name_condition}"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.oidc_providers

    content {
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = [statement.value.provider_arn]
      }

      condition {
        test     = var.assume_role_condition_test
        variable = "${replace(statement.value.provider_arn, "/^(.*provider/)/", "")}:sub"
        values   = ["system:serviceaccount:${try(statement.value.namespace, local.namespace)}:${statement.value.service_account}"]
      }

      # https://aws.amazon.com/premiumsupport/knowledge-center/eks-troubleshoot-oidc-and-irsa/?nc1=h_ls
      condition {
        test     = var.assume_role_condition_test
        variable = "${replace(statement.value.provider_arn, "/^(.*provider/)/", "")}:aud"
        values   = ["sts.amazonaws.com"]
      }
    }
  }
}

data "aws_iam_policy_document" "cert_manager" {
  count = local.create_cert_manager_irsa ? 1 : 0

  source_policy_documents   = lookup(var.cert_manager, "source_policy_documents", [])
  override_policy_documents = lookup(var.cert_manager, "override_policy_documents", [])

  statement {
    actions   = ["route53:GetChange", ]
    resources = ["arn:${local.partition}:route53:::change/*"]
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = var.cert_manager_route53_hosted_zone_arns
  }

  statement {
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "this" {
  count = local.create_role ? 1 : 0

  name        = var.role_name_use_prefix ? null : local.role_name
  name_prefix = var.role_name_use_prefix ? "${local.role_name}-" : null
  path        = var.role_path
  description = var.role_description

  assume_role_policy    = data.aws_iam_policy_document.assume[0].json
  max_session_duration  = var.max_session_duration
  permissions_boundary  = var.role_permissions_boundary_arn
  force_detach_policies = true

  tags = var.tags
}

# resource "aws_iam_role_policy_attachment" "additional" {
#   for_each = { for k, v in var.role_policies : k => v if local.create_role }

#   role       = aws_iam_role.this[0].name
#   policy_arn = each.value
# }

################################################################################
# IAM Policy
################################################################################

locals {
  create_policy = local.create_role && var.create_policy
  policy_name   = try(coalesce(var.policy_name, local.role_name), "")
  perms         = concat(var.source_policy_documents, var.override_policy_documents, var.policy_statements, data.aws_iam_policy_document.cert_manager)
}

# data "aws_iam_policy_document" "this" {
#   count = local.create_policy && length(local.perms) > 0 ? 1 : 0

#   source_policy_documents   = var.source_policy_documents
#   override_policy_documents = var.override_policy_documents

#   dynamic "statement" {
#     for_each = var.policy_statements

#     content {
#       sid           = try(statement.value.sid, null)
#       actions       = try(statement.value.actions, null)
#       not_actions   = try(statement.value.not_actions, null)
#       effect        = try(statement.value.effect, null)
#       resources     = try(statement.value.resources, null)
#       not_resources = try(statement.value.not_resources, null)

#       dynamic "principals" {
#         for_each = try(statement.value.principals, [])

#         content {
#           type        = principals.value.type
#           identifiers = principals.value.identifiers
#         }
#       }

#       dynamic "not_principals" {
#         for_each = try(statement.value.not_principals, [])

#         content {
#           type        = not_principals.value.type
#           identifiers = not_principals.value.identifiers
#         }
#       }

#       dynamic "condition" {
#         for_each = try(statement.value.conditions, [])

#         content {
#           test     = condition.value.test
#           values   = condition.value.values
#           variable = condition.value.variable
#         }
#       }
#     }
#   }
# }

resource "aws_iam_policy" "this" {
  count = local.create_policy && length(local.perms) > 0 ? 1 : 0

  name        = var.policy_name_use_prefix ? null : local.policy_name
  name_prefix = var.policy_name_use_prefix ? "${local.policy_name}-" : null
  path        = coalesce(var.policy_path, var.role_path)
  description = try(coalesce(var.policy_description, var.role_description), null)
  policy      = data.aws_iam_policy_document.cert_manager[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  count = local.create_policy && length(local.perms) > 0 ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.this[0].arn
}