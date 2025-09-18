#include "../vendor/httplib.h"
#include "../vendor/json.hpp"
#include <iostream>
#include <string>
#include <cctype>

using json = nlohmann::json;

class SlaveNumbersServer {
private:
    int countNumbers(const std::string& text) {
        int count = 0;
        for (char c : text) {
            if (std::isdigit(c)) {
                count++;
            }
        }
        return count;
    }

public:
    void startServer() {
        httplib::Server server;

        // Endpoint para contar números
        server.Post("/numeros", [this](const httplib::Request& req, httplib::Response& res) {
            try {
                json request_data = json::parse(req.body);
                std::string content = request_data["content"];
                
                std::cout << "Processando contagem de números..." << std::endl;
                std::cout << "Tamanho do texto: " << content.length() << " caracteres" << std::endl;

                int number_count = countNumbers(content);

                json response_data;
                response_data["count"] = number_count;
                response_data["type"] = "numbers";
                response_data["status"] = "success";

                res.set_content(response_data.dump(), "application/json");
                
                std::cout << "Números encontrados: " << number_count << std::endl;

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
            response["service"] = "slave-numbers";
            response["port"] = 8082;
            res.set_content(response.dump(), "application/json");
        });

        // Endpoint raiz para informações
        server.Get("/", [](const httplib::Request&, httplib::Response& res) {
            json response;
            response["service"] = "Slave Numbers Counter";
            response["version"] = "1.0";
            response["endpoints"] = {"/numeros", "/health"};
            res.set_content(response.dump(), "application/json");
        });

        std::cout << "Servidor Escravo Números iniciado na porta 8082" << std::endl;
        server.listen("0.0.0.0", 8082);
    }
};

int main() {
    try {
        SlaveNumbersServer slave;
        slave.startServer();
    } catch (const std::exception& e) {
        std::cerr << "Erro ao iniciar servidor: " << e.what() << std::endl;
        return 1;
    }
    return 0;
}