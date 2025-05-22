import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/services/WebSocketService.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ValueNotifier<List<Map<String, dynamic>>> pendingResponders =
      ValueNotifier([]);
  final webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _listenToWebSocket();
  }

  void _listenToWebSocket() {
    if (!webSocketService.isConnected) {
      webSocketService.connect('ws://192.168.4.1:81');
    }
    WebSocketService().addListener(_handleWebSocketMessage);
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) async {
    final type = message['type'];
    if (type == 'license_text') {
      final responder = {
        'id': message['senderID'] ?? 'unknown',
        'name': message['username'] ?? 'Responder',
        'role': message['role'] ?? 'N/A',
        'description': message['description'] ?? '',
      };

      final currentList = List<Map<String, dynamic>>.from(
        pendingResponders.value,
      );
      final isDuplicate = currentList.any((e) => e['id'] == responder['id']);
      if (!isDuplicate) {
        pendingResponders.value = [...currentList, responder];
      }
    }
  }

  @override
  void dispose() {
    webSocketService.removeListener(_handleWebSocketMessage);
    super.dispose();
  }

  void _approveUser(BuildContext context, Map<String, dynamic> user) {
    Map<String, dynamic> messageJson = {
      'type': 'verify',
      'id': user['id'],
      'status': 'approved',
    };
    webSocketService.send(jsonEncode(messageJson));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${user['name']} approved \u2705"),
        backgroundColor: Colors.green,
      ),
    );
    pendingResponders.value = List.from(pendingResponders.value)..remove(user);
  }

  void _rejectUser(BuildContext context, Map<String, dynamic> user) {
    Map<String, dynamic> messageJson = {
      'type': 'verify',
      'id': user['id'],
      'status': 'rejected',
    };
    webSocketService.send(jsonEncode(messageJson));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${user['name']} rejected \u274c"),
        backgroundColor: Colors.red,
      ),
    );

    pendingResponders.value = List.from(pendingResponders.value)..remove(user);
  }

  //Simulates a responder submission
  void _simulateTestResponder() {
    final demo = {
      'type': 'license_text',
      'senderID': '999',
      'username': 'Demo User',
      'role': 'Firefighter',
      'description': 'I have completed fire rescue training and serve Zone 3.',
    };

    final currentList = List<Map<String, dynamic>>.from(
      pendingResponders.value,
    );
    final isDuplicate = currentList.any((e) => e['id'] == demo['senderID']);
    if (!isDuplicate) {
      pendingResponders.value = [
        ...currentList,
        {
          'id': demo['senderID'],
          'name': demo['username'],
          'role': demo['role'],
          'description': demo['description'],
        },
      ];
    }
    print("\ud83d\udd2a Simulated responder added: ${demo['username']}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Verifications'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          // ✅ Demo simulation button
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: "Simulate Responder",
            onPressed: _simulateTestResponder,
          ),
        ],
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
                        Text(
                          "Role: ${user['role']}",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Description:",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          user['description'],
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        const SizedBox(height: 16),
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
