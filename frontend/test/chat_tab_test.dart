import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_trip_planner/core/connectivity/connectivity_cubit.dart';
import 'package:smart_trip_planner/features/auth/domain/entities/user.dart';
import 'package:smart_trip_planner/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/chat_message.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/trip.dart';
import 'package:smart_trip_planner/features/trips/presentation/bloc/chat_bloc.dart';
import 'package:smart_trip_planner/features/trips/presentation/screens/chat_tab.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ChatState());
  });

  testWidgets('renders chat messages and input', (tester) async {
    final chatBloc = MockChatBloc();
    final authBloc = MockAuthBloc();
    final connectivityCubit = MockConnectivityCubit();

    final message = ChatMessageEntity(
      id: 'msg1',
      tripId: 'trip1',
      senderId: 'user1',
      content: 'Hello',
      createdAt: DateTime(2024, 1, 1, 10),
    );
    final chatState = ChatState(
      status: ChatStatus.loaded,
      messages: [message],
      tripId: 'trip1',
      connectionStatus: ChatConnectionStatus.connected,
    );
    const authState = AuthState(
      status: AuthStatus.authenticated,
      user: UserEntity(id: 'user1', email: 'user@example.com'),
    );
    const connectivityState = ConnectivityState(isOnline: true);

    when(() => chatBloc.state).thenReturn(chatState);
    whenListen(chatBloc, Stream.value(chatState), initialState: chatState);
    when(() => authBloc.state).thenReturn(authState);
    whenListen(authBloc, Stream.value(authState), initialState: authState);
    when(() => connectivityCubit.state).thenReturn(connectivityState);
    whenListen(
      connectivityCubit,
      Stream<ConnectivityState>.value(connectivityState),
      initialState: connectivityState,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ChatBloc>.value(value: chatBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ChatTab(trip: TripEntity(id: 'trip1', title: 'Trip')),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
