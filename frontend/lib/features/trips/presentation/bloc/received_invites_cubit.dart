import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/trip_invite.dart';
import '../../domain/usecases/get_received_invites.dart';

part 'received_invites_state.dart';

class ReceivedInvitesCubit extends Cubit<ReceivedInvitesState> {
  final GetReceivedInvites getReceivedInvites;

  ReceivedInvitesCubit({required this.getReceivedInvites}) : super(const ReceivedInvitesState());

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
}
