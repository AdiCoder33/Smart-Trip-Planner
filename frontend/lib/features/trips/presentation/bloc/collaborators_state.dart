part of 'collaborators_bloc.dart';

enum CollaboratorsStatus { initial, loading, loaded, error }

class CollaboratorsState extends Equatable {
  final CollaboratorsStatus status;
  final List<TripMemberEntity> members;
  final List<TripInviteEntity> invites;
  final List<UserLookupEntity> searchResults;
  final bool isRefreshing;
  final bool isSearching;
  final String searchQuery;
  final String? message;
  final String? tripId;

  const CollaboratorsState({
    this.status = CollaboratorsStatus.initial,
    this.members = const [],
    this.invites = const [],
    this.searchResults = const [],
    this.isRefreshing = false,
    this.isSearching = false,
    this.searchQuery = '',
    this.message,
    this.tripId,
  });

  CollaboratorsState copyWith({
    CollaboratorsStatus? status,
    List<TripMemberEntity>? members,
    List<TripInviteEntity>? invites,
    List<UserLookupEntity>? searchResults,
    bool? isRefreshing,
    bool? isSearching,
    String? searchQuery,
    String? message,
    String? tripId,
  }) {
    return CollaboratorsState(
      status: status ?? this.status,
      members: members ?? this.members,
      invites: invites ?? this.invites,
      searchResults: searchResults ?? this.searchResults,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      message: message,
      tripId: tripId ?? this.tripId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        members,
        invites,
        searchResults,
        isRefreshing,
        isSearching,
        searchQuery,
        message,
        tripId,
      ];
}
