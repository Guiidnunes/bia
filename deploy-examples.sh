#!/bin/bash

# Exemplos Práticos do Script de Deploy - Projeto BIA
# Este arquivo contém exemplos de uso do script deploy.sh

echo "🚀 Exemplos Práticos do Script de Deploy BIA"
echo "=============================================="
echo ""

echo "1. DEPLOY NORMAL (após fazer commit)"
echo "   git add ."
echo "   git commit -m 'Nova funcionalidade'"
echo "   ./deploy.sh deploy"
echo ""

echo "2. SIMULAR DEPLOY (sem executar)"
echo "   ./deploy.sh deploy --dry-run"
echo ""

echo "3. DEPLOY SEM BUILD (usar imagem existente)"
echo "   ./deploy.sh deploy --skip-build"
echo ""

echo "4. DEPLOY FORÇADO (ignorar mudanças não commitadas)"
echo "   ./deploy.sh deploy --force"
echo ""

echo "5. VER STATUS ATUAL DO SERVIÇO"
echo "   ./deploy.sh status"
echo ""

echo "6. LISTAR VERSÕES DISPONÍVEIS"
echo "   ./deploy.sh list"
echo ""

echo "7. ROLLBACK PARA VERSÃO ANTERIOR"
echo "   ./deploy.sh list                    # Ver versões"
echo "   ./deploy.sh rollback a1b2c3d        # Rollback"
echo ""

echo "8. WORKFLOW COMPLETO DE DESENVOLVIMENTO"
echo "   # Desenvolvimento"
echo "   git add ."
echo "   git commit -m 'Fix: correção de bug'"
echo "   "
echo "   # Teste do deploy"
echo "   ./deploy.sh deploy --dry-run"
echo "   "
echo "   # Deploy real"
echo "   ./deploy.sh deploy"
echo "   "
echo "   # Verificar status"
echo "   ./deploy.sh status"
echo ""

echo "9. CENÁRIO DE ROLLBACK DE EMERGÊNCIA"
echo "   # Ver versões disponíveis"
echo "   ./deploy.sh list"
echo "   "
echo "   # Rollback imediato"
echo "   ./deploy.sh rollback a1b2c3d"
echo "   "
echo "   # Confirmar rollback"
echo "   ./deploy.sh status"
echo ""

echo "10. AJUDA E DOCUMENTAÇÃO"
echo "    ./deploy.sh help"
echo "    cat DEPLOY.md"
echo ""

echo "💡 DICAS:"
echo "   - Sempre faça commit antes do deploy"
echo "   - Use --dry-run para testar"
echo "   - Mantenha o histórico de commits limpo"
echo "   - Monitore os logs no CloudWatch"
echo ""
