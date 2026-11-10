data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "parameter_read" {
  name = "read-screenhive-runtime-parameters"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ssm:GetParameter"]
      Resource = [
        "arn:${data.aws_partition.current.partition}:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/screenhive/dev/runtime-env",
        "arn:${data.aws_partition.current.partition}:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/screenhive/dev/firebase-service-account"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-instance-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_iam_role" "github" {
  name = "${var.project_name}-${var.environment}-github-actions"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = var.github_oidc_provider_arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "push-ecr-and-deploy-via-ssm"
  role = aws_iam_role.github.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage"
        ]
        Resource = var.ecr_repository_arn
      },
      {
        Effect = "Allow"
        Action = ["ssm:SendCommand"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ssm:*::document/AWS-RunShellScript",
          var.instance_arn_prefix
        ]
      },
      {
        Effect = "Allow"
        Action = ["ssm:GetCommandInvocation", "ssm:ListCommandInvocations", "ec2:DescribeInstances"]
        Resource = "*"
      }
    ]
  })
}
