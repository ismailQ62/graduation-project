import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/services/database/channel_service.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  _ChannelsScreenState createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChannelService _channelService = ChannelService();
  List<Channel> _channels = [];

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    final fetched = await _channelService.getAllChannels();
    setState(() => _channels = fetched);
  }

  /* void _addChannel() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController newChannelController = TextEditingController();
        return AlertDialog(
          title: const Text("Create New Channel"),
          content: TextField(
            controller: newChannelController,
            decoration: const InputDecoration(hintText: "Enter channel name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = newChannelController.text.trim();
                if (name.isNotEmpty) {
                  await _channelService.createChannel(Channel(name: name));
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
  } */

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
        /* actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addChannel,
          ),
        ], */
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            //To check if all channels are being fetched
            ElevatedButton(
              onPressed: () async {
                final channels = await _channelService.getAllChannels();
                for (var c in channels) {
                  print(" CHANNEL: id=${c.id}, name=${c.name}");
                }
              },
              child: const Text("Log All Channels"),
            ),
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
                            /*  trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red[300]),
                              onPressed: () => _confirmDelete(channel),
                            ), */
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.chat,
                                arguments: channel.name,
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      /* bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.verification);
              },
            ),
            IconButton(
              icon: Icon(Icons.chat, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.chat);
              },
            ),
            SizedBox(width: 48.w),
            IconButton(
              icon: Icon(Icons.map, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.map);
              },
            ),
            IconButton(
              icon: Icon(Icons.person, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
          ],
        ),
      ), */
    );
  }
}
