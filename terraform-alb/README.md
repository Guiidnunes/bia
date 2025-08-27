# Terraform ALB - Projeto BIA

Este diretório contém a configuração Terraform para gerenciar o Application Load Balancer (ALB) do projeto BIA de forma independente, permitindo economizar créditos AWS através de destroy/apply quando necessário.

## 🎯 Objetivo

Permitir que você possa:
- **Destruir** o ALB quando não estiver usando (economizar créditos)
- **Recriar** o ALB rapidamente quando precisar
- Manter a configuração idêntica à infraestrutura atual

## 📁 Estrutura dos Arquivos

- `main.tf` - Recursos principais (ALB, Target Group, Listeners, Security Group)
- `variables.tf` - Definição das variáveis
- `terraform.tfvars` - Valores específicos do seu ambiente
- `outputs.tf` - Outputs importantes (DNS, ARNs, etc.)

## 🚀 Como Usar

### 1. Inicializar o Terraform
```bash
cd /home/ec2-user/bia/terraform-alb
terraform init
```

### 2. Verificar o que será criado
```bash
terraform plan
```

### 3. Aplicar a configuração (criar ALB)
```bash
terraform apply
```

### 4. Destruir o ALB (economizar créditos)
```bash
terraform destroy
```

## ⚠️ Importante - Segurança

### Antes de Destruir
1. **Verifique se o ECS Service não está rodando**
2. **Confirme que não há tráfego ativo**
3. **Anote o DNS name atual se necessário**

### Antes de Aplicar
1. **Confirme que o certificado SSL ainda existe**
2. **Verifique se as subnets estão disponíveis**
3. **Certifique-se que a VPC está ativa**

## 🔧 Configuração Atual

O Terraform está configurado para recriar exatamente:

- **ALB Name:** bia-alb
- **Target Group:** tg-bia
- **Security Group:** bia-alb
- **Listeners:** HTTP (80) → HTTPS redirect, HTTPS (443)
- **SSL Certificate:** Certificado existente no ACM
- **Health Check:** Path "/" com configurações padrão

## 📊 Outputs Importantes

Após aplicar, você terá acesso a:
- DNS name do ALB
- ARN do Target Group (para configurar no ECS)
- ID do Security Group
- ARNs dos Listeners

## 🔄 Integração com ECS

Após aplicar o Terraform, você precisará:
1. Atualizar o ECS Service para usar o novo Target Group ARN
2. Verificar se o Security Group do ECS permite tráfego do ALB
3. Testar a conectividade

## 💡 Dicas de Economia

- **Destrua o ALB** quando não estiver desenvolvendo
- **Aplique novamente** apenas quando precisar testar
- O processo de criação leva ~2-3 minutos
- O processo de destruição leva ~1-2 minutos

## 🆘 Troubleshooting

### Erro de Certificado
Se o certificado não for encontrado, verifique se ainda existe:
```bash
aws acm list-certificates --region us-east-1
```

### Erro de Subnet
Se as subnets não forem encontradas, liste as disponíveis:
```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-02e84025586853660"
```

### Erro de VPC
Verifique se a VPC ainda existe:
```bash
aws ec2 describe-vpcs --vpc-ids vpc-02e84025586853660
```
