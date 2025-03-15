import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lorescue/models/channel_model.dart';

class ChannelCubit extends Cubit<List<Channel>> {
  ChannelCubit() : super([]);

  // Add a new channel
  void addChannel(String name, String description) {
    final newChannel = Channel(name: name, description: description);
    emit([...state, newChannel]); // Update the state
  }

  // Edit a channel
  void editChannel(int index, String newName, String newDescription) {
    final updatedChannels = List<Channel>.from(state);
    updatedChannels[index] = Channel(
      name: newName,
      description: newDescription,
    );
    emit(updatedChannels);
  }

  // Delete a channel
  void deleteChannel(int index) {
    final updatedChannels = List<Channel>.from(state)..removeAt(index);
    emit(updatedChannels);
  }
}
