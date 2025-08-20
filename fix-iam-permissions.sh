#!/bin/bash

echo "=== SCRIPT PARA CORRIGIR PERMISSÕES IAM ==="
echo "Este script deve ser executado por um usuário com permissões administrativas"
echo ""

# Criar política customizada
echo "1. Criando política ECS para CodeBuild..."
aws iam create-policy \
    --policy-name CodeBuildECSDeployPolicy \
    --policy-document file://ecs-deploy-policy.json \
    --description "Política para permitir deploy do CodeBuild no ECS" \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo "✅ Política criada com sucesso"
    
    # Anexar política à role
    echo "2. Anexando política à role do CodeBuild..."
    aws iam attach-role-policy \
        --role-name codebuild-bia-build-service-role \
        --policy-arn arn:aws:iam::098978302313:policy/CodeBuildECSDeployPolicy \
        --region us-east-1
    
    if [ $? -eq 0 ]; then
        echo "✅ Política anexada com sucesso"
    else
        echo "❌ Erro ao anexar política"
    fi
else
    echo "⚠️  Política pode já existir, tentando anexar..."
    aws iam attach-role-policy \
        --role-name codebuild-bia-build-service-role \
        --policy-arn arn:aws:iam::098978302313:policy/CodeBuildECSDeployPolicy \
        --region us-east-1
fi

# Anexar política AWS gerenciada para ECS
echo "3. Anexando política AWS gerenciada para ECS..."
aws iam attach-role-policy \
    --role-name codebuild-bia-build-service-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo "✅ Política ECS anexada com sucesso"
else
    echo "⚠️  Política ECS pode já estar anexada"
fi

echo ""
echo "=== VERIFICANDO POLÍTICAS ANEXADAS ==="
aws iam list-attached-role-policies --role-name codebuild-bia-build-service-role --region us-east-1

echo ""
echo "=== SCRIPT CONCLUÍDO ==="
echo "Aguarde alguns minutos para que as permissões sejam propagadas antes de testar a pipeline."
