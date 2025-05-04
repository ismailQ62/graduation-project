import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_socket_channel/io.dart';
import 'package:lorescue/services/auth_service.dart';

class UploadVerificationScreen extends StatefulWidget {
  const UploadVerificationScreen({super.key});

  @override
  _UploadVerificationScreenState createState() =>
      _UploadVerificationScreenState();
}

class _UploadVerificationScreenState extends State<UploadVerificationScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  late IOWebSocketChannel _channel;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotification();
    _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

    _channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        final currentUser = AuthService.getCurrentUser();
        if (data['type'] == 'verify' &&
            data['status'] == 'approved' &&
            data['id'] == currentUser?.nationalId) {
          _showVerificationNotification();
        }
      },
      onError: (error) {
        debugPrint("WebSocket error: $error");
      },
    );
  }

  Future<void> _initNotification() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _showVerificationNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'verification_channel',
      'Verification Status',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      0,
      'Verification Complete',
      'You have been verified by the admin!',
      notificationDetails,
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendImage() async {
    final user = AuthService.getCurrentUser();
    if (_selectedImage == null || user == null) return;

    setState(() => _isLoading = true);

    final bytes = await _selectedImage!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final payload = jsonEncode({
      'type': 'license_upload',
      'senderID': user.nationalId,
      'username': user.name,
      'image': base64Image,
    });

    try {
      if (_channel.closeCode == null) {
        _channel.sink.add(payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image sent successfully!")),
        );
        // Optionally reset image:
        setState(() => _selectedImage = null);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to send image")));
      debugPrint("Send error: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Responder Verification",
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.blue.shade900, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.file_upload,
                        size: 40.sp,
                        color: Colors.blue.shade900,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "Upload Credentials",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.file(
                    _selectedImage!,
                    width: 200.w,
                    height: 200.h,
                    fit: BoxFit.cover,
                  ),
                ),
              SizedBox(height: 20.h),
              if (_selectedImage != null && !_isLoading)
                ElevatedButton.icon(
                  onPressed: _sendImage,
                  icon: const Icon(Icons.send),
                  label: const Text("Send to Admin"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
              if (_isLoading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}


/* void handleWebSocketEvent(uint8_t clientNum, WStype_t type, uint8_t *payload, size_t length) {
  if (type == WStype_TEXT) {
    String msg = String((char *)payload);
    Serial.println("Received: " + msg);

    StaticJsonDocument<1024> doc;
    DeserializationError error = deserializeJson(doc, msg);

    if (error) {
      Serial.println("JSON parse failed!");
      return;
    }

    String messageType = doc["type"];

    if (messageType == "license_upload") {
      String userId = doc["senderID"];
      String username = doc["username"];
      String imageBase64 = doc["image"];

      Serial.println("License upload from: " + userId + ", " + username);
      // ✅ You can store it in SPIFFS or handle it immediately

      // Forward to admin client or store in queue
      // Example: Broadcast it to all:
      webSocket.broadcastTXT(msg);

    } else if (messageType == "verify") {
      String userId = doc["id"];
      String status = doc["status"];

      Serial.println("Verification for: " + userId + ", Status: " + status);

      // Send back to responder
      StaticJsonDocument<200> response;
      response["type"] = "verify";
      response["id"] = userId;
      response["status"] = status;

      String responseStr;
      serializeJson(response, responseStr);
      webSocket.broadcastTXT(responseStr);
    }
  }
} */