#include "../vendor/httplib.h"
#include "../vendor/json.hpp"
#include <iostream>
#include <string>
#include <cctype>

using json = nlohmann::json;

class SlaveLettersServer {
private:
    int countLetters(const std::string& text) {
        int count = 0;
        for (char c : text) {
            if (std::isalpha(c)) {
                count++;
            }
        }
        return count;
    }

public:
    void startServer() {
        httplib::Server server;

        // Endpoint para contar letras
        server.Post("/letras", [this](const httplib::Request& req, httplib::Response& res) {
            try {
                json request_data = json::parse(req.body);
                std::string content = request_data["content"];
                
                std::cout << "Processando contagem de letras..." << std::endl;
                std::cout << "Tamanho do texto: " << content.length() << " caracteres" << std::endl;

                int letter_count = countLetters(content);

                json response_data;
                response_data["count"] = letter_count;
                response_data["type"] = "letters";
                response_data["status"] = "success";

                res.set_content(response_data.dump(), "application/json");
                
                std::cout << "Letras encontradas: " << letter_count << std::endl;

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
            response["service"] = "slave-letters";
            response["port"] = 8081;
            res.set_content(response.dump(), "application/json");
        });

        // Endpoint raiz para informações
        server.Get("/", [](const httplib::Request&, httplib::Response& res) {
            json response;
            response["service"] = "Slave Letters Counter";
            response["version"] = "1.0";
            response["endpoints"] = {"/letras", "/health"};
            res.set_content(response.dump(), "application/json");
        });

        std::cout << "Servidor Escravo Letras iniciado na porta 8081" << std::endl;
        server.listen("0.0.0.0", 8081);
    }
};

int main() {
    try {
        SlaveLettersServer slave;
        slave.startServer();
    } catch (const std::exception& e) {
        std::cerr << "Erro ao iniciar servidor: " << e.what() << std::endl;
        return 1;
    }
    return 0;
}