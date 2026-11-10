data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = var.instance_profile
  associate_public_ip_address = true
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-USERDATA
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y docker curl awscli
    systemctl enable --now docker
    mkdir -p /usr/local/lib/docker/cli-plugins /opt/screenhive
    curl -fsSL https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    cat > /opt/screenhive/deploy.sh <<'SCRIPT'
    #!/bin/bash
    set -euo pipefail
    IMAGE_URI="${1:?Pass immutable ECR image URI}"
    REGION="${AWS_REGION:-us-east-1}"
    cd /opt/screenhive
    aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${IMAGE_URI%%/*}"
    aws ssm get-parameter --name /screenhive/dev/runtime-env --with-decryption --query Parameter.Value --output text --region "$REGION" > .env
    aws ssm get-parameter --name /screenhive/dev/firebase-service-account --with-decryption --query Parameter.Value --output text --region "$REGION" > firebase-service-account.json
    chmod 600 .env firebase-service-account.json
    curl -fsSL https://raw.githubusercontent.com/Ritacloud23/ScreenHive-DevOps/main/docker-compose.prod.yml -o docker-compose.prod.yml
    export ECR_IMAGE="$IMAGE_URI"
    docker compose -f docker-compose.prod.yml pull
    docker compose -f docker-compose.prod.yml up -d --remove-orphans
    docker image prune -f
    SCRIPT
    chmod 750 /opt/screenhive/deploy.sh
    chown -R ec2-user:ec2-user /opt/screenhive
    systemctl enable amazon-ssm-agent || true
    systemctl restart amazon-ssm-agent || true
  USERDATA

  tags = {
    Name        = "${var.project_name}-${var.environment}-api"
    Project     = var.project_name
    Environment = var.environment
  }
}
