#!/bin/bash

# Script para integrar o ALB criado pelo Terraform com o ECS Service
# Atualiza automaticamente o ECS Service com o novo Target Group

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações do projeto
CLUSTER_NAME="cluster-bia"
SERVICE_NAME="service-bia"
TASK_DEFINITION="task-def-bia"
REGION="us-east-1"

echo -e "${BLUE}=== Integração ALB + ECS - Projeto BIA ===${NC}"
echo ""

# Verificar se o ALB existe
echo -e "${BLUE}🔍 Verificando se ALB existe...${NC}"
if ! aws elbv2 describe-load-balancers --names "bia-alb" --region $REGION &>/dev/null; then
    echo -e "${RED}❌ ALB 'bia-alb' não encontrado!${NC}"
    echo -e "${YELLOW}💡 Execute primeiro: ./manage-alb.sh apply${NC}"
    exit 1
fi

# Obter ARN do Target Group
echo -e "${BLUE}🎯 Obtendo ARN do Target Group...${NC}"
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names "tg-bia" --region $REGION --query 'TargetGroups[0].TargetGroupArn' --output text)

if [ "$TARGET_GROUP_ARN" == "None" ] || [ -z "$TARGET_GROUP_ARN" ]; then
    echo -e "${RED}❌ Target Group 'tg-bia' não encontrado!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Target Group encontrado: $TARGET_GROUP_ARN${NC}"

# Verificar se o ECS Service existe
echo -e "${BLUE}🔍 Verificando ECS Service...${NC}"
if ! aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION &>/dev/null; then
    echo -e "${RED}❌ ECS Service '$SERVICE_NAME' não encontrado no cluster '$CLUSTER_NAME'!${NC}"
    exit 1
fi

# Obter a task definition atual
echo -e "${BLUE}📋 Obtendo Task Definition atual...${NC}"
CURRENT_TASK_DEF=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].taskDefinition' --output text)
echo -e "${BLUE}📄 Task Definition atual: $CURRENT_TASK_DEF${NC}"

# Obter detalhes da task definition
TASK_DEF_DETAILS=$(aws ecs describe-task-definition --task-definition $CURRENT_TASK_DEF --region $REGION)

# Extrair informações necessárias
FAMILY=$(echo $TASK_DEF_DETAILS | jq -r '.taskDefinition.family')
CONTAINER_DEFINITIONS=$(echo $TASK_DEF_DETAILS | jq '.taskDefinition.containerDefinitions')
REQUIRES_COMPATIBILITIES=$(echo $TASK_DEF_DETAILS | jq -r '.taskDefinition.requiresCompatibilities[]')
NETWORK_MODE=$(echo $TASK_DEF_DETAILS | jq -r '.taskDefinition.networkMode')
CPU=$(echo $TASK_DEF_DETAILS | jq -r '.taskDefinition.cpu // empty')
MEMORY=$(echo $TASK_DEF_DETAILS | jq -r '.taskDefinition.memory // empty')
EXECUTION_ROLE_ARN=$(echo $TASK_DEF_DETAILS | jq -r '.taskDefinition.executionRoleArn // empty')
TASK_ROLE_ARN=$(echo $TASK_DEF_DETAILS | jq -r '.taskDefinition.taskRoleArn // empty')

# Criar nova task definition com load balancer configurado
echo -e "${BLUE}🔧 Criando nova Task Definition com Load Balancer...${NC}"

# Preparar JSON para nova task definition
NEW_TASK_DEF_JSON=$(cat <<EOF
{
  "family": "$FAMILY",
  "containerDefinitions": $CONTAINER_DEFINITIONS,
  "requiresCompatibilities": ["$REQUIRES_COMPATIBILITIES"],
  "networkMode": "$NETWORK_MODE"
EOF
)

# Adicionar CPU e Memory se existirem
if [ "$CPU" != "null" ] && [ "$CPU" != "" ]; then
    NEW_TASK_DEF_JSON=$(echo $NEW_TASK_DEF_JSON | jq ". + {\"cpu\": \"$CPU\"}")
fi

if [ "$MEMORY" != "null" ] && [ "$MEMORY" != "" ]; then
    NEW_TASK_DEF_JSON=$(echo $NEW_TASK_DEF_JSON | jq ". + {\"memory\": \"$MEMORY\"}")
fi

# Adicionar roles se existirem
if [ "$EXECUTION_ROLE_ARN" != "null" ] && [ "$EXECUTION_ROLE_ARN" != "" ]; then
    NEW_TASK_DEF_JSON=$(echo $NEW_TASK_DEF_JSON | jq ". + {\"executionRoleArn\": \"$EXECUTION_ROLE_ARN\"}")
fi

if [ "$TASK_ROLE_ARN" != "null" ] && [ "$TASK_ROLE_ARN" != "" ]; then
    NEW_TASK_DEF_JSON=$(echo $NEW_TASK_DEF_JSON | jq ". + {\"taskRoleArn\": \"$TASK_ROLE_ARN\"}")
fi

# Fechar JSON
NEW_TASK_DEF_JSON=$(echo $NEW_TASK_DEF_JSON | jq '. + {}}')

# Registrar nova task definition
echo -e "${BLUE}📝 Registrando nova Task Definition...${NC}"
NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEF_JSON | aws ecs register-task-definition --region $REGION --cli-input-json file:///dev/stdin --query 'taskDefinition.taskDefinitionArn' --output text)

echo -e "${GREEN}✅ Nova Task Definition criada: $NEW_TASK_DEF_ARN${NC}"

# Atualizar ECS Service com Load Balancer
echo -e "${BLUE}🔄 Atualizando ECS Service com Load Balancer...${NC}"

aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $NEW_TASK_DEF_ARN \
    --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=bia,containerPort=8080 \
    --region $REGION \
    --query 'service.serviceName' \
    --output text

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ECS Service atualizado com sucesso!${NC}"
    echo ""
    echo -e "${BLUE}🌐 Informações do ALB:${NC}"
    
    # Mostrar DNS do ALB
    ALB_DNS=$(aws elbv2 describe-load-balancers --names "bia-alb" --region $REGION --query 'LoadBalancers[0].DNSName' --output text)
    echo -e "${GREEN}   DNS: $ALB_DNS${NC}"
    echo -e "${GREEN}   HTTPS: https://$ALB_DNS${NC}"
    echo -e "${GREEN}   HTTP: http://$ALB_DNS (redireciona para HTTPS)${NC}"
    
    echo ""
    echo -e "${YELLOW}⏳ Aguarde alguns minutos para o serviço ficar disponível...${NC}"
    echo -e "${BLUE}💡 Você pode verificar o status com: aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME${NC}"
else
    echo -e "${RED}❌ Erro ao atualizar ECS Service${NC}"
    exit 1
fi
