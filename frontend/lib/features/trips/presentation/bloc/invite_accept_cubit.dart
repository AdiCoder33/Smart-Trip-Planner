import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/trip_member.dart';
import '../../domain/usecases/accept_invite.dart';

enum InviteAcceptStatus { initial, loading, success, error }

class InviteAcceptState extends Equatable {
  final InviteAcceptStatus status;
  final TripMemberEntity? member;
  final String? message;

  const InviteAcceptState({
    this.status = InviteAcceptStatus.initial,
    this.member,
    this.message,
  });

  InviteAcceptState copyWith({
    InviteAcceptStatus? status,
    TripMemberEntity? member,
    String? message,
  }) {
    return InviteAcceptState(
      status: status ?? this.status,
      member: member ?? this.member,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, member, message];
}

class InviteAcceptCubit extends Cubit<InviteAcceptState> {
  final AcceptInvite acceptInvite;

  InviteAcceptCubit({required this.acceptInvite}) : super(const InviteAcceptState());

  Future<void> submit(String token) async {
    emit(state.copyWith(status: InviteAcceptStatus.loading, message: null));
    try {
      final member = await acceptInvite(token: token);
      emit(state.copyWith(status: InviteAcceptStatus.success, member: member));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to accept invite';
      emit(state.copyWith(status: InviteAcceptStatus.error, message: message));
    }
  }
}
