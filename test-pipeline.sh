#!/bin/bash

echo "=== TESTE DA PIPELINE BIA ==="
echo "Simulando processo de build e deploy..."

# Variáveis
REPOSITORY_URI=098978302313.dkr.ecr.us-east-1.amazonaws.com/bia
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
IMAGE_TAG=${COMMIT_HASH:=latest}

echo "Repository URI: $REPOSITORY_URI"
echo "Image Tag: $IMAGE_TAG"

# Teste de login ECR
echo ""
echo "=== TESTANDO LOGIN ECR ==="
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 098978302313.dkr.ecr.us-east-1.amazonaws.com
if [ $? -eq 0 ]; then
    echo "✅ Login ECR: OK"
else
    echo "❌ Login ECR: FALHOU"
    exit 1
fi

# Teste de build
echo ""
echo "=== TESTANDO BUILD ==="
docker build -t $REPOSITORY_URI:latest .
if [ $? -eq 0 ]; then
    echo "✅ Build Docker: OK"
else
    echo "❌ Build Docker: FALHOU"
    exit 1
fi

# Tag da imagem
docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG

# Teste de push (opcional - descomente se quiser testar)
# echo ""
# echo "=== TESTANDO PUSH ==="
# docker push $REPOSITORY_URI:latest
# docker push $REPOSITORY_URI:$IMAGE_TAG

# Teste de permissões ECS
echo ""
echo "=== TESTANDO PERMISSÕES ECS ==="
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb --region us-east-1 > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Permissões ECS: OK"
else
    echo "❌ Permissões ECS: FALHOU - Verifique as permissões IAM"
fi

echo ""
echo "=== TESTE CONCLUÍDO ==="
