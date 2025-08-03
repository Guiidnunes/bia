#!/bin/bash

# Script de Deploy para ECS - Projeto BIA
# Autor: Amazon Q
# Versão: 1.0

set -e

# Configurações
REGION="us-east-1"
CLUSTER_NAME="cluster-bia-alb"
SERVICE_NAME="service-bia-alb"
TASK_FAMILY="task-def-bia-alb"
ECR_REPOSITORY="098978302313.dkr.ecr.us-east-1.amazonaws.com/bia"
CONTAINER_NAME="bia"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir mensagens coloridas
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função de ajuda
show_help() {
    cat << EOF
🚀 Script de Deploy ECS - Projeto BIA

USAGE:
    ./deploy.sh [COMMAND] [OPTIONS]

COMMANDS:
    deploy              Faz build e deploy da aplicação
    rollback <hash>     Faz rollback para uma versão específica
    list                Lista as últimas 10 versões disponíveis
    status              Mostra status atual do serviço
    help                Mostra esta ajuda

OPTIONS:
    --dry-run           Simula o deploy sem executar (apenas para deploy)
    --skip-build        Pula a etapa de build (usa imagem existente)
    --force             Força o deploy mesmo se não houver mudanças

EXAMPLES:
    ./deploy.sh deploy                    # Deploy normal
    ./deploy.sh deploy --dry-run          # Simula o deploy
    ./deploy.sh deploy --skip-build       # Deploy sem build
    ./deploy.sh rollback a1b2c3d          # Rollback para commit a1b2c3d
    ./deploy.sh list                      # Lista versões disponíveis
    ./deploy.sh status                    # Status do serviço

WORKFLOW:
    1. Obtém hash do commit atual (7 caracteres)
    2. Faz build da imagem Docker com tag do commit
    3. Faz push para ECR
    4. Cria nova task definition
    5. Atualiza o serviço ECS
    6. Monitora o deploy

ROLLBACK:
    Para fazer rollback, use o hash do commit desejado:
    ./deploy.sh rollback a1b2c3d

    Para ver versões disponíveis:
    ./deploy.sh list

EOF
}

# Função para verificar dependências
check_dependencies() {
    local deps=("docker" "aws" "git" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Dependências não encontradas: ${missing[*]}"
        log_info "Instale as dependências necessárias antes de continuar"
        exit 1
    fi
}

# Função para verificar se estamos em um repositório git
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Este não é um repositório Git válido"
        exit 1
    fi
}

# Função para obter hash do commit
get_commit_hash() {
    local hash=$(git rev-parse --short=7 HEAD)
    echo "$hash"
}

# Função para verificar se há mudanças não commitadas
check_git_status() {
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "Há mudanças não commitadas no repositório"
        if [ "$FORCE" != "true" ]; then
            log_error "Use --force para continuar mesmo assim"
            exit 1
        fi
    fi
}

# Função para fazer login no ECR
ecr_login() {
    log_info "Fazendo login no ECR..."
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY
}

# Função para build da imagem
build_image() {
    local commit_hash=$1
    local image_tag="$ECR_REPOSITORY:$commit_hash"
    
    log_info "Fazendo build da imagem com tag: $commit_hash"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "[DRY RUN] docker build -t $image_tag ."
        return 0
    fi
    
    docker build -t "$image_tag" .
    docker tag "$image_tag" "$ECR_REPOSITORY:latest"
    
    log_success "Build concluído: $image_tag"
}

# Função para push da imagem
push_image() {
    local commit_hash=$1
    local image_tag="$ECR_REPOSITORY:$commit_hash"
    
    log_info "Fazendo push da imagem para ECR..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "[DRY RUN] docker push $image_tag"
        log_warning "[DRY RUN] docker push $ECR_REPOSITORY:latest"
        return 0
    fi
    
    docker push "$image_tag"
    docker push "$ECR_REPOSITORY:latest"
    
    log_success "Push concluído: $image_tag"
}

# Função para verificar se imagem existe no ECR
check_image_exists() {
    local commit_hash=$1
    
    log_info "Verificando se imagem existe no ECR: $commit_hash"
    
    if aws ecr describe-images --repository-name "bia" --image-ids imageTag="$commit_hash" --region $REGION &>/dev/null; then
        log_success "Imagem encontrada no ECR: $commit_hash"
        return 0
    else
        log_error "Imagem não encontrada no ECR: $commit_hash"
        return 1
    fi
}

# Função para obter task definition atual
get_current_task_definition() {
    aws ecs describe-task-definition \
        --task-definition "$TASK_FAMILY" \
        --region $REGION \
        --query 'taskDefinition' \
        --output json
}

# Função para criar nova task definition
create_task_definition() {
    local commit_hash=$1
    local image_uri="$ECR_REPOSITORY:$commit_hash"
    
    log_info "Criando nova task definition com imagem: $commit_hash"
    
    # Obter task definition atual
    local current_task_def=$(get_current_task_definition)
    
    # Criar nova task definition com a nova imagem
    local new_task_def=$(echo "$current_task_def" | jq --arg image "$image_uri" '
        .containerDefinitions[0].image = $image |
        del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy, .enableFaultInjection)
    ')
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "[DRY RUN] Criaria nova task definition com imagem: $image_uri"
        return 0
    fi
    
    # Registrar nova task definition
    local result=$(aws ecs register-task-definition \
        --region $REGION \
        --cli-input-json "$new_task_def")
    
    local new_revision=$(echo "$result" | jq -r '.taskDefinition.revision')
    
    log_success "Nova task definition criada: $TASK_FAMILY:$new_revision"
    echo "$new_revision"
}

