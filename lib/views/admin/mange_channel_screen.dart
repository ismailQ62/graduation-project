import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/database/channel_service.dart';

class ManageChannelsScreen extends StatefulWidget {
  const ManageChannelsScreen({super.key});

  @override
  _ManageChannelsScreenState createState() => _ManageChannelsScreenState();
}

class _ManageChannelsScreenState extends State<ManageChannelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChannelService _channelService = ChannelService();
  final WebSocketService _webSocketService = WebSocketService();

  List<Channel> _channels = [];

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _webSocketService.addListener(_handleWebSocketMessage);
  }

  @override
  void dispose() {
    _webSocketService.removeListener(_handleWebSocketMessage);
    super.dispose();
  }

  void _handleWebSocketMessage(Map<String, dynamic> decoded) async {
    if (decoded['type'] == 'NewChannel') {
      final name = decoded['name'];
      final channelType = decoded['channelType'] ?? '';
      final exists = _channels.any((c) => c.name == name);
      if (!exists) {
        await _channelService.createChannel(
          Channel(name: name, type: channelType),
        );
        await _loadChannels();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("📡 New channel added: $name")));
      }
    }
  }

  Future<void> _loadChannels() async {
    final fetched = await _channelService.getAllChannels();
    setState(() => _channels = fetched);
  }

  void _addChannel() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController newChannelController = TextEditingController();
        String? selectedType;
        final List<String> types = ['main', 'chat', 'alert', 'news'];

        return AlertDialog(
          title: const Text("Create New Channel"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newChannelController,
                decoration: const InputDecoration(
                  hintText: "Enter channel name",
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Type"),
                value: selectedType,
                items:
                    types
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          ),
                        )
                        .toList(),
                onChanged: (val) => selectedType = val,
                validator: (val) => val == null ? 'Please select a type' : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = newChannelController.text.trim();
                if (name.isNotEmpty && selectedType != null) {
                  final newChannel = Channel(name: name, type: selectedType!);
                  await _channelService.createChannel(newChannel);

                  _webSocketService.send(
                    jsonEncode({
                      "type": "NewChannel",
                      "name": name,
                      "channelType": selectedType,
                    }),
                  );

                  Navigator.pop(context);
                  await _loadChannels();
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Channel channel) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Channel"),
            content: Text("Are you sure you want to delete '${channel.name}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await _channelService.deleteChannel(channel.id!);
                  Navigator.pop(context);
                  await _loadChannels();
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Channels",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addChannel,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Search",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child:
                  _channels.isEmpty
                      ? const Center(child: Text("No Channels Available"))
                      : ListView.builder(
                        itemCount: _channels.length,
                        itemBuilder: (context, index) {
                          final channel = _channels[index];
                          final search = _searchController.text.toLowerCase();

                          if (search.isNotEmpty &&
                              !channel.name.toLowerCase().contains(search)) {
                            return const SizedBox.shrink();
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade300,
                              child: const Icon(
                                Icons.group,
                                color: Colors.grey,
                              ),
                            ),
                            title: Text(
                              channel.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("Type: ${channel.type}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red[300]),
                              onPressed: () => _confirmDelete(channel),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.chat,
                                arguments: {
                                  'channel': channel,
                                  'zone': Zone(id: '1', name: 'Zone_1'),
                                },
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
