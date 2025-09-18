#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <curl/curl.h>
#include <json/json.h>

struct HTTPResponse {
    std::string data;
    long response_code;
};

size_t WriteCallback(void* contents, size_t size, size_t nmemb, HTTPResponse* response) {
    size_t total_size = size * nmemb;
    response->data.append((char*)contents, total_size);
    return total_size;
}

class Client {
private:
    std::string master_url;
    CURL* curl;

public:
    Client(const std::string& url) : master_url(url) {
        curl = curl_easy_init();
        if (!curl) {
            throw std::runtime_error("Failed to initialize CURL");
        }
    }

    ~Client() {
        if (curl) {
            curl_easy_cleanup(curl);
        }
    }

    HTTPResponse sendFile(const std::string& filename) {
        std::ifstream file(filename);
        if (!file.is_open()) {
            throw std::runtime_error("Cannot open file: " + filename);
        }

        std::stringstream buffer;
        buffer << file.rdbuf();
        std::string content = buffer.str();
        file.close();

        // Criar JSON para enviar
        Json::Value json_data;
        json_data["content"] = content;
        json_data["filename"] = filename;

        Json::StreamWriterBuilder builder;
        std::string json_string = Json::writeString(builder, json_data);

        HTTPResponse response;
        response.response_code = 0;

        if (curl) {
            curl_easy_setopt(curl, CURLOPT_URL, (master_url + "/process").c_str());
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_string.c_str());
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

            struct curl_slist* headers = nullptr;
            headers = curl_slist_append(headers, "Content-Type: application/json");
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

            CURLcode res = curl_easy_perform(curl);
            curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response.response_code);

            curl_slist_free_all(headers);

            if (res != CURLE_OK) {
                throw std::runtime_error("CURL request failed: " + std::string(curl_easy_strerror(res)));
            }
        }

        return response;
    }

    void displayResult(const HTTPResponse& response) {
        if (response.response_code == 200) {
            Json::Value root;
            Json::Reader reader;
            
            if (reader.parse(response.data, root)) {
                std::cout << "\n=== RESULTADO DO PROCESSAMENTO ===" << std::endl;
                std::cout << "Número de letras: " << root["letters"].asInt() << std::endl;
                std::cout << "Número de números: " << root["numbers"].asInt() << std::endl;
                std::cout << "Status: " << root["status"].asString() << std::endl;
                std::cout << "===================================" << std::endl;
            } else {
                std::cout << "Erro ao processar resposta JSON" << std::endl;
                std::cout << "Resposta bruta: " << response.data << std::endl;
            }
        } else {
            std::cout << "Erro na requisição. Código: " << response.response_code << std::endl;
            std::cout << "Resposta: " << response.data << std::endl;
        }
    }
};

int main(int argc, char* argv[]) {
    std::cout << "=== CLIENTE DISTRIBUÍDO C++ ===" << std::endl;

    std::string master_url = "http://localhost:8080";
    std::string filename;

    // Verificar argumentos da linha de comando
    if (argc > 1) {
        filename = argv[1];
    } else {
        std::cout << "Digite o caminho do arquivo .txt: ";
        std::getline(std::cin, filename);
    }

    if (argc > 2) {
        master_url = argv[2];
    }

    try {
        Client client(master_url);
        std::cout << "Enviando arquivo: " << filename << std::endl;
        std::cout << "Para o mestre: " << master_url << std::endl;

        HTTPResponse response = client.sendFile(filename);
        client.displayResult(response);

    } catch (const std::exception& e) {
        std::cerr << "Erro: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}