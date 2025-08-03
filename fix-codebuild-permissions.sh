#!/bin/bash

echo "🔧 Corrigindo permissões do CodeBuild para ECR..."

# Anexar política gerenciada para ECR
echo "📦 Anexando política ECR à role do CodeBuild..."
aws iam attach-role-policy \
    --role-name codebuild-bia-build-service-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# Anexar política gerenciada para ECS (para deploy)
echo "🚀 Anexando política ECS à role do CodeBuild..."
aws iam attach-role-policy \
    --role-name codebuild-bia-build-service-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

echo "✅ Permissões corrigidas com sucesso!"
echo ""
echo "📋 Políticas anexadas:"
echo "   - AmazonEC2ContainerRegistryPowerUser (para ECR)"
echo "   - AmazonECS_FullAccess (para deploy no ECS)"
echo ""
echo "🔄 Agora você pode executar o pipeline novamente."
