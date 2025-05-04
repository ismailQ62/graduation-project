import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ValueNotifier<List<Map<String, dynamic>>> pendingResponders =
      ValueNotifier([]);
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();

    channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

    // ✅ Uncomment below for testing UI with dummy data
    /*
    final dummyImage = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
    );
    pendingResponders.value = [
      {'id': 'R12345', 'name': 'Ali Hammoudeh', 'imageBytes': dummyImage},
      {'id': 'R67890', 'name': 'Sara Qasem', 'imageBytes': dummyImage},
    ];
    */

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'verification') {
        final imageBytes = base64Decode(data['image']);
        pendingResponders.value = List.from(pendingResponders.value)..add({
          'id': data['senderID'] ?? 'R000',
          'name': data['username'] ?? 'Responder',
          'imageBytes': imageBytes,
        });
      }
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void _approveUser(BuildContext context, Map<String, dynamic> user) {
    final message = jsonEncode({
      'type': 'verify',
      'id': user['id'],
      'status': 'approved',
    });
    channel.sink.add(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${user['name']} approved"),
        backgroundColor: Colors.green,
      ),
    );

    pendingResponders.value = List.from(pendingResponders.value)..remove(user);
  }

  void _rejectUser(BuildContext context, Map<String, dynamic> user) {
    final message = jsonEncode({
      'type': 'verify',
      'id': user['id'],
      'status': 'rejected',
    });
    channel.sink.add(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${user['name']} rejected"),
        backgroundColor: Colors.red,
      ),
    );

    pendingResponders.value = List.from(pendingResponders.value)..remove(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Verifications'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: pendingResponders,
          builder: (context, list, _) {
            if (list.isEmpty) {
              return Center(
                child: Text(
                  'No pending verifications.',
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final user = list[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name: ${user['name']}",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "ID: ${user['id']}",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        SizedBox(height: 12.h),
                        user['imageBytes'] != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.memory(
                                user['imageBytes'] as Uint8List,
                                width: double.infinity,
                                height: 200.h,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Container(
                              width: double.infinity,
                              height: 200.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                color: Colors.grey.shade200,
                              ),
                              child: Text(
                                "No image uploaded",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _approveUser(context, user),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.green,
                              ),
                              child: const Text("Approve"),
                            ),
                            TextButton(
                              onPressed: () => _rejectUser(context, user),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text("Reject"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