# Função para atualizar serviço ECS
update_service() {
    local task_revision=$1
    local task_definition="$TASK_FAMILY:$task_revision"
    
    log_info "Atualizando serviço ECS com task definition: $task_definition"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "[DRY RUN] Atualizaria serviço com: $task_definition"
        return 0
    fi
    
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --task-definition "$task_definition" \
        --region $REGION \
        --output table
    
    log_success "Serviço atualizado com sucesso"
}

# Função para monitorar deploy
monitor_deployment() {
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "[DRY RUN] Monitoraria o deployment"
        return 0
    fi
    
    log_info "Monitorando deployment..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local status=$(aws ecs describe-services \
            --cluster "$CLUSTER_NAME" \
            --services "$SERVICE_NAME" \
            --region $REGION \
            --query 'services[0].deployments[0].rolloutState' \
            --output text)
        
        case $status in
            "COMPLETED")
                log_success "Deploy concluído com sucesso!"
                return 0
                ;;
            "FAILED")
                log_error "Deploy falhou!"
                return 1
                ;;
            "IN_PROGRESS")
                log_info "Deploy em progresso... (tentativa $((attempt + 1))/$max_attempts)"
                ;;
            *)
                log_info "Status: $status (tentativa $((attempt + 1))/$max_attempts)"
                ;;
        esac
        
        sleep 10
        ((attempt++))
    done
    
    log_warning "Timeout no monitoramento. Verifique o status manualmente."
    return 1
}

# Função para listar versões disponíveis
list_versions() {
    log_info "Listando últimas 10 versões disponíveis no ECR:"
    
    aws ecr describe-images \
        --repository-name "bia" \
        --region $REGION \
        --query 'sort_by(imageDetails,&imagePushedAt)[-10:].[imageDigest,imageTags[0],imagePushedAt]' \
        --output table
}

# Função para mostrar status do serviço
show_status() {
    log_info "Status atual do serviço ECS:"
    
    aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --region $REGION \
        --query 'services[0].{
            ServiceName: serviceName,
            Status: status,
            RunningCount: runningCount,
            DesiredCount: desiredCount,
            TaskDefinition: taskDefinition,
            LastDeployment: deployments[0].{
                Status: status,
                CreatedAt: createdAt,
                UpdatedAt: updatedAt
            }
        }' \
        --output table
}

# Função principal de deploy
deploy() {
    log_info "🚀 Iniciando deploy do projeto BIA"
    
    check_dependencies
    check_git_repo
    check_git_status
    
    local commit_hash=$(get_commit_hash)
    log_info "Hash do commit atual: $commit_hash"
    
    if [ "$SKIP_BUILD" != "true" ]; then
        ecr_login
        build_image "$commit_hash"
        push_image "$commit_hash"
    else
        log_info "Pulando build (--skip-build ativado)"
        if ! check_image_exists "$commit_hash"; then
            log_error "Imagem não existe no ECR. Execute sem --skip-build"
            exit 1
        fi
    fi
    
    local new_revision=$(create_task_definition "$commit_hash")
    
    if [ "$DRY_RUN" != "true" ]; then
        update_service "$new_revision"
        monitor_deployment
        
        log_success "✅ Deploy concluído com sucesso!"
        log_info "Versão deployada: $commit_hash"
        log_info "Task Definition: $TASK_FAMILY:$new_revision"
    else
        log_warning "🔍 DRY RUN concluído - nenhuma alteração foi feita"
    fi
}

# Função de rollback
rollback() {
    local target_hash=$1
    
    if [ -z "$target_hash" ]; then
        log_error "Hash do commit é obrigatório para rollback"
        log_info "Use: ./deploy.sh rollback <hash>"
        log_info "Para ver versões disponíveis: ./deploy.sh list"
        exit 1
    fi
    
    log_info "🔄 Iniciando rollback para versão: $target_hash"
    
    check_dependencies
    
    if ! check_image_exists "$target_hash"; then
        log_error "Versão não encontrada no ECR: $target_hash"
        log_info "Versões disponíveis:"
        list_versions
        exit 1
    fi
    
    local new_revision=$(create_task_definition "$target_hash")
    update_service "$new_revision"
    monitor_deployment
    
    log_success "✅ Rollback concluído com sucesso!"
    log_info "Versão atual: $target_hash"
    log_info "Task Definition: $TASK_FAMILY:$new_revision"
}

# Parse dos argumentos
COMMAND=""
DRY_RUN="false"
SKIP_BUILD="false"
FORCE="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        deploy|rollback|list|status|help)
            COMMAND=$1
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --skip-build)
            SKIP_BUILD="true"
            shift
            ;;
        --force)
            FORCE="true"
            shift
            ;;
        -h|--help)
            COMMAND="help"
            shift
            ;;
        *)
            if [ "$COMMAND" = "rollback" ] && [ -z "$ROLLBACK_HASH" ]; then
                ROLLBACK_HASH=$1
            else
                log_error "Argumento desconhecido: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Executar comando
case $COMMAND in
    deploy)
        deploy
        ;;
    rollback)
        rollback "$ROLLBACK_HASH"
        ;;
    list)
        list_versions
        ;;
    status)
        show_status
        ;;
    help|"")
        show_help
        ;;
    *)
        log_error "Comando inválido: $COMMAND"
        show_help
        exit 1
        ;;
esac
