import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<User> users = [];
  List<User> filteredUsers = [];
  TextEditingController searchController = TextEditingController();
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

    _channel.stream.listen((message) async {
      final data = jsonDecode(message);

      // 🔁 Trigger simple reload
      if (data["type"] == "trigger_user_sync") {
        fetchUsers();
      }

      // 📥 Sync full user list
      if (data["type"] == "sync_users" && data["users"] != null) {
        final List<dynamic> receivedUsers = data["users"];
        await UserService().deleteAllUsers(); // clear local db
        for (var u in receivedUsers) {
          await UserService().insertUser(User.fromJson(u));
        }
        fetchUsers(); // reload UI
      }
    });

    fetchUsers(); // initial load
  }

  @override
  void dispose() {
    _channel.sink.close();
    searchController.dispose();
    super.dispose();
  }

  // 🔄 Admin shares users with others
  void broadcastUserList(List<User> users) {
    final userListJson = users.map((u) => u.toJson()).toList();
    final payload = {"type": "sync_users", "users": userListJson};
    _channel.sink.add(jsonEncode(payload));
  }

  Future<void> fetchUsers() async {
    final fetchedUsers = await UserService().getAllUsers();
    setState(() {
      users = fetchedUsers;
      filteredUsers = fetchedUsers;
    });

    broadcastUserList(fetchedUsers); // Notify others with user data
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

  Future<void> deleteUser(User user) async {
    await UserService().deleteUser(user.nationalId);

    final payload = {
      "type": "delete_user",
      "id": user.nationalId,
      "role": user.role,
    };
    _channel.sink.add(jsonEncode(payload));

    fetchUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${user.name} deleted successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchUsers),
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
                              'Role: ${user.role}\nID: ${user.nationalId}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Delete User'),
                                        content: Text(
                                          'Are you sure you want to delete ${user.name}?',
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
                                              deleteUser(user);
                                            },
                                            child: const Text('Delete'),
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
