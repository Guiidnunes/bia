# Configuração HTTPS com Certificado Wildcard

## Status Atual ✅
- ✅ **Redirecionamento HTTP → HTTPS configurado**
- ✅ **ALB configurado corretamente**
- ❌ **Certificado wildcard pendente**

## Passo a Passo para Configurar Certificado Wildcard

### 1. Solicitar Certificado no AWS Console

1. Acesse o **AWS Certificate Manager (ACM)**
2. Clique em **"Request a certificate"**
3. Selecione **"Request a public certificate"**
4. Configure:
   - **Domain name**: `*.app-bia.com.br`
   - **Add another name**: `app-bia.com.br`
   - **Validation method**: DNS validation
   - **Key algorithm**: RSA 2048

### 2. Validar Certificado via DNS

1. Após solicitar, o ACM mostrará registros CNAME para validação
2. Adicione estes registros no Route 53:
   - Acesse **Route 53 → Hosted zones → app-bia.com.br**
   - Crie registros CNAME conforme mostrado no ACM
   - Aguarde validação (pode levar até 30 minutos)

### 3. Atualizar ALB com Novo Certificado

Execute este comando após o certificado ser validado:

```bash
# Substitua NOVO_CERT_ARN pelo ARN do certificado wildcard
aws elbv2 modify-listener \
    --listener-arn "arn:aws:elasticloadbalancing:us-east-1:098978302313:listener/app/bia-alb/7ba22f1baf624a69/5b383175b339ecad" \
    --certificates CertificateArn="NOVO_CERT_ARN" \
    --region us-east-1
```

## Configuração Atual do ALB

### Listeners Configurados:
- **HTTP (80)**: Redireciona para HTTPS ✅
- **HTTPS (443)**: Certificado atual (app-bia.com.br apenas)

### URLs Funcionais:
- ✅ `http://formacao.app-bia.com.br` → Redireciona para HTTPS
- ✅ `https://bia-alb-1126663415.us-east-1.elb.amazonaws.com`
- ❌ `https://formacao.app-bia.com.br` → Erro de certificado

## Solução Temporária

Enquanto o certificado wildcard não está configurado, você pode:

1. **Usar o DNS direto do ALB**:
   ```
   https://bia-alb-1126663415.us-east-1.elb.amazonaws.com
   ```

2. **Aceitar o aviso de certificado** no navegador para `https://formacao.app-bia.com.br`

## Comandos de Teste

```bash
# Testar redirecionamento HTTP → HTTPS
curl -I "http://formacao.app-bia.com.br/api/versao"

# Testar HTTPS (ignorando certificado)
curl -k "https://formacao.app-bia.com.br/api/versao"

# Testar HTTPS direto no ALB
curl "https://bia-alb-1126663415.us-east-1.elb.amazonaws.com/api/versao"
```

## Próximos Passos

1. **Solicitar certificado wildcard** no AWS Console
2. **Validar via DNS** no Route 53
3. **Atualizar listener HTTPS** com novo certificado
4. **Testar HTTPS** em `https://formacao.app-bia.com.br`

## Informações Técnicas

- **ALB ARN**: `arn:aws:elasticloadbalancing:us-east-1:098978302313:loadbalancer/app/bia-alb/7ba22f1baf624a69`
- **HTTPS Listener ARN**: `arn:aws:elasticloadbalancing:us-east-1:098978302313:listener/app/bia-alb/7ba22f1baf624a69/5b383175b339ecad`
- **Hosted Zone ID**: `Z02081913KGKPZCXJP1VP`
- **Domínio**: `formacao.app-bia.com.br`
