# Makefile para compilação do sistema distribuído
CXX = g++
CXXFLAGS = -std=c++17 -O2 -Wall -Wextra
INCLUDES = -Ivendor

# Diretórios
CLIENT_DIR = ../client
MASTER_DIR = master
SLAVE_LETTERS_DIR = slave_letters
SLAVE_NUMBERS_DIR = slave_numbers

# Alvos principais
all: client master slave_letters slave_numbers

# Cliente (compila fora dos containers)
client:
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(CLIENT_DIR)/client $(CLIENT_DIR)/client.cpp -lcurl -ljsoncpp

# Servidor Mestre
master:
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o master_server $(MASTER_DIR)/master.cpp -lcurl -lpthread

# Escravo Letras
slave_letters:
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o slave_letters_server $(SLAVE_LETTERS_DIR)/slave_letters.cpp -lpthread

# Escravo Números
slave_numbers:
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o slave_numbers_server $(SLAVE_NUMBERS_DIR)/slave_numbers.cpp -lpthread

# Compilação apenas dos servidores (para uso nos containers)
servers: master slave_letters slave_numbers

# Docker
docker-build:
	docker-compose build

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

docker-restart: docker-down docker-up

# Limpeza
clean:
	rm -f master_server slave_letters_server slave_numbers_server $(CLIENT_DIR)/client
	docker-compose down --rmi all --volumes --remove-orphans 2>/dev/null || true

# Teste completo
test: docker-up
	@echo "Aguardando serviços iniciarem..."
	@sleep 5
	@echo "Testando health checks..."
	@curl -s http://localhost:8080/health || echo "Master não está respondendo"
	@curl -s http://localhost:8081/health || echo "Slave Letters não está respondendo"  
	@curl -s http://localhost:8082/health || echo "Slave Numbers não está respondendo"

# Instalar dependências (Ubuntu/Debian)
install-deps:
	sudo apt-get update
	sudo apt-get install -y build-essential cmake libcurl4-openssl-dev libjsoncpp-dev pkg-config docker.io docker-compose

# Ajuda
help:
	@echo "Alvos disponíveis:"
	@echo "  all           - Compila cliente e todos os servidores"
	@echo "  client        - Compila apenas o cliente"
	@echo "  servers       - Compila apenas os servidores"
	@echo "  docker-build  - Constrói as imagens Docker"
	@echo "  docker-up     - Inicia os containers"
	@echo "  docker-down   - Para os containers"
	@echo "  docker-logs   - Mostra logs dos containers"
	@echo "  docker-restart- Reinicia os containers"
	@echo "  test          - Testa os serviços"
	@echo "  clean         - Limpa arquivos compilados e containers"
	@echo "  install-deps  - Instala dependências do sistema"
	@echo "  help          - Mostra esta ajuda"

.PHONY: all client master slave_letters slave_numbers servers docker-build docker-up docker-down docker-logs docker-restart clean test install-deps help