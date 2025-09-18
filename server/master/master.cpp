#include "../vendor/httplib.h"
#include "../vendor/json.hpp"
#include <iostream>
#include <thread>
#include <future>
#include <string>
#include <curl/curl.h>

using json = nlohmann::json;

struct HTTPResponse {
    std::string data;
    long response_code;
    bool success;
};

size_t WriteCallback(void* contents, size_t size, size_t nmemb, HTTPResponse* response) {
    size_t total_size = size * nmemb;
    response->data.append((char*)contents, total_size);
    return total_size;
}

class MasterServer {
private:
    std::string slave1_url = "http://slave-letters:8081";
    std::string slave2_url = "http://slave-numbers:8082";

    HTTPResponse makeRequest(const std::string& url, const std::string& data = "") {
        HTTPResponse response;
        response.success = false;
        response.response_code = 0;

        CURL* curl = curl_easy_init();
        if (!curl) {
            return response;
        }

        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);

        struct curl_slist* headers = nullptr;

        if (!data.empty()) {
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data.c_str());
            headers = curl_slist_append(headers, "Content-Type: application/json");
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        }

        CURLcode res = curl_easy_perform(curl);
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response.response_code);

        if (headers) {
            curl_slist_free_all(headers);
        }
        curl_easy_cleanup(curl);

        response.success = (res == CURLE_OK && response.response_code == 200);
        return response;
    }

    bool checkSlaveHealth(const std::string& slave_url) {
        std::cout << "Verificando saúde do escravo: " << slave_url << std::endl;
        HTTPResponse response = makeRequest(slave_url + "/health");
        return response.success;
    }

    std::future<int> processWithSlave(const std::string& slave_url, const std::string& endpoint, 
                                     const std::string& content) {
        return std::async(std::launch::async, [this, slave_url, endpoint, content]() -> int {
            std::cout << "Processando com escravo: " << slave_url << endpoint << std::endl;
            
            // Verificar se o escravo está disponível
            if (!checkSlaveHealth(slave_url)) {
                std::cerr << "Escravo não está disponível: " << slave_url << std::endl;
                return -1;
            }

            // Enviar dados para processamento
            json request_data;
            request_data["content"] = content;
            
            HTTPResponse response = makeRequest(slave_url + endpoint, request_data.dump());
            
            if (response.success) {
                try {
                    json result = json::parse(response.data);
                    return result["count"];
                } catch (const std::exception& e) {
                    std::cerr << "Erro ao processar resposta JSON: " << e.what() << std::endl;
                    return -1;
                }
            }
            
            std::cerr << "Erro na comunicação com escravo: " << slave_url << std::endl;
            return -1;
        });
    }

public:
    void startServer() {
        httplib::Server server;

        // Endpoint para processar arquivos
        server.Post("/process", [this](const httplib::Request& req, httplib::Response& res) {
            try {
                json request_data = json::parse(req.body);
                std::string content = request_data["content"];
                
                std::cout << "Recebida requisição de processamento" << std::endl;
                std::cout << "Tamanho do conteúdo: " << content.length() << " caracteres" << std::endl;

                // Disparar duas threads em paralelo
                auto letters_future = processWithSlave(slave1_url, "/letras", content);
                auto numbers_future = processWithSlave(slave2_url, "/numeros", content);

                // Aguardar resultados
                int letters_count = letters_future.get();
                int numbers_count = numbers_future.get();

                // Criar resposta consolidada
                json response_data;
                
                if (letters_count >= 0 && numbers_count >= 0) {
                    response_data["status"] = "success";
                    response_data["letters"] = letters_count;
                    response_data["numbers"] = numbers_count;
                    res.set_content(response_data.dump(), "application/json");
                    std::cout << "Processamento concluído com sucesso" << std::endl;
                } else {
                    response_data["status"] = "error";
                    response_data["message"] = "Erro ao processar com um ou mais escravos";
                    res.status = 500;
                    res.set_content(response_data.dump(), "application/json");
                    std::cout << "Erro no processamento" << std::endl;
                }

            } catch (const std::exception& e) {
                json error_response;
                error_response["status"] = "error";
                error_response["message"] = e.what();
                res.status = 400;
                res.set_content(error_response.dump(), "application/json");
                std::cerr << "Erro ao processar requisição: " << e.what() << std::endl;
            }
        });

        // Endpoint de health check
        server.Get("/health", [](const httplib::Request&, httplib::Response& res) {
            json response;
            response["status"] = "healthy";
            response["service"] = "master";
            res.set_content(response.dump(), "application/json");
        });

        std::cout << "Servidor Mestre iniciado na porta 8080" << std::endl;
        server.listen("0.0.0.0", 8080);
    }
};

int main() {
    // Inicializar CURL globalmente
    curl_global_init(CURL_GLOBAL_DEFAULT);
    
    try {
        MasterServer master;
        master.startServer();
    } catch (const std::exception& e) {
        std::cerr << "Erro ao iniciar servidor: " << e.what() << std::endl;
        return 1;
    }

    // Limpar CURL
    curl_global_cleanup();
    return 0;
}