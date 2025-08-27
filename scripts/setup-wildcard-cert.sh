#!/bin/bash

# Script para configurar certificado wildcard
# Execute com permissões de administrador

echo "🔐 Configurando Certificado Wildcard para *.app-bia.com.br"
echo "========================================================="

# Variáveis
DOMAIN="*.app-bia.com.br"
ROOT_DOMAIN="app-bia.com.br"
REGION="us-east-1"
HTTPS_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:098978302313:listener/app/bia-alb/7ba22f1baf624a69/5b383175b339ecad"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Solicitando certificado wildcard...${NC}"

# Solicitar certificado
CERT_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN" \
    --subject-alternative-names "$ROOT_DOMAIN" \
    --validation-method DNS \
    --region $REGION \
    --query 'CertificateArn' \
    --output text 2>/dev/null)

if [ $? -eq 0 ] && [ "$CERT_ARN" != "None" ]; then
    echo -e "${GREEN}✅ Certificado solicitado: $CERT_ARN${NC}"
    
    echo -e "${YELLOW}Aguardando informações de validação...${NC}"
    sleep 10
    
    # Mostrar registros de validação
    echo -e "${YELLOW}Registros DNS para validação:${NC}"
    aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region $REGION \
        --query 'Certificate.DomainValidationOptions[*].[DomainName,ResourceRecord.Name,ResourceRecord.Value]' \
        --output table
    
    echo ""
    echo -e "${YELLOW}Criando registros DNS automaticamente...${NC}"
    
    # Criar registros DNS de validação
    VALIDATION_DATA=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region $REGION \
        --query 'Certificate.DomainValidationOptions[*].ResourceRecord' \
        --output json)
    
    echo "$VALIDATION_DATA" | jq -r '.[] | @base64' | while read record; do
        RECORD_JSON=$(echo "$record" | base64 -d)
        RECORD_NAME=$(echo "$RECORD_JSON" | jq -r '.Name')
        RECORD_VALUE=$(echo "$RECORD_JSON" | jq -r '.Value')
        
        aws route53 change-resource-record-sets \
            --hosted-zone-id "Z02081913KGKPZCXJP1VP" \
            --change-batch "{
                \"Changes\": [{
                    \"Action\": \"UPSERT\",
                    \"ResourceRecordSet\": {
                        \"Name\": \"$RECORD_NAME\",
                        \"Type\": \"CNAME\",
                        \"TTL\": 300,
                        \"ResourceRecords\": [{\"Value\": \"$RECORD_VALUE\"}]
                    }
                }]
            }" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Registro DNS criado: $RECORD_NAME${NC}"
        fi
    done
    
    echo -e "${YELLOW}Aguardando validação do certificado (isso pode levar alguns minutos)...${NC}"
    
    # Aguardar validação
    timeout 600 aws acm wait certificate-validated \
        --certificate-arn "$CERT_ARN" \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Certificado validado com sucesso!${NC}"
        
        # Atualizar listener HTTPS
        echo -e "${YELLOW}Atualizando listener HTTPS...${NC}"
        aws elbv2 modify-listener \
            --listener-arn "$HTTPS_LISTENER_ARN" \
            --certificates CertificateArn="$CERT_ARN" \
            --region $REGION > /dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Listener HTTPS atualizado!${NC}"
            
            echo -e "${YELLOW}Aguardando propagação...${NC}"
            sleep 30
            
            # Testar HTTPS
            if curl -s -f "https://formacao.app-bia.com.br/api/versao" > /dev/null 2>&1; then
                echo -e "${GREEN}🎉 HTTPS funcionando perfeitamente!${NC}"
            else
                echo -e "${YELLOW}⚠️  HTTPS ainda propagando. Teste novamente em alguns minutos.${NC}"
            fi
        else
            echo -e "${RED}❌ Erro ao atualizar listener${NC}"
        fi
    else
        echo -e "${RED}❌ Timeout na validação do certificado${NC}"
        echo "Verifique o status no console AWS ACM"
    fi
    
else
    echo -e "${RED}❌ Erro ao solicitar certificado${NC}"
    echo "Execute este script com permissões de administrador AWS"
fi

echo ""
echo "📋 Status Final:"
echo "• HTTP → HTTPS redirect: ✅ Configurado"
echo "• Certificado wildcard: Execute com permissões adequadas"
echo "• URLs de teste:"
echo "  - http://formacao.app-bia.com.br (redireciona)"
echo "  - https://bia-alb-1126663415.us-east-1.elb.amazonaws.com (funciona)"
