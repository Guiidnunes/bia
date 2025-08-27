#!/bin/bash

echo "=== Criando certificado wildcard para *.app-bia.com.br ==="

# Solicitar certificado wildcard
CERT_ARN=$(aws acm request-certificate \
  --domain-name "*.app-bia.com.br" \
  --subject-alternative-names "app-bia.com.br" \
  --validation-method DNS \
  --key-algorithm RSA_2048 \
  --region us-east-1 \
  --query 'CertificateArn' \
  --output text)

echo "Certificado solicitado: $CERT_ARN"

# Aguardar um momento para o certificado ser processado
echo "Aguardando processamento do certificado..."
sleep 10

# Obter informações de validação DNS
echo "=== Informações de validação DNS ==="
aws acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,Name:ResourceRecord.Name,Value:ResourceRecord.Value,Type:ResourceRecord.Type}' \
  --output table

echo ""
echo "ARN do novo certificado: $CERT_ARN"
echo ""
echo "Execute o próximo script para criar os registros DNS automaticamente."
