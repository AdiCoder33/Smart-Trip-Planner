import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/trip_invite.dart';
import '../../domain/usecases/accept_invite_by_id.dart';
import '../../domain/usecases/decline_invite.dart';
import '../../domain/usecases/get_received_invites.dart';

part 'received_invites_state.dart';

class ReceivedInvitesCubit extends Cubit<ReceivedInvitesState> {
  final GetReceivedInvites getReceivedInvites;
  final AcceptInviteById acceptInviteById;
  final DeclineInvite declineInvite;

  ReceivedInvitesCubit({
    required this.getReceivedInvites,
    required this.acceptInviteById,
    required this.declineInvite,
  }) : super(const ReceivedInvitesState());

  Future<void> load() async {
    emit(state.copyWith(status: ReceivedInvitesStatus.loading, message: null));
    try {
      final invites = await getReceivedInvites();
      emit(state.copyWith(status: ReceivedInvitesStatus.loaded, invites: invites));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to load received invites';
      emit(state.copyWith(status: ReceivedInvitesStatus.error, message: message));
    }
  }

  Future<bool> acceptInvite(String inviteId) async {
    try {
      await acceptInviteById(inviteId: inviteId);
      final updated = state.invites.where((invite) => invite.id != inviteId).toList();
      emit(state.copyWith(invites: updated, message: 'Invite accepted.'));
      return true;
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to accept invite';
      emit(state.copyWith(message: message));
      return false;
    }
  }

  Future<bool> declineInviteById(String inviteId) async {
    try {
      await declineInvite(inviteId: inviteId);
      final updated = state.invites.where((invite) => invite.id != inviteId).toList();
      emit(state.copyWith(invites: updated, message: 'Invite declined.'));
      return true;
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to decline invite';
      emit(state.copyWith(message: message));
      return false;
    }
  }
}
