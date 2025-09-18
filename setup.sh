#!/bin/bash

# Script de configuração automática do sistema distribuído
echo "=== CONFIGURAÇÃO DO SISTEMA DISTRIBUÍDO C++ ==="

# Verificar se está rodando como root para algumas operações
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Não execute como root. Execute como usuário normal."
    exit 1
fi

# Função para verificar se um comando existe
check_command() {
    if command -v $1 >/dev/null 2>&1; then
        echo "✅ $1 está disponível"
        return 0
    else
        echo "❌ $1 não encontrado"
        return 1
    fi
}

# Função para instalar dependências
install_dependencies() {
    echo "📦 Instalando dependências do sistema..."
    
    # Atualizar repositórios
    sudo apt-get update
    
    # Instalar dependências básicas
    sudo apt-get install -y \
        build-essential \
        cmake \
        pkg-config \
        libcurl4-openssl-dev \
        libjsoncpp-dev \
        wget \
        curl \
        docker.io \
        docker-compose
    
    # Adicionar usuário ao grupo docker
    sudo usermod -aG docker $USER
    
    echo "✅ Dependências instaladas!"
}

# Função para baixar bibliotecas vendor
setup_vendor_libs() {
    echo "📚 Configurando bibliotecas vendor..."
    
    cd server/vendor
    
    # Verificar se já existem
    if [ ! -f "httplib.h" ]; then
        echo "Baixando httplib.h..."
        wget -q https://raw.githubusercontent.com/yhirose/cpp-httplib/master/httplib.h
        if [ $? -eq 0 ]; then
            echo "✅ httplib.h baixado"
        else
            echo "❌ Erro ao baixar httplib.h"
            exit 1
        fi
    else
        echo "✅ httplib.h já existe"
    fi
    
    if [ ! -f "json.hpp" ]; then
        echo "Baixando json.hpp..."
        wget -q -O json.hpp https://raw.githubusercontent.com/nlohmann/json/develop/single_include/nlohmann/json.hpp
        if [ $? -eq 0 ]; then
            echo "✅ json.hpp baixado"
        else
            echo "❌ Erro ao baixar json.hpp"
            exit 1
        fi
    else
        echo "✅ json.hpp já existe"
    fi
    
    cd ../..
}

# Função para criar arquivo de teste
create_test_file() {
    echo "📝 Criando arquivo de teste..."
    
    cat > test_input.txt << 'EOF'
Hello World 123!
Esta é uma string de teste com números: 456, 789.
Contém letras maiúsculas: ABCDEF
Contém letras minúsculas: ghijkl
E alguns símbolos especiais: @#$%^&*()
Mais números para teste: 2024, 1337, 42
Fim do arquivo de teste.
EOF
    
    echo "✅ Arquivo test_input.txt criado"
}

# Função para compilar o projeto
compile_project() {
    echo "🔨 Compilando projeto..."
    
    # Compilar cliente
    cd client
    make clean
    make
    if [ $? -eq 0 ]; then
        echo "✅ Cliente compilado com sucesso"
    else
        echo "❌ Erro na compilação do cliente"
        exit 1
    fi
    cd ..
    
    # Construir containers Docker
    cd server
    echo "🐳 Construindo containers Docker..."
    docker-compose build
    if [ $? -eq 0 ]; then
        echo "✅ Containers construídos com sucesso"
    else
        echo "❌ Erro na construção dos containers"
        exit 1
    fi
    cd ..
}

# Função para iniciar os serviços
start_services() {
    echo "🚀 Iniciando serviços..."
    
    cd server
    docker-compose up -d
    
    # Aguardar serviços iniciarem
    echo "⏳ Aguardando serviços iniciarem..."
    sleep 10
    
    # Verificar se os serviços estão rodando
    echo "🔍 Verificando serviços..."
    
    for port in 8080 8081 8082; do
        if curl -s http://localhost:$port/health >/dev/null; then
            echo "✅ Serviço na porta $port está rodando"
        else
            echo "❌ Serviço na porta $port não está respondendo"
        fi
    done
    
    cd ..
}

# Função para executar teste
run_test() {
    echo "🧪 Executando teste..."
    
    if [ -f "test_input.txt" ] && [ -f "client/client" ]; then
        echo "📤 Enviando arquivo de teste..."
        ./client/client test_input.txt
        
        if [ $? -eq 0 ]; then
            echo "✅ Teste executado com sucesso!"
        else
            echo "❌ Erro no teste"
        fi
    else
        echo "❌ Arquivos necessários não encontrados"
    fi
}

# Função para mostrar informações do sistema
show_info() {
    echo ""
    echo "ℹ️  INFORMAÇÕES DO SISTEMA:"
    echo "  - Mestre: http://localhost:8080"
    echo "  - Escravo Letras: http://localhost:8081"  
    echo "  - Escravo Números: http://localhost:8082"
    echo ""
    echo "📋 COMANDOS ÚTEIS:"
    echo "  - Verificar logs: cd server && docker-compose logs -f"
    echo "  - Parar serviços: cd server && docker-compose down"
    echo "  - Executar cliente: ./client/client <arquivo.txt>"
    echo "  - Health check: curl http://localhost:8080/health"
    echo ""
}

# Menu principal
main() {
    echo ""
    echo "Escolha uma opção:"
    echo "1) Instalação completa (recomendado para primeira execução)"
    echo "2) Apenas instalar dependências"
    echo "3) Apenas configurar bibliotecas vendor"
    echo "4) Apenas compilar projeto"
    echo "5) Apenas iniciar serviços"
    echo "6) Executar teste"
    echo "7) Mostrar informações"
    echo "0) Sair"
    echo ""
    
    read -p "Digite sua escolha: " choice
    
    case $choice in
        1)
            echo "🚀 Iniciando instalação completa..."
            install_dependencies
            setup_vendor_libs
            create_test_file
            compile_project
            start_services
            run_test
            show_info
            ;;
        2)
            install_dependencies
            ;;
        3)
            setup_vendor_libs
            ;;
        4)
            setup_vendor_libs
            compile_project
            ;;
        5)
            start_services
            ;;
        6)
            run_test
            ;;
        7)
            show_info
            ;;
        0)
            echo "👋 Saindo..."
            exit 0
            ;;
        *)
            echo "❌ Opção inválida"
            main
            ;;
    esac
}

# Verificações iniciais
echo "🔍 Verificando sistema..."

# Verificar se estamos no diretório correto
if [ ! -d "server" ] || [ ! -d "client" ]; then
    echo "❌ Execute este script no diretório raiz do projeto"
    exit 1
fi

# Verificar comandos essenciais
echo "Verificando comandos essenciais..."
check_command "gcc"
check_command "g++"
check_command "make"

# Executar menu principal
main