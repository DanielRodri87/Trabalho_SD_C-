# 🚀 Guia de Início Rápido

## Configuração Automática (Recomendado)

```bash
# 1. Clone/baixe o projeto
git clone <seu-repositorio>
cd sistema-distribuido-cpp

# 2. Execute o setup automático
chmod +x setup.sh
./setup.sh

# 3. Siga as instruções na tela
# Escolha opção 1 para instalação completa
```

## Configuração Manual

### Passo 1: Instalar Dependências
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y build-essential cmake libcurl4-openssl-dev libjsoncpp-dev docker.io docker-compose

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### Passo 2: Baixar Bibliotecas Vendor
```bash
cd server/vendor
wget https://raw.githubusercontent.com/yhirose/cpp-httplib/master/httplib.h
wget -O json.hpp https://raw.githubusercontent.com/nlohmann/json/develop/single_include/nlohmann/json.hpp
cd ../..
```

### Passo 3: Compilar e Executar
```bash
# Iniciar serviços Docker
cd server
docker-compose up --build -d

# Compilar cliente
cd ../client
make

# Testar sistema
./client ../exemplo.txt
```

## Teste Rápido

```bash
# Verificar se serviços estão rodando
curl http://localhost:8080/health
curl http://localhost:8081/health
curl http://localhost:8082/health

# Executar teste automatizado
chmod +x test.sh
./test.sh
```

## Comandos Úteis

```bash
# Ver logs dos serviços
cd server && docker-compose logs -f

# Parar serviços
cd server && docker-compose down

# Reiniciar tudo
cd server && docker-compose restart

# Limpeza completa
cd server && make clean
```

## Estrutura de Arquivos Esperada

```
projeto/
├── client/
│   ├── client.cpp
│   └── Makefile
├── server/
│   ├── master/master.cpp
│   ├── slave_letters/slave_letters.cpp
│   ├── slave_numbers/slave_numbers.cpp
│   ├── vendor/
│   │   ├── httplib.h
│   │   └── json.hpp
│   ├── docker-compose.yml
│   └── Dockerfile.*
├── exemplo.txt
├── setup.sh
└── test.sh
```

## Solução de Problemas Comuns

**Erro de compilação:**
```bash
# Verificar g++ versão (deve ser >= 7.0)
g++ --version

# Reinstalar dependências
sudo apt-get install --reinstall build-essential libcurl4-openssl-dev libjsoncpp-dev
```

**Docker não inicia:**
```bash
# Verificar se Docker está rodando
sudo systemctl status docker

# Verificar portas
netstat -tlnp | grep :808
```

**Cliente não conecta:**
```bash
# Verificar se serviços estão saudáveis
docker-compose ps

# Verificar logs
docker-compose logs master
```

## Exemplo de Uso

```bash
# Criar arquivo de teste
echo "Hello123World456" > teste.txt

# Executar processamento
./client/client teste.txt

# Resultado esperado:
# Número de letras: 10
# Número de números: 6
```

---

Para mais detalhes, consulte o [README.md](README.md) completo.