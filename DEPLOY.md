# 🚀 Script de Deploy ECS - Projeto BIA

Este script automatiza o processo de deploy da aplicação BIA no Amazon ECS, incluindo funcionalidades de rollback baseadas em commit hash.

## ✨ Funcionalidades

- **Build automatizado** com tag baseada no commit hash (7 caracteres)
- **Deploy para ECS** com criação automática de task definitions
- **Rollback simples** para versões anteriores
- **Monitoramento** do status do deployment
- **Listagem** de versões disponíveis
- **Dry run** para simular deployments
- **Logs coloridos** para melhor visualização

## 📋 Pré-requisitos

- Docker instalado e configurado
- AWS CLI configurado com credenciais válidas
- Git (para obter hash dos commits)
- jq (para manipulação de JSON)
- Permissões AWS para ECS, ECR e CloudWatch

## 🎯 Comandos Disponíveis

### Deploy Normal
```bash
./deploy.sh deploy
```

### Deploy com Simulação (Dry Run)
```bash
./deploy.sh deploy --dry-run
```

### Deploy Pulando Build (usa imagem existente)
```bash
./deploy.sh deploy --skip-build
```

### Deploy Forçado (ignora mudanças não commitadas)
```bash
./deploy.sh deploy --force
```

### Rollback para Versão Específica
```bash
./deploy.sh rollback a1b2c3d
```

### Listar Versões Disponíveis
```bash
./deploy.sh list
```

### Ver Status do Serviço
```bash
./deploy.sh status
```

### Ajuda
```bash
./deploy.sh help
```

## 🔄 Fluxo de Deploy

1. **Verificação**: Dependências e status do Git
2. **Hash do Commit**: Obtém os últimos 7 caracteres do commit atual
3. **Build**: Constrói imagem Docker com tag do commit
4. **Push**: Envia imagem para ECR
5. **Task Definition**: Cria nova task definition com a imagem
6. **Update Service**: Atualiza o serviço ECS
7. **Monitoramento**: Acompanha o status do deployment

## 🎨 Exemplos de Uso

### Cenário 1: Deploy de Nova Funcionalidade
```bash
# Fazer commit das mudanças
git add .
git commit -m "Nova funcionalidade: botão adicionar tarefa"

# Deploy
./deploy.sh deploy
```

### Cenário 2: Rollback de Emergência
```bash
# Ver versões disponíveis
./deploy.sh list

# Fazer rollback para versão anterior
./deploy.sh rollback a1b2c3d
```

### Cenário 3: Teste de Deploy
```bash
# Simular deploy sem executar
./deploy.sh deploy --dry-run
```

## 📊 Saída do Script

O script fornece logs coloridos para facilitar o acompanhamento:

- 🔵 **INFO**: Informações gerais
- 🟢 **SUCCESS**: Operações bem-sucedidas  
- 🟡 **WARNING**: Avisos importantes
- 🔴 **ERROR**: Erros que impedem a execução

## 🔧 Configurações

As configurações principais estão no início do script:

```bash
REGION="us-east-1"
CLUSTER_NAME="cluster-bia"
SERVICE_NAME="service-bia"
TASK_FAMILY="task-def-bia"
ECR_REPOSITORY="098978302313.dkr.ecr.us-east-1.amazonaws.com/bia"
CONTAINER_NAME="bia"
```

## 🚨 Troubleshooting

### Erro: "Dependências não encontradas"
Instale as dependências necessárias:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io awscli git jq

# Amazon Linux
sudo yum update
sudo yum install docker aws-cli git jq
```

### Erro: "Imagem não encontrada no ECR"
Para rollback, certifique-se de que a versão existe:
```bash
./deploy.sh list
```

### Erro: "Mudanças não commitadas"
Faça commit das mudanças ou use `--force`:
```bash
git add .
git commit -m "Suas mudanças"
# ou
./deploy.sh deploy --force
```

### Timeout no Monitoramento
Verifique manualmente o status:
```bash
./deploy.sh status
```

## 🔐 Segurança

- O script não expõe credenciais AWS
- Usa roles IAM para autenticação
- Logs não contêm informações sensíveis
- Validações de entrada para prevenir erros

## 📈 Monitoramento

Após o deploy, você pode monitorar:

- **CloudWatch Logs**: `/ecs/task-def-bia`
- **ECS Console**: Status do serviço e tasks
- **ECR Console**: Imagens disponíveis

## 🤝 Contribuição

Para melhorar o script:

1. Teste suas mudanças com `--dry-run`
2. Documente novas funcionalidades
3. Mantenha compatibilidade com versões anteriores

## 📝 Changelog

### v1.0
- Deploy automatizado com commit hash
- Funcionalidade de rollback
- Monitoramento de deployment
- Dry run e skip build
- Logs coloridos
- Listagem de versões
