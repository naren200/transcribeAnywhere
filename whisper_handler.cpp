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
#include <chrono>


struct TranscriptionData {
    std::string text;
    std::chrono::system_clock::time_point timestamp;
    
};

class WhisperStreamHandler {
private:
    std::string outputPath = "/app/output/live_transcript.txt";
    bool ydotoolInitialized = false;
    
    void initializeYdotool() {
        if (!ydotoolInitialized) {
            system("pkill ydotool"); // Kill any existing instances
            system("ydotool &>/dev/null &");
            std::this_thread::sleep_for(std::chrono::milliseconds(700));
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
        std::string sanitized = std::regex_replace(text, std::regex("'"), "'\\''");
        std::string cmd = "ydotool type '" + sanitized + "'";

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
        
public:
    WhisperStreamHandler() {
        initializeFile(); 
        initializeYdotool();
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
        std::string cmd = "stdbuf -oL /usr/local/src/whisper.cpp/build/bin/whisper-stream -m " + modelPath + 
                         " --capture " + std::to_string(captureDevice);
        // Configure streams
        std::cout << std::unitbuf;
        std::ios_base::sync_with_stdio(false);


        FILE* pipe = popen(cmd.c_str(), "r");
        if (!pipe) {
            throw std::runtime_error("Failed to start whisper-stream");
        }

        char buffer[1024];
        std::string currentLine;
        std::regex ansiEscape(R"(\x1B\[[0-9;]*[A-Za-z])");  // ANSI escape pattern

        while (fgets(buffer, sizeof(buffer), pipe)) {
            currentLine = buffer;
            
            std::cout << "RAW_OUTPUT" << currentLine;

            // Inside the processing loop
            if (!currentLine.empty()) {
                TranscriptionData data{
                    currentLine,
                    std::chrono::system_clock::now()
                };
                // Inside processWhisperStream() after reading currentLine:
                std::string processedLine;
                size_t lastPos = 0;
                std::sregex_iterator it(currentLine.begin(), currentLine.end(), ansiEscape);
                std::sregex_iterator end;

                for (; it != end; ++it) {
                    std::smatch match = *it;
                    size_t escapeStart = match.position();
                    size_t escapeLength = match.length();

                    size_t lastNewline = currentLine.rfind('\n', escapeStart);
                    
                    if (lastNewline != std::string::npos) {
                        processedLine += currentLine.substr(lastPos, lastNewline - lastPos + 1);
                        lastPos = lastNewline + 1;
                    } else {
                        lastPos = escapeStart;
                    }
                    lastPos = escapeStart + escapeLength;
                }

                processedLine += currentLine.substr(lastPos);
                currentLine = std::regex_replace(processedLine, ansiEscape, "");


                // Collapse whitespace and clean line
                currentLine = std::regex_replace(currentLine, std::regex(R"(\s+)"), " ");  // Multiple spaces -> single
                currentLine = std::regex_replace(currentLine, std::regex(R"(^\s+|\s+$)"), " ");  // Trim edges

                // After cleaning the transcribed text in processWhisperStream():
                if (!currentLine.empty()) {
                    injectText(currentLine);
                    // saveToFile(currentLine);
                }
                
            }

        }
        pclose(pipe);
    }
};

int main() {
    WhisperStreamHandler handler;
    
    // First list available audio devices
    handler.getAudioDevices();
    try {
        // Get device from environment variable or use default
        const char* env_device = std::getenv("CAPTURE_DEVICE");
        int capture_device = 2; // Default value
        
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
