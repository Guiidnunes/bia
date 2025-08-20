#!/bin/bash

echo "=== STATUS DA PIPELINE BIA ==="
echo ""

# Verificar serviço ECS
echo "1. STATUS DO SERVIÇO ECS:"
aws ecs describe-services \
    --cluster cluster-bia-alb \
    --services service-bia-alb \
    --region us-east-1 \
    --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,TaskDefinition:taskDefinition}' \
    --output table

# Verificar últimas imagens no ECR
echo ""
echo "2. ÚLTIMAS IMAGENS NO ECR:"
aws ecr describe-images \
    --repository-name bia \
    --region us-east-1 \
    --query 'sort_by(imageDetails,&imagePushedAt)[-5:].{Tag:imageTags[0],Pushed:imagePushedAt,Size:imageSizeInBytes}' \
    --output table

# Verificar logs recentes do CodeBuild
echo ""
echo "3. LOGS RECENTES DO CODEBUILD:"
echo "Para ver logs detalhados, execute:"
echo "aws logs filter-log-events --log-group-name '/aws/codebuild/bia-build' --start-time \$(date -d '1 hour ago' +%s)000 --region us-east-1"

# Verificar políticas da role
echo ""
echo "4. POLÍTICAS ANEXADAS À ROLE DO CODEBUILD:"
aws iam list-attached-role-policies \
    --role-name codebuild-bia-build-service-role \
    --region us-east-1 \
    --output table

echo ""
echo "=== VERIFICAÇÃO CONCLUÍDA ==="
