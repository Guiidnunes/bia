#!/bin/bash

if [ -z "$1" ]; then
    echo "Uso: $0 <CERTIFICATE_ARN>"
    exit 1
fi

NEW_CERT_ARN="$1"
LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:098978302313:listener/app/bia-alb/7ba22f1baf624a69/5b383175b339ecad"

echo "=== Atualizando certificado no ALB ==="
echo "Novo certificado: $NEW_CERT_ARN"
echo "Listener: $LISTENER_ARN"

# Atualizar o listener com o novo certificado
aws elbv2 modify-listener \
  --listener-arn "$LISTENER_ARN" \
  --certificates CertificateArn="$NEW_CERT_ARN" \
  --region us-east-1

echo "Certificado atualizado no ALB!"
echo ""
echo "Testando conectividade HTTPS..."
sleep 5
curl -I https://formacao.app-bia.com.br
