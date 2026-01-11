import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/trip_invite.dart';
import '../../domain/usecases/get_sent_invites.dart';

part 'sent_invites_state.dart';

class SentInvitesCubit extends Cubit<SentInvitesState> {
  final GetSentInvites getSentInvites;

  SentInvitesCubit({required this.getSentInvites}) : super(const SentInvitesState());

  Future<void> load() async {
    emit(state.copyWith(status: SentInvitesStatus.loading, message: null));
    try {
      final invites = await getSentInvites();
      emit(state.copyWith(status: SentInvitesStatus.loaded, invites: invites));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to load sent invites';
      emit(state.copyWith(status: SentInvitesStatus.error, message: message));
    }
  }
}
