#!/bin/bash

if [ -z "$1" ]; then
    echo "Uso: $0 <CERTIFICATE_ARN>"
    echo "Exemplo: $0 arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    exit 1
fi

CERT_ARN="$1"
HOSTED_ZONE_ID="Z02081913KGKPZCXJP1VP"

echo "=== Criando registros DNS de validação ==="
echo "Certificado: $CERT_ARN"
echo "Zona hospedada: $HOSTED_ZONE_ID"

# Obter informações de validação DNS
VALIDATION_INFO=$(aws acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[*].[ResourceRecord.Name,ResourceRecord.Value]' \
  --output text)

# Criar registros DNS para cada domínio
echo "$VALIDATION_INFO" | while read -r NAME VALUE; do
    if [ -n "$NAME" ] && [ -n "$VALUE" ]; then
        echo "Criando registro DNS:"
        echo "  Nome: $NAME"
        echo "  Valor: $VALUE"
        
        # Criar arquivo JSON temporário para o registro
        cat > /tmp/dns-record.json << EOF
{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$NAME",
                "Type": "CNAME",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "$VALUE"
                    }
                ]
            }
        }
    ]
}
EOF

        # Criar o registro DNS
        CHANGE_ID=$(aws route53 change-resource-record-sets \
          --hosted-zone-id "$HOSTED_ZONE_ID" \
          --change-batch file:///tmp/dns-record.json \
          --query 'ChangeInfo.Id' \
          --output text)
        
        echo "  Registro criado. Change ID: $CHANGE_ID"
        echo ""
    fi
done

echo "=== Verificando status da validação ==="
aws acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --region us-east-1 \
  --query 'Certificate.{Status:Status,DomainValidationOptions:DomainValidationOptions[*].{Domain:DomainName,Status:ValidationStatus}}' \
  --output table

echo ""
echo "A validação pode levar alguns minutos. Execute o comando abaixo para verificar:"
echo "aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.Status'"
