#!/bin/bash

# Script de teste automatizado para o sistema distribuído
echo "=== TESTE AUTOMATIZADO DO SISTEMA DISTRIBUÍDO ==="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para verificar se um serviço está rodando
check_service() {
    local port=$1
    local name=$2
    
    if curl -s http://localhost:$port/health >/dev/null 2>&1; then
        log_success "$name está rodando na porta $port"
        return 0
    else
        log_error "$name não está respondendo na porta $port"
        return 1
    fi
}

# Função para testar endpoint específico
test_endpoint() {
    local url=$1
    local expected_code=$2
    local description=$3
    
    log_info "Testando: $description"
    
    response=$(curl -s -w "%{http_code}" -o /tmp/response.txt "$url")
    
    if [ "$response" = "$expected_code" ]; then
        log_success "$description - OK ($response)"
        return 0
    else
        log_error "$description - FALHA ($response)"
        return 1
    fi
}

# Função para testar processamento completo
test_processing() {
    local test_file=$1
    local expected_letters=$2
    local expected_numbers=$3
    
    log_info "Testando processamento completo com $test_file"
    
    if [ ! -f "$test_file" ]; then
        log_error "Arquivo $test_file não encontrado"
        return 1
    fi
    
    if [ ! -f "client/client" ]; then
        log_error "Cliente não compilado. Execute: cd client && make"
        return 1
    fi
    
    # Executar cliente e capturar output
    output=$(./client/client "$test_file" 2>&1)
    exit_code=$?
    
    echo "$output"
    
    if [ $exit_code -eq 0 ]; then
        # Verificar se os números estão corretos
        letters_found=$(echo "$output" | grep "Número de letras:" | grep -o '[0-9]\+')
        numbers_found=$(echo "$output" | grep "Número de números:" | grep -o '[0-9]\+')
        
        if [ "$letters_found" = "$expected_letters" ] && [ "$numbers_found" = "$expected_numbers" ]; then
            log_success "Processamento correto: $letters_found letras, $numbers_found números"
            return 0
        else
            log_warning "Resultado inesperado: esperado $expected_letters letras e $expected_numbers números, obteve $letters_found letras e $numbers_found números"
            return 1
        fi
    else
        log_error "Erro na execução do cliente"
        return 1
    fi
}

# Função para criar arquivos de teste
create_test_files() {
    log_info "Criando arquivos de teste..."
    
    # Arquivo simples
    cat > test_simple.txt << 'EOF'
abc123
EOF
    
    # Arquivo complexo
    cat > test_complex.txt << 'EOF'
Hello World 123!
Esta string tem números: 456, 789.
MAIÚSCULAS: ABC
minúsculas: xyz  
Símbolos: @#$%^&*()
Mais números: 2024
EOF
    
    # Arquivo vazio
    touch test_empty.txt
    
    # Arquivo só com letras
    echo "abcdefghijklmnopqrstuvwxyz" > test_only_letters.txt
    
    # Arquivo só com números
    echo "1234567890" > test_only_numbers.txt
    
    log_success "Arquivos de teste criados"
}

