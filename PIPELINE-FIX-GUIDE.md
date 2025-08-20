# Guia de Correção da Pipeline BIA

## Problema Identificado
A pipeline está falhando por falta de permissões para fazer deploy no ECS. A role do CodeBuild não tem permissões suficientes para atualizar o serviço ECS.

## Status Atual
- ✅ **ECS Service**: Funcionando (2/2 tasks rodando)
- ✅ **ECR Repository**: Ativo com imagens recentes
- ✅ **CodeBuild Project**: Configurado
- ❌ **Permissões IAM**: Insuficientes para deploy ECS

## Soluções Implementadas

### 1. Buildspec.yml Atualizado
- ✅ Adicionado deploy automático no ECS
- ✅ Comando para forçar nova implantação
- ✅ Aguarda estabilização do serviço

### 2. Scripts Criados

#### `fix-iam-permissions.sh`
**Execução necessária por usuário com permissões administrativas**
```bash
./fix-iam-permissions.sh
```
Este script:
- Cria política customizada para ECS
- Anexa política à role do CodeBuild
- Adiciona política AWS gerenciada para ECS

#### `test-pipeline.sh`
**Teste local da pipeline**
```bash
./test-pipeline.sh
```
Este script testa:
- Login no ECR
- Build da imagem Docker
- Permissões ECS

#### `check-pipeline-status.sh`
**Verificação do status atual**
```bash
./check-pipeline-status.sh
```
Este script mostra:
- Status do serviço ECS
- Últimas imagens no ECR
- Políticas anexadas à role

## Passos para Resolver

### Passo 1: Aplicar Permissões IAM
```bash
# Execute com usuário administrativo
./fix-iam-permissions.sh
```

### Passo 2: Testar Localmente
```bash
# Teste a pipeline localmente
./test-pipeline.sh
```

### Passo 3: Commit das Mudanças
```bash
git add buildspec.yml
git commit -m "fix: adicionar deploy automático no ECS"
git push origin main
```

### Passo 4: Verificar Status
```bash
# Monitore o status
./check-pipeline-status.sh
```

## Permissões IAM Necessárias

A role `codebuild-bia-build-service-role` precisa das seguintes permissões:

### Política Customizada (CodeBuildECSDeployPolicy)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateService",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:RegisterTaskDefinition",
                "ecs:ListTasks",
                "ecs:DescribeTasks"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": [
                "arn:aws:iam::098978302313:role/ecsTaskExecutionRole",
                "arn:aws:iam::098978302313:role/*"
            ]
        }
    ]
}
```

### Política AWS Gerenciada
- `AmazonECS_FullAccess`

## Verificação de Sucesso

Após aplicar as correções, a pipeline deve:

1. ✅ Fazer build da imagem Docker
2. ✅ Push para ECR com sucesso
3. ✅ Executar deploy no ECS sem erros
4. ✅ Aguardar estabilização do serviço
5. ✅ Completar sem falhas

## Troubleshooting

### Se ainda houver erros:

1. **Verificar logs detalhados:**
```bash
aws logs filter-log-events --log-group-name '/aws/codebuild/bia-build' --start-time $(date -d '1 hour ago' +%s)000 --region us-east-1
```

2. **Verificar políticas anexadas:**
```bash
aws iam list-attached-role-policies --role-name codebuild-bia-build-service-role
```

3. **Verificar status do ECS:**
```bash
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb
```

## Contato
Para dúvidas ou problemas adicionais, verifique os logs específicos e compare com as permissões necessárias listadas acima.
