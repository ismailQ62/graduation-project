import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lorescue/controllers/user_controller.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:lorescue/models/user_model.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final UserController _controller = UserController();
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _controller.fetchBlockedUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Blocked Users')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.blockedUsers.isEmpty) {
            return Center(child: Text('No blocked users.'));
          }

          return ListView.builder(
            itemCount: _controller.blockedUsers.length,
            itemBuilder: (context, index) {
              final user = _controller.blockedUsers[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.role),
                trailing: IconButton(
                  icon: Icon(Icons.lock_open, color: Colors.green),
                  onPressed: () => _onUnblockUser(user),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onUnblockUser(User user) async {
    if (!mounted) return;

    final success = await _controller.unblockUser(
      user: user,
      confirmUnblock: (user) async {
        if (!mounted) return false;
        return await _showConfirmationDialog(user);
      },
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${user.name} has been unblocked.")),
      );
    }
  }

  Future<bool> _showConfirmationDialog(User user) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: Text("Unblock User"),
                content: Text("Are you sure you want to unblock ${user.name}?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text("Unblock"),
                  ),
                ],
              ),
        ) ??
        false;
  }
}
