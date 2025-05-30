import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/controllers/channel_controller.dart';
import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:provider/provider.dart';

class ChannelsScreen extends StatefulWidget {
  final Zone zone;
  const ChannelsScreen({super.key, required this.zone});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  late ChannelController _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ChannelController(widget.zone);
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ChannelController>(
        builder:
            (context, model, child) => Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  "Channels - Zone: ${widget.zone.id}",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                centerTitle: true,
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
                        controller: model.searchController,
                        onChanged: (value) => model.notifyListeners(),
                        decoration: const InputDecoration(
                          hintText: "Search",
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          model.filteredChannels.isEmpty
                              ? const Center(
                                child: Text("No Channels Available"),
                              )
                              : ListView.builder(
                                itemCount: model.filteredChannels.length,
                                itemBuilder: (context, index) {
                                  final channel = model.filteredChannels[index];
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
                                    onTap:
                                        () => model.handleChannelTap(
                                          context,
                                          channel,
                                        ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
