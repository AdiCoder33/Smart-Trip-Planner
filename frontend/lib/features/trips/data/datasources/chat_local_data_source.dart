import 'package:hive/hive.dart';

import '../models/chat_message_model.dart';

class ChatLocalDataSource {
  final Box<ChatMessageModel> box;

  const ChatLocalDataSource(this.box);

  Future<List<ChatMessageModel>> getMessages(String tripId) async {
    final messages = box.values.where((message) => message.tripId == tripId).toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> cacheMessages(String tripId, List<ChatMessageModel> messages) async {
    final idsToRemove = box.values
        .where((message) => message.tripId == tripId)
        .map((message) => message.id)
        .toList();
    await box.deleteAll(idsToRemove);
    final map = {for (final message in messages) message.id: message};
    await box.putAll(map);
  }

  Future<void> upsertMessage(ChatMessageModel message) async {
    await box.put(message.id, message);
  }
}
