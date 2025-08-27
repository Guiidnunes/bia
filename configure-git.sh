#!/bin/bash

echo "=== Configuração Git para Projeto BIA ==="
echo ""

# Verificar se o token foi fornecido
if [ -z "$1" ]; then
    echo "❌ Erro: Token não fornecido!"
    echo "Uso: ./configure-git.sh SEU_TOKEN_AQUI"
    echo ""
    echo "Para gerar um token:"
    echo "1. Vá para: https://github.com/settings/tokens/new"
    echo "2. Marque os scopes: repo e workflow"
    echo "3. Copie o token gerado"
    exit 1
fi

TOKEN=$1
REPO_URL="https://${TOKEN}@github.com/Guiidnunes/bia.git"

echo "🔧 Configurando remote com token..."
git remote set-url origin "$REPO_URL"

echo "✅ Remote configurado!"
echo ""

echo "🔍 Verificando configuração..."
git remote -v | grep origin

echo ""
echo "📤 Testando push..."
git push origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Sucesso! Push realizado com sucesso!"
    echo "✅ Repositório configurado e sincronizado"
else
    echo ""
    echo "❌ Erro no push. Verifique o token e tente novamente."
fi
