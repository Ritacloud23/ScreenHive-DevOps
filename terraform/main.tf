data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/screenhive/dev"
  retention_in_days = 7
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  environment  = var.environment
  az           = data.aws_availability_zones.available.names[0]
}

module "registry" {
  source       = "./modules/registry"
  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source                = "./modules/iam"
  project_name          = var.project_name
  environment           = var.environment
  github_repository     = var.github_repository
  github_oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  ecr_repository_arn    = module.registry.repository_arn
  instance_arn_prefix   = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
}

module "compute" {
  source             = "./modules/compute"
  project_name       = var.project_name
  environment        = var.environment
  instance_type      = var.instance_type
  subnet_id          = module.network.public_subnet_id
  security_group_id  = module.network.security_group_id
  instance_profile   = module.iam.ec2_instance_profile_name
  aws_region         = var.aws_region
}

output "instance_id" {
  value       = module.compute.instance_id
  description = "EC2 instance ID; set as GitHub Actions variable EC2_INSTANCE_ID."
}

output "public_ip" {
  value       = module.compute.public_ip
  description = "Public IPv4 address for the API (port 8000)."
}

output "ecr_repository_url" {
  value       = module.registry.repository_url
  description = "ECR image URI; set as GitHub Actions variable ECR_REPOSITORY_URI."
}

output "github_actions_role_arn" {
  value       = module.iam.github_actions_role_arn
  description = "OIDC role ARN; set as GitHub Actions variable AWS_ROLE_ARN."
}

output "cloudwatch_log_group" {
  value       = aws_cloudwatch_log_group.app.name
}
