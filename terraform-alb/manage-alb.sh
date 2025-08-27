#!/bin/bash

# Script para gerenciar o ALB do projeto BIA
# Facilita o processo de destroy/apply para economizar créditos

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Função para exibir ajuda
show_help() {
    echo -e "${BLUE}=== Gerenciador ALB - Projeto BIA ===${NC}"
    echo ""
    echo "Uso: $0 [COMANDO]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  init     - Inicializar Terraform"
    echo "  plan     - Visualizar mudanças"
    echo "  apply    - Criar/Atualizar ALB"
    echo "  destroy  - Destruir ALB (economizar créditos)"
    echo "  status   - Verificar status atual"
    echo "  outputs  - Mostrar outputs do Terraform"
    echo ""
    echo "Exemplos:"
    echo "  $0 apply    # Criar o ALB"
    echo "  $0 destroy  # Destruir o ALB"
    echo "  $0 status   # Ver se ALB existe"
}

# Função para verificar se terraform está instalado
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform não encontrado. Instale o Terraform primeiro.${NC}"
        exit 1
    fi
}

# Função para verificar status do ALB
check_alb_status() {
    echo -e "${BLUE}🔍 Verificando status do ALB...${NC}"
    
    if aws elbv2 describe-load-balancers --names "bia-alb" --region us-east-1 &>/dev/null; then
        echo -e "${GREEN}✅ ALB 'bia-alb' está ATIVO${NC}"
        
        # Mostrar DNS name
        DNS_NAME=$(aws elbv2 describe-load-balancers --names "bia-alb" --region us-east-1 --query 'LoadBalancers[0].DNSName' --output text)
        echo -e "${BLUE}🌐 DNS: ${DNS_NAME}${NC}"
        
        return 0
    else
        echo -e "${YELLOW}⚠️  ALB 'bia-alb' NÃO EXISTE${NC}"
        return 1
    fi
}

# Função para inicializar terraform
terraform_init() {
    echo -e "${BLUE}🚀 Inicializando Terraform...${NC}"
    cd "$SCRIPT_DIR"
    terraform init
    echo -e "${GREEN}✅ Terraform inicializado com sucesso!${NC}"
}

# Função para fazer plan
terraform_plan() {
    echo -e "${BLUE}📋 Executando Terraform Plan...${NC}"
    cd "$SCRIPT_DIR"
    terraform plan
}

# Função para aplicar
terraform_apply() {
    echo -e "${YELLOW}⚠️  ATENÇÃO: Isso irá criar o ALB e começar a cobrar créditos!${NC}"
    echo -e "${BLUE}💰 Custo estimado: ~$16-20/mês se ficar sempre ativo${NC}"
    echo ""
    read -p "Deseja continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🏗️  Criando ALB...${NC}"
        cd "$SCRIPT_DIR"
        terraform apply -auto-approve
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ ALB criado com sucesso!${NC}"
            echo ""
            terraform output
        else
            echo -e "${RED}❌ Erro ao criar ALB${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}❌ Operação cancelada${NC}"
    fi
}

# Função para destruir
terraform_destroy() {
    echo -e "${YELLOW}⚠️  ATENÇÃO: Isso irá DESTRUIR o ALB!${NC}"
    echo -e "${GREEN}💰 Isso irá PARAR a cobrança de créditos${NC}"
    echo ""
    echo -e "${RED}🚨 Certifique-se que:${NC}"
    echo "   - O ECS Service não está rodando"
    echo "   - Não há tráfego ativo"
    echo "   - Você anotou informações importantes"
    echo ""
    read -p "Deseja continuar com a DESTRUIÇÃO? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}💥 Destruindo ALB...${NC}"
        cd "$SCRIPT_DIR"
        terraform destroy -auto-approve
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ ALB destruído com sucesso!${NC}"
            echo -e "${GREEN}💰 Créditos AWS não estão mais sendo cobrados pelo ALB${NC}"
        else
            echo -e "${RED}❌ Erro ao destruir ALB${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}❌ Operação cancelada${NC}"
    fi
}

# Função para mostrar outputs
show_outputs() {
    echo -e "${BLUE}📊 Outputs do Terraform:${NC}"
    cd "$SCRIPT_DIR"
    if [ -f "terraform.tfstate" ]; then
        terraform output
    else
        echo -e "${YELLOW}⚠️  Nenhum state encontrado. Execute 'apply' primeiro.${NC}"
    fi
}

# Main
case "${1:-}" in
    "init")
        check_terraform
        terraform_init
        ;;
    "plan")
        check_terraform
        terraform_plan
        ;;
    "apply")
        check_terraform
        terraform_apply
        ;;
    "destroy")
        check_terraform
        terraform_destroy
        ;;
    "status")
        check_alb_status
        ;;
    "outputs")
        check_terraform
        show_outputs
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Comando inválido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
