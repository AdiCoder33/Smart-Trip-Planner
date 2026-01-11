import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/trip_invite.dart';
import '../../domain/entities/trip_member.dart';
import '../../domain/entities/user_lookup.dart';
import '../../domain/usecases/get_trip_invites.dart';
import '../../domain/usecases/get_trip_members.dart';
import '../../domain/usecases/revoke_invite.dart';
import '../../domain/usecases/search_trip_users.dart';
import '../../domain/usecases/send_trip_invite.dart';

part 'collaborators_event.dart';
part 'collaborators_state.dart';

class CollaboratorsBloc extends Bloc<CollaboratorsEvent, CollaboratorsState> {
  final GetTripMembers getTripMembers;
  final GetTripInvites getTripInvites;
  final SendTripInvite sendTripInvite;
  final RevokeInvite revokeInvite;
  final SearchTripUsers searchTripUsers;
  final ConnectivityService connectivityService;

  CollaboratorsBloc({
    required this.getTripMembers,
    required this.getTripInvites,
    required this.sendTripInvite,
    required this.revokeInvite,
    required this.searchTripUsers,
    required this.connectivityService,
  }) : super(const CollaboratorsState()) {
    on<CollaboratorsStarted>(_onStarted);
    on<CollaboratorsRefreshed>(_onRefreshed);
    on<InviteSent>(_onInviteSent);
    on<InviteRevoked>(_onInviteRevoked);
    on<CollaboratorsSearchRequested>(_onSearchRequested);
  }

  Future<void> _onStarted(CollaboratorsStarted event, Emitter<CollaboratorsState> emit) async {
    emit(state.copyWith(
      status: CollaboratorsStatus.loading,
      message: null,
      tripId: event.tripId,
      searchResults: const [],
      searchQuery: '',
      isSearching: false,
    ));
    try {
      final members = await getTripMembers(event.tripId);
      List<TripInviteEntity> invites = [];
      try {
        invites = await getTripInvites(event.tripId);
      } catch (_) {}
      emit(state.copyWith(
        status: CollaboratorsStatus.loaded,
        members: members,
        invites: invites,
      ));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to load collaborators';
      emit(state.copyWith(status: CollaboratorsStatus.error, message: message));
    }
  }

  Future<void> _onRefreshed(CollaboratorsRefreshed event, Emitter<CollaboratorsState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline.'));
      return;
    }
    emit(state.copyWith(isRefreshing: true, message: null));
    try {
      final members = await getTripMembers(event.tripId);
      List<TripInviteEntity> invites = [];
      try {
        invites = await getTripInvites(event.tripId);
      } catch (_) {}
      emit(state.copyWith(
        status: CollaboratorsStatus.loaded,
        members: members,
        invites: invites,
        isRefreshing: false,
      ));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to refresh collaborators';
      emit(state.copyWith(isRefreshing: false, message: message));
    }
  }

  Future<void> _onInviteSent(InviteSent event, Emitter<CollaboratorsState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline. Invites are disabled.'));
      return;
    }

    try {
      final invite = await sendTripInvite(
        tripId: event.tripId,
        email: event.email,
        role: event.role,
      );
      final updated = [invite, ...state.invites];
      final updatedResults = state.searchResults
          .where((user) => user.email.toLowerCase() != invite.email.toLowerCase())
          .toList();
      emit(state.copyWith(
        invites: updated,
        searchResults: updatedResults,
        message: 'Invite sent.',
      ));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to send invite';
      emit(state.copyWith(message: message));
    }
  }

  Future<void> _onInviteRevoked(InviteRevoked event, Emitter<CollaboratorsState> emit) async {
    try {
      final revoked = await revokeInvite(inviteId: event.inviteId);
      final updated = state.invites.where((invite) => invite.id != revoked.id).toList();
      emit(state.copyWith(invites: updated, message: 'Invite revoked.'));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to revoke invite';
      emit(state.copyWith(message: message));
    }
  }

  Future<void> _onSearchRequested(
    CollaboratorsSearchRequested event,
    Emitter<CollaboratorsState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(
        searchResults: const [],
        isSearching: false,
        searchQuery: '',
      ));
      return;
    }

    if (query.length < 2) {
      emit(state.copyWith(
        searchResults: const [],
        isSearching: false,
        searchQuery: query,
      ));
      return;
    }

    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(
        isSearching: false,
        message: 'You are offline. Search is unavailable.',
      ));
      return;
    }

    emit(state.copyWith(isSearching: true, searchQuery: query, message: null));
    try {
      final results = await searchTripUsers(tripId: event.tripId, query: query);
      emit(state.copyWith(searchResults: results, isSearching: false));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to search users';
      emit(state.copyWith(isSearching: false, message: message));
    }
  }
}
