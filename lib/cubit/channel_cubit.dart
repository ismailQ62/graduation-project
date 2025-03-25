import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lorescue/models/channel_model.dart';

class ChannelCubit extends Cubit<List<Channel>> {
  ChannelCubit() : super([]);

  void addChannel(String name, String description) {
    final newChannel = Channel(name: name); // description: description);
    emit([...state, newChannel]);
  }

  void editChannel(int index, String newName, String newDescription) {
    final updatedChannels = List<Channel>.from(state);
    updatedChannels[index] = Channel(
      name: newName,
      //  description: newDescription,
    );
    emit(updatedChannels);
  }

  void deleteChannel(int index) {
    final updatedChannels = List<Channel>.from(state)..removeAt(index);
    emit(updatedChannels);
  }
}
