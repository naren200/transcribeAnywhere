CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra
LDFLAGS = -lasound -lX11

TARGET = whisper_handler
SRCS = whisper_handler.cpp
OBJS = $(SRCS:.cpp=.o)

$(TARGET): $(OBJS)
	$(CXX) $(OBJS) -o $(TARGET) $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)
