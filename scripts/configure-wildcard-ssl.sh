#!/bin/bash

# Script para configurar certificado wildcard para *.app-bia.com.br
# Execute este script para configurar HTTPS completo

echo "🔐 Configurando certificado wildcard para *.app-bia.com.br"
echo "=================================================="

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variáveis
DOMAIN="*.app-bia.com.br"
ROOT_DOMAIN="app-bia.com.br"
REGION="us-east-1"
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:098978302313:loadbalancer/app/bia-alb/7ba22f1baf624a69"
HTTPS_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:098978302313:listener/app/bia-alb/7ba22f1baf624a69/5b383175b339ecad"
HOSTED_ZONE_ID="Z02081913KGKPZCXJP1VP"

echo -e "${YELLOW}Passo 1: Solicitando certificado wildcard...${NC}"

# Solicitar certificado wildcard
CERT_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN" \
    --subject-alternative-names "$ROOT_DOMAIN" \
    --validation-method DNS \
    --key-algorithm RSA_2048 \
    --region $REGION \
    --query 'CertificateArn' \
    --output text)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Certificado solicitado com sucesso!${NC}"
    echo "ARN do Certificado: $CERT_ARN"
else
    echo -e "${RED}❌ Erro ao solicitar certificado${NC}"
    exit 1
fi

echo -e "${YELLOW}Passo 2: Aguardando informações de validação DNS...${NC}"
sleep 5

# Obter registros de validação DNS
echo "Obtendo registros de validação DNS..."
aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region $REGION \
    --query 'Certificate.DomainValidationOptions[*].[DomainName,ResourceRecord.Name,ResourceRecord.Value]' \
    --output table

echo -e "${YELLOW}Passo 3: Criando registros DNS de validação...${NC}"

# Obter registros de validação e criar no Route53
VALIDATION_RECORDS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region $REGION \
    --query 'Certificate.DomainValidationOptions[*].ResourceRecord' \
    --output json)

# Criar arquivo de mudanças DNS
cat > /tmp/dns-validation-changes.json << EOF
{
    "Changes": []
}
EOF

# Processar cada registro de validação
echo "$VALIDATION_RECORDS" | jq -r '.[] | @base64' | while IFS= read -r record; do
    RECORD_DATA=$(echo "$record" | base64 -d)
    RECORD_NAME=$(echo "$RECORD_DATA" | jq -r '.Name')
    RECORD_VALUE=$(echo "$RECORD_DATA" | jq -r '.Value')
    
    # Adicionar registro CNAME de validação
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --change-batch "{
            \"Changes\": [{
                \"Action\": \"CREATE\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$RECORD_NAME\",
                    \"Type\": \"CNAME\",
                    \"TTL\": 300,
                    \"ResourceRecords\": [{\"Value\": \"$RECORD_VALUE\"}]
                }
            }]
        }" > /dev/null
    
    echo -e "${GREEN}✅ Registro DNS criado: $RECORD_NAME${NC}"
done

echo -e "${YELLOW}Passo 4: Aguardando validação do certificado...${NC}"
echo "Isso pode levar alguns minutos..."

# Aguardar validação do certificado
aws acm wait certificate-validated \
    --certificate-arn "$CERT_ARN" \
    --region $REGION

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Certificado validado com sucesso!${NC}"
else
    echo -e "${RED}❌ Timeout na validação do certificado${NC}"
    echo "Verifique manualmente o status no console AWS"
    exit 1
fi

echo -e "${YELLOW}Passo 5: Atualizando listener HTTPS do ALB...${NC}"

# Atualizar listener HTTPS com novo certificado
aws elbv2 modify-listener \
    --listener-arn "$HTTPS_LISTENER_ARN" \
    --certificates CertificateArn="$CERT_ARN" \
    --region $REGION > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Listener HTTPS atualizado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro ao atualizar listener HTTPS${NC}"
    exit 1
fi

echo -e "${YELLOW}Passo 6: Testando configuração...${NC}"

# Aguardar propagação
echo "Aguardando propagação das mudanças..."
sleep 30

# Testar HTTPS
echo "Testando HTTPS..."
if curl -s -f "https://formacao.app-bia.com.br/api/versao" > /dev/null; then
    echo -e "${GREEN}✅ HTTPS funcionando perfeitamente!${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS ainda não está funcionando. Aguarde alguns minutos para propagação.${NC}"
fi

# Testar redirecionamento HTTP -> HTTPS
echo "Testando redirecionamento HTTP -> HTTPS..."
REDIRECT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://formacao.app-bia.com.br/api/versao")
if [ "$REDIRECT_STATUS" = "301" ]; then
    echo -e "${GREEN}✅ Redirecionamento HTTP -> HTTPS configurado!${NC}"
else
    echo -e "${YELLOW}⚠️  Redirecionamento retornou status: $REDIRECT_STATUS${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Configuração concluída!${NC}"
echo "=================================================="
echo "URLs disponíveis:"
echo "• HTTPS: https://formacao.app-bia.com.br"
echo "• HTTP (redireciona): http://formacao.app-bia.com.br"
echo ""
echo "Certificado ARN: $CERT_ARN"
echo ""
echo -e "${YELLOW}Nota: Se o HTTPS ainda não estiver funcionando, aguarde alguns minutos para propagação DNS.${NC}"
