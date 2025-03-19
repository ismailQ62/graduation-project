import 'package:http/http.dart' as http;

class ESP32HttpService {
  final String _esp32Url = "http://192.168.4.1/send"; // ESP32 AP Mode URL

  Future<bool> sendMessage(String message) async {
    try {
      var response = await http.post(
        Uri.parse(_esp32Url),
        body: message,
        headers: {"Content-Type": "text/plain"},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error sending message: $e");
      return false;
    }
  }
}
