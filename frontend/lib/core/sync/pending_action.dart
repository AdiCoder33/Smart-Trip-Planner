import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class PendingActionType {
  static const String createItinerary = 'CREATE_ITINERARY';
  static const String updateItinerary = 'UPDATE_ITINERARY';
  static const String deleteItinerary = 'DELETE_ITINERARY';
  static const String reorderItinerary = 'REORDER_ITINERARY';
  static const String createPoll = 'CREATE_POLL';
  static const String votePoll = 'VOTE_POLL';
  static const String sendChatMessage = 'SEND_CHAT_MESSAGE';
}

class PendingAction extends Equatable {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const PendingAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  factory PendingAction.create({
    required String type,
    required Map<String, dynamic> payload,
  }) {
    return PendingAction(
      id: const Uuid().v4(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, type, payload, createdAt];
}

class PendingActionAdapter extends TypeAdapter<PendingAction> {
  @override
  final int typeId = 5;

  @override
  PendingAction read(BinaryReader reader) {
    final id = reader.read() as String;
    final type = reader.read() as String;
    final payload = Map<String, dynamic>.from(reader.read() as Map);
    final createdAt = reader.read() as DateTime;
    return PendingAction(
      id: id,
      type: type,
      payload: payload,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter writer, PendingAction obj) {
    writer
      ..write(obj.id)
      ..write(obj.type)
      ..write(obj.payload)
      ..write(obj.createdAt);
  }
}
