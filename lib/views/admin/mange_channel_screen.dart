import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lorescue/cubit/channel_cubit.dart';
import 'package:lorescue/models/channel_model.dart';

class ManageChannelsScreen extends StatelessWidget {
  const ManageChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChannelCubit(),
      child: const ManageChannelsView(),
    );
  }
}

class ManageChannelsView extends StatelessWidget {
  const ManageChannelsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Manage Channels",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.black,
            ), // Changed to 'Add' instead of 'Edit'
            onPressed: () => _showAddChannelDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<ChannelCubit, List<Channel>>(
        builder: (context, channels) {
          return channels.isEmpty
              ? const Center(child: Text("No Channels Available"))
              : ListView.builder(
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  return ListTile(
                    title: Text(
                      channel.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(channel.description),
                    leading: const CircleAvatar(child: Icon(Icons.group)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed:
                          () => _showEditChannelDialog(context, index, channel),
                    ),
                  );
                },
              );
        },
      ),
    );
  }

  void _showAddChannelDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Channel"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Channel Name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      descriptionController.text.isNotEmpty) {
                    context.read<ChannelCubit>().addChannel(
                      nameController.text,
                      descriptionController.text,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  void _showEditChannelDialog(
    BuildContext context,
    int index,
    Channel channel,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: channel.name,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: channel.description,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Channel"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Channel Name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ChannelCubit>().editChannel(
                    index,
                    nameController.text,
                    descriptionController.text,
                  );
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  context.read<ChannelCubit>().deleteChannel(index);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
