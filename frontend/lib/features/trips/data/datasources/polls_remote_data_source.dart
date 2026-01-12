import 'package:dio/dio.dart';

import '../models/poll_model.dart';

class PollsRemoteDataSource {
  final Dio dio;

  const PollsRemoteDataSource(this.dio);

  Future<List<PollModel>> fetchPolls(String tripId) async {
    final response = await dio.get('/api/trips/$tripId/polls');
    final data = response.data as List;
    return data
        .map((item) => PollModel.fromJson(item as Map<String, dynamic>, tripId: tripId))
        .toList();
  }

  Future<PollModel> createPoll({
    required String tripId,
    required String question,
    required List<String> options,
  }) async {
    final response = await dio.post('/api/trips/$tripId/polls', data: {
      'question': question,
      'options': options,
    });
    return PollModel.fromJson(response.data as Map<String, dynamic>, tripId: tripId);
  }

  Future<PollModel> vote({
    required String pollId,
    required String optionId,
    required String tripId,
  }) async {
    final response = await dio.post('/api/polls/$pollId/vote', data: {'option_id': optionId});
    return PollModel.fromJson(response.data as Map<String, dynamic>, tripId: tripId);
  }

  Future<PollModel> updatePoll({
    required String pollId,
    required String tripId,
    required String question,
    required List<String> options,
  }) async {
    final response = await dio.patch('/api/polls/$pollId', data: {
      'question': question,
      'options': options,
    });
    return PollModel.fromJson(response.data as Map<String, dynamic>, tripId: tripId);
  }

  Future<void> deletePoll({required String pollId}) async {
    await dio.delete('/api/polls/$pollId');
  }
}
