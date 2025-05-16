import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

String formatDateWithTime(String? isoDate) {
  if (isoDate == null) return "Unknown";
  try {
    final parsed = DateTime.parse(isoDate);
    final year = parsed.year.toString().padLeft(4, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return "$year-$month-$day • $hour:$minute";
  } catch (e) {
    return "Invalid Date";
  }
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<User> users = [];
  List<User> filteredUsers = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  late WebSocketChannel _channel;
  final webSocketService = WebSocketService();
  final userservice = UserService();

  @override
  void initState() {
    super.initState();
    //_channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

    if (!webSocketService.isConnected) {
      print('🔌 WebSocket not connected. Connecting...');
      webSocketService.connect('ws://192.168.4.1:81');
    } else {
      print('✅ WebSocket already connected.');
    }
    _listenToWebSocket();

    fetchUsers();
  }

  void _handleWebSocketMessage(Map<String, dynamic> decoded) async {
    try {
      final type = decoded['type'] ?? '';
      final national_id = decoded['national_id'] ?? '';
      final name = decoded['name'] ?? '';
      final role = decoded['role'] ?? '';
      final zoneID = decoded['zoneID'] ?? '';
      //_receiverZone = Zone.fromMap(decoded['receivedZone'] ?? {});

      if (type == 'NewUser') {
        setState(() {
          if (!users.any((z) => z.nationalId == national_id)) {
            final newUser = User(
              name: name,
              nationalId: national_id,
              password: " ",
              role: role,
              connectedZoneId: zoneID,
            );

            addUser(newUser);
          }
        });
      }
    } catch (e) {
      print("Error handling WebSocket message: $e");
    }
  }

  void _listenToWebSocket() {
    WebSocketService().addListener(_handleWebSocketMessage);
  }

  void addUser(User user) async {
    await userservice.insertUser(user);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("New user added successfully!")));
  }

  @override
  void dispose() {
    //_channel.sink.close();
    searchController.dispose();
     WebSocketService().removeListener(_handleWebSocketMessage);
    super.dispose();
  }

  void broadcastUserList(List<User> users) {
    final userListJson = users.map((u) => u.toJson()).toList();
    final payload = {"type": "sync_users", "users": userListJson};
    _channel.sink.add(jsonEncode(payload));
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);

    print("🔄 Reloading users at ${DateTime.now()}");
    final fetchedUsers = await UserService().getAllUsers();
    print("📦 Users fetched: ${fetchedUsers.length}");

    setState(() {
      users = fetchedUsers;
      filteredUsers = fetchedUsers;
    });

    broadcastUserList(fetchedUsers);
    print("📡 Users broadcasted to ESP.");

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => isLoading = false);
  }

  void searchUsers(String query) {
    final results =
        users.where((user) {
          final nameMatch = user.name.toLowerCase().contains(
            query.toLowerCase(),
          );
          final roleMatch = user.role.toLowerCase().contains(
            query.toLowerCase(),
          );
          return nameMatch || roleMatch;
        }).toList();

    setState(() {
      filteredUsers = results;
    });
  }

  Future<void> blockUser(User user) async {
    final payload = {"type": "block", "id": user.nationalId, "role": user.role};
    _channel.sink.add(jsonEncode(payload));
    await UserService().blockUser(user.nationalId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${user.name} has been blocked.")));
    await fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          isLoading
              ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
              : IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await fetchUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Users synced .")),
                  );
                },
              ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: searchUsers,
              decoration: InputDecoration(
                hintText: 'Search by name or role',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                filteredUsers.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  user.role == "Admin"
                                      ? Colors.blue
                                      : user.role == "Responder"
                                      ? Colors.green
                                      : Colors.grey,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Text(
                              'Role: ${user.role}\nID: ${user.nationalId}\nCreated At: ${formatDateWithTime(user.createdAt)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.block,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Block User'),
                                        content: Text(
                                          'Are you sure you want to block ${user.name}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              blockUser(user);
                                            },
                                            child: const Text('Block'),
                                          ),
                                        ],
                                      ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