# Função para executar todos os testes
run_all_tests() {
    local failed=0
    
    echo ""
    log_info "=== INICIANDO TESTES ==="
    echo ""
    
    # 1. Verificar se os serviços estão rodando
    log_info "1. Verificando serviços..."
    check_service 8080 "Mestre" || ((failed++))
    check_service 8081 "Escravo Letras" || ((failed++))
    check_service 8082 "Escravo Números" || ((failed++))
    
    echo ""
    
    # 2. Testar endpoints de health
    log_info "2. Testando endpoints de saúde..."
    test_endpoint "http://localhost:8080/health" "200" "Health Mestre" || ((failed++))
    test_endpoint "http://localhost:8081/health" "200" "Health Escravo Letras" || ((failed++))
    test_endpoint "http://localhost:8082/health" "200" "Health Escravo Números" || ((failed++))
    
    echo ""
    
    # 3. Testar endpoints diretos dos escravos
    log_info "3. Testando processamento direto dos escravos..."
    
    # Teste escravo letras
    curl -s -X POST http://localhost:8081/letras \
         -H "Content-Type: application/json" \
         -d '{"content":"abc123"}' > /tmp/letters_response.txt
    
    if grep -q '"count":3' /tmp/letters_response.txt; then
        log_success "Escravo letras processando corretamente"
    else
        log_error "Escravo letras com resultado incorreto"
        ((failed++))
    fi
    
    # Teste escravo números
    curl -s -X POST http://localhost:8082/numeros \
         -H "Content-Type: application/json" \
         -d '{"content":"abc123"}' > /tmp/numbers_response.txt
    
    if grep -q '"count":3' /tmp/numbers_response.txt; then
        log_success "Escravo números processando corretamente"
    else
        log_error "Escravo números com resultado incorreto"
        ((failed++))
    fi
    
    echo ""
    
    # 4. Criar arquivos de teste
    log_info "4. Preparando arquivos de teste..."
    create_test_files
    
    echo ""
    
    # 5. Testar processamento completo
    log_info "5. Testando processamento completo via cliente..."
    
    # Teste simples: "abc123" = 3 letras, 3 números
    test_processing "test_simple.txt" "3" "3" || ((failed++))
    
    # Teste arquivo vazio
    log_info "Testando arquivo vazio..."
    test_processing "test_empty.txt" "0" "0" || ((failed++))
    
    # Teste só letras: "abcdefghijklmnopqrstuvwxyz" = 26 letras, 0 números
    test_processing "test_only_letters.txt" "26" "0" || ((failed++))
    
    # Teste só números: "1234567890" = 0 letras, 10 números
    test_processing "test_only_numbers.txt" "0" "10" || ((failed++))
    
    echo ""
    
    # 6. Teste de carga simples
    log_info "6. Teste de carga (múltiplas requisições)..."
    for i in {1..5}; do
        log_info "Requisição $i/5..."
        test_processing "test_simple.txt" "3" "3" >/dev/null || ((failed++))
    done
    log_success "Teste de carga concluído"
    
    echo ""
    
    # Resumo dos testes
    if [ $failed -eq 0 ]; then
        log_success "=== TODOS OS TESTES PASSARAM! ==="
        log_success "Sistema funcionando corretamente"
    else
        log_error "=== $failed TESTE(S) FALHARAM ==="
        log_error "Verifique os logs acima para detalhes"
    fi
    
    # Limpeza
    rm -f test_*.txt /tmp/*_response.txt /tmp/response.txt
    
    return $failed
}

# Função para mostrar logs dos serviços
show_logs() {
    log_info "Mostrando logs dos serviços..."
    echo ""
    
    cd server
    docker-compose logs --tail=20
    cd ..
}

# Função para reiniciar serviços
restart_services() {
    log_info "Reiniciando serviços..."
    
    cd server
    docker-compose down
    sleep 2
    docker-compose up -d
    sleep 10
    cd ..
    
    log_success "Serviços reiniciados"
}

# Menu principal
case "${1:-}" in
    "all"|"")
        run_all_tests
        ;;
    "services")
        log_info "Verificando apenas os serviços..."
        check_service 8080 "Mestre"
        check_service 8081 "Escravo Letras"
        check_service 8082 "Escravo Números"
        ;;
    "health")
        log_info "Testando endpoints de saúde..."
        test_endpoint "http://localhost:8080/health" "200" "Health Mestre"
        test_endpoint "http://localhost:8081/health" "200" "Health Escravo Letras"
        test_endpoint "http://localhost:8082/health" "200" "Health Escravo Números"
        ;;
    "client")
        log_info "Testando apenas o cliente..."
        create_test_files
        test_processing "test_simple.txt" "3" "3"
        ;;
    "logs")
        show_logs
        ;;
    "restart")
        restart_services
        ;;
    "help")
        echo "Uso: $0 [comando]"
        echo ""
        echo "Comandos disponíveis:"
        echo "  all      - Executar todos os testes (padrão)"
        echo "  services - Verificar apenas se os serviços estão rodando"
        echo "  health   - Testar apenas endpoints de saúde"
        echo "  client   - Testar apenas o cliente"
        echo "  logs     - Mostrar logs dos serviços"
        echo "  restart  - Reiniciar os serviços"
        echo