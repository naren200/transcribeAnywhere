#include <iostream>
#include <vector>
#include <string>
#include <chrono>
#include <fstream>
#include <cstdio>
#include <memory>
#include <array>
#include <algorithm>  
#include <filesystem>
#include <regex>
#include <cstdlib>
#include <thread>
#include <atomic>
#include <csignal>
#include <sys/types.h>
#include <fcntl.h>

class WhisperStreamHandler {
private:
    std::string outputPath = "/app/output/live_transcript.txt";
    bool ydotoolInitialized = false;
    std::atomic<bool> transcriptionActive{true};
    std::atomic<bool> keepRunning{true};
    FILE* whisperPipe{nullptr};
    static WhisperStreamHandler* instance;
    // Add these at class level
    std::atomic<int> sigint_count{0};
    std::chrono::steady_clock::time_point last_sigint_time;

    void initializeYdotool() {
        if (!ydotoolInitialized) {
            system("pkill ydotool"); // Kill any existing instances
            system("ydotool &>/dev/null &");
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            ydotoolInitialized = true;
        }
    }

    // Function to clear or delete the file if it exists
    void initializeFile() {
        if (std::filesystem::exists(outputPath)) {
            std::ofstream outFile(outputPath, std::ios::trunc); // Open in truncate mode to clear contents
            if (outFile.is_open()) {
                outFile.close();
                std::cout << "Cleared existing file: " << outputPath << std::endl;
            } else {
                throw std::runtime_error("Failed to clear file: " + outputPath);
            }
        }
    }
    
    void saveToFile(const std::string& text) {
        std::filesystem::create_directories(std::filesystem::path(outputPath).parent_path());
        
        std::ofstream outFile(outputPath, std::ios::app);
        if (outFile.is_open()) {
            outFile << text;
            outFile.flush();  
        }
    }
    void injectText(const std::string& text) {
        std::string spacedText = "   " + text;
        std::string sanitized = std::regex_replace(spacedText, std::regex("'"), "'\\''");
        
        try {
            if (!ydotoolInitialized) {
                initializeYdotool();
            }
            
            std::string cmd = "ydotool type --key-delay 10 '" + sanitized + "' 2>/dev/null";
            int result = system(cmd.c_str());
            
            if (result != 0) {
                std::cerr << "ydotool command failed, reinitializing..." << std::endl;
                ydotoolInitialized = false;
                initializeYdotool();
                system(cmd.c_str());
            }
        } catch (const std::exception& e) {
            std::cerr << "Error injecting text: " << e.what() << std::endl;
        }
    }

    static void signalHandler(int signum) {
        if (instance && signum == SIGINT) {
            auto now = std::chrono::steady_clock::now();
            if (now - instance->last_sigint_time < std::chrono::seconds(1)) {
                std::cerr << "\n[FORCED SHUTDOWN]\n";
                _exit(EXIT_FAILURE);
            }
            
            instance->last_sigint_time = now;
            instance->sigint_count++;
            
            std::cerr << "\n[SHUTDOWN INITIATED - PRESS AGAIN TO FORCE]\n";
            instance->keepRunning = false;
            
            if (instance->whisperPipe) {
                pclose(instance->whisperPipe);
                instance->whisperPipe = nullptr;
            }
        }
    }
    
    void inputHandler() {
        std::string command;
        while (keepRunning) {
            std::getline(std::cin, command);
            
            for(size_t i = 0; i < command.length() - 1; ++i) {
                if(command[i] == '!') {
                    const char next = std::tolower(command[i+1]);
                    if(next == 's') {
                        transcriptionActive = true;
                        std::cout << "\n[SYSTEM] Transcription RESUMED\n";
                        break;
                    }
                    else if(next == 'p') {
                        transcriptionActive = false;
                        std::cout << "\n[SYSTEM] Transcription PAUSED\n";
                        break;
                    }
                    else if(next == 'e') {
                        keepRunning = false;
                        std::cout << "\n[SYSTEM] Shutting down...\n";
                        if (whisperPipe) {
                            fclose(whisperPipe);
                            whisperPipe = nullptr;
                        }
                        break;
                    }
                }
            }
        }
    }
        
public:
    WhisperStreamHandler() {
        instance = this;
        struct sigaction sa;
        sa.sa_handler = signalHandler;
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = 0;
        sigaction(SIGINT, &sa, nullptr);
        
        initializeFile(); 
        initializeYdotool();
    }

    ~WhisperStreamHandler() {
        if (whisperPipe) {
            fclose(whisperPipe);
        }
    }

    std::string executeCommand(const std::string& cmd) {
        std::array<char, 128> buffer;
        std::string result;
        std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
        
        if (!pipe) {
            throw std::runtime_error("popen() failed!");
        }
        
        while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
            result += buffer.data();
        }
        return result;
    }

    void getAudioDevices() {
        std::string cmd = "arecord -l";
        std::string devices = executeCommand(cmd);
        std::cout << "Available audio devices:\n" << devices << std::endl;
    }

    void processWhisperStream(const std::string& modelPath, int captureDevice) {
        std::string cmd = "stdbuf -oL /usr/local/src/whisper.cpp/build/bin/whisper-stream -m " + 
                         modelPath + " --capture " + std::to_string(captureDevice);

        std::thread inputThread([this]() { inputHandler(); });
        
        whisperPipe = popen(cmd.c_str(), "r");
        if (!whisperPipe) {
            throw std::runtime_error("Failed to start whisper-stream");
        }

        char buffer[1024];
        std::string currentLine;
        std::regex ansiEscape(R"(\x1B\[[0-9;]*[A-Za-z])");

        while (keepRunning && fgets(buffer, sizeof(buffer), whisperPipe)) {
            currentLine = buffer;
            
            // std::cout << "RAW_OUTPUT" << currentLine;

            // Inside the processing loop
            if (!currentLine.empty()) {
                currentLine = std::regex_replace(currentLine, ansiEscape, "");
                currentLine = std::regex_replace(currentLine, std::regex(R"(\s*[\[\{].*?[\]\}])"), "");
                currentLine = std::regex_replace(currentLine, std::regex(R"(\s*[\(\{].*?[\)\}])"), "");
                currentLine = std::regex_replace(currentLine, std::regex(R"(\s+)"), " ");
                currentLine = std::regex_replace(currentLine, std::regex(R"(^\s+|\s+$)"), " ");

                if (!currentLine.empty() && transcriptionActive) {
                    injectText(currentLine);
                    std::cout << "\n[TRANSCRIPT] " << currentLine << std::endl;
                }
            }
        }

        keepRunning = false;
        inputThread.join();
        
        if (whisperPipe) {
            pclose(whisperPipe);
            whisperPipe = nullptr;
        }
    }
};

// Initialize static member
WhisperStreamHandler* WhisperStreamHandler::instance = nullptr;

int main() {
    WhisperStreamHandler handler;
    
    // First list available audio devices
    handler.getAudioDevices();
    try {
        // Get device from environment variable or use default
        const char* env_device = std::getenv("CAPTURE_DEVICE");
        int capture_device = 2;
        
        if(env_device != nullptr) {
            try {
                capture_device = std::stoi(env_device);
            } catch(const std::exception& e) {
                std::cerr << "Invalid CAPTURE_DEVICE value: " 
                         << env_device << " - using default 2\n";
            }
        }

        std::cerr << "Using capture device: " << capture_device << "\n";
        handler.processWhisperStream(
            "/usr/local/src/whisper.cpp/models/ggml-small.en.bin",
            capture_device
        );
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
