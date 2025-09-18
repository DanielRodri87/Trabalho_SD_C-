# Sistema Distribuído C++ - Contador de Letras e Números

Sistema distribuído implementado em C++ puro utilizando threads, containers Docker e arquitetura mestre-escravo para processamento paralelo de arquivos de texto.

## 📋 Descrição

Este sistema implementa uma arquitetura distribuída onde:
- **Cliente**: Envia arquivos .txt via HTTP REST para processamento
- **Mestre**: Coordena o processamento distribuído usando threads paralelas  
- **Escravos**: Processam o conteúdo (um conta letras, outro conta números)

## 🏗️ Arquitetura

```
Cliente (Notebook 1) 
    ↓ HTTP REST
Mestre (Container Docker)
    ↓ Threads paralelas  
Escravo 1 (Letters) ←→ Escravo 2 (Numbers)
```

### Componentes

1. **Cliente** (`client/client.