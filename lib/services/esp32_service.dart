import 'package:web_socket_channel/io.dart';

class ESP32WebSocketService {
  late IOWebSocketChannel channel;
  Function(String message)? onMessageReceived;

  void connect() {
    channel = IOWebSocketChannel.connect("ws://192.168.4.1:81");

    channel.stream.listen((message) {
      if (onMessageReceived != null) {
        onMessageReceived!(message);
      }
    });
  }

  void sendMessage(String message) {
    channel.sink.add(message);
  }

  void disconnect() {
    channel.sink.close();
  }
}







/* #include <WiFi.h>
#include <WebServer.h>

const char *ssid = "ESP32_Network";  // Change this
const char *password = "12345678";   // Change this

WebServer server(80); // Create server on port 80

String receivedMessage = "";

void handleRoot() {
  server.send(200, "text/plain", "ESP32 is connected!");
}

void handleSendMessage() {
  if (server.hasArg("message")) {
    receivedMessage = server.arg("message");
    Serial.println("Received Message: " + receivedMessage);
    server.send(200, "text/plain", "Message received: " + receivedMessage);
  } else {
    server.send(400, "text/plain", "No message received");
  }
}

void handleGetMessage() {
  server.send(200, "text/plain", "Last Message: " + receivedMessage);
}

void setup() {
  Serial.begin(115200);
  WiFi.softAP(ssid, password);  // Start ESP32 as Wi-Fi Access Point

  server.on("/", handleRoot);
  server.on("/send", HTTP_POST, handleSendMessage);
  server.on("/receive", HTTP_GET, handleGetMessage);

  server.begin();
  Serial.println("ESP32 Server started");
}

void loop() {
  server.handleClient();
} */




/* #include <WiFi.h>
#include <WebSocketsServer.h>

const char *ssid = "ESP32_Chat";
const char *password = "12345678";

WebSocketsServer webSocket(81);

void setup() {
    Serial.begin(115200);
    WiFi.softAP(ssid, password);
    
    Serial.println("ESP32 WebSocket Server Started!");
    webSocket.begin();
    webSocket.onEvent(webSocketEvent);
}

void loop() {
    webSocket.loop();
}

// Handle WebSocket Events
void webSocketEvent(uint8_t num, WStype_t type, uint8_t *payload, size_t length) {
    if (type == WStype_TEXT) {
        Serial.printf("Received: %s\n", payload);
        // Broadcast message to all connected users
        webSocket.broadcastTXT(payload, length);
    }
}
 */

