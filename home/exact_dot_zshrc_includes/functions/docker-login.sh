function docker-login {
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 412041701469.dkr.ecr.us-east-1.amazonaws.com
}