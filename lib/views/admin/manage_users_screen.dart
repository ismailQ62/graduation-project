import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lorescue/controllers/user_controller.dart';
import 'package:provider/provider.dart';
import 'package:lorescue/models/user_model.dart';

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
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userController = Provider.of<UserController>(context, listen: false);
    userController.listenToWebSocket();
    Future.microtask(() {
      userController.fetchUsers();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    final userController = Provider.of<UserController>(context, listen: false);
    userController.removeWebSocketListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
      builder: (context, userController, child) {
        final filteredUsers = userController.filteredUsers;
        final currentNationalId = userController.userData?['nationalId'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Users'),
            actions: [
              userController.isLoading
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
                      await userController.fetchUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Users synced.")),
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
                  onChanged: userController.searchUsers,
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
                            final isSelf = user.nationalId == currentNationalId;

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
                                trailing:
                                    (user.role == "Admin")
                                        ? null
                                        : IconButton(
                                          icon: const Icon(
                                            Icons.block,
                                            color: Colors.orange,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text(
                                                      'Block User',
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to block ${user.name}?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          userController
                                                              .blockUser(
                                                                user,
                                                                context,
                                                              );
                                                        },
                                                        child: const Text(
                                                          'Block',
                                                        ),
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
      },
    );
  }
}
