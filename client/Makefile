# Makefile para o Cliente
CXX = g++
CXXFLAGS = -std=c++17 -O2 -Wall -Wextra
LIBS = -lcurl -ljsoncpp

# Nome do executável
TARGET = client

# Arquivo fonte
SOURCE = client.cpp

# Compilação
$(TARGET): $(SOURCE)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SOURCE) $(LIBS)

# Instalar dependências
install-deps:
	sudo apt-get update
	sudo apt-get install -y build-essential libcurl4-openssl-dev libjsoncpp-dev

# Limpeza
clean:
	rm -f $(TARGET)

# Teste básico
test: $(TARGET)
	@echo "Cliente compilado com sucesso!"
	@echo "Uso: ./$(TARGET) <arquivo.txt> [url_do_mestre]"

.PHONY: install-deps clean test