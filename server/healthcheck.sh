#!/bin/bash

# Script de health check para containers Docker
# Usado pelos Dockerfiles para verificar se os serviços estão saudáveis

PORT=${1:-8080}
SERVICE=${2:-"service"}

# Tentar conectar no endpoint de saúde
response=$(curl -s -f "http://localhost:${PORT}/health" 2>/dev/null)
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "✅ $SERVICE está saudável na porta $PORT"
    exit 0
else
    echo "❌ $SERVICE não está respondendo na porta $PORT"
    exit 1
fi