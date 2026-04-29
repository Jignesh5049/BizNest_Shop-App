import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, AuthException, AuthChangeEvent;
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? phone;
  AuthSignupRequested({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'business',
    this.phone,
  });
  @override
  List<Object?> get props => [name, email, password, role, phone];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthBusinessUpdated extends AuthEvent {
  final Map<String, dynamic> business;
  AuthBusinessUpdated(this.business);
  @override
  List<Object?> get props => [business];
}

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? business;
  final String role;

  AuthAuthenticated({required this.user, this.business, required this.role});

  bool get isBusinessOwner => role == 'business';
  bool get isCustomer => role == 'customer';
  bool get hasOnboarded => business?['isOnboarded'] == true;
  String get userName => user['name'] ?? '';

  @override
  List<Object?> get props => [user, business, role];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _api = ApiService();
  final TokenService _tokenService = TokenService();

  bool get _hasSupabase {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckAuth);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignupRequested>(_onSignup);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthBusinessUpdated>(_onBusinessUpdated);

    if (_hasSupabase) {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedOut) {
          add(AuthCheckRequested());
        }
      });
    }
  }

  Future<void> _onCheckAuth(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final hasJwt = await _tokenService.hasJwtToken();
      if (hasJwt) {
        try {
          final response = await _api.getMe();
          final data = response.data;
          emit(
            AuthAuthenticated(
              user: {
                '_id': data['_id'],
                'name': data['name'],
                'email': data['email'],
                'phone': data['phone'],
              },
              business: data['business'],
              role: data['role'] ?? 'business',
            ),
          );
          return;
        } on DioException catch (e) {
          await _tokenService.clearJwtToken();
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError) {
            emit(AuthUnauthenticated());
            return;
          }
          rethrow;
        }
      }

      final session = _hasSupabase
          ? Supabase.instance.client.auth.currentSession
          : null;
      if (session == null) {
        emit(AuthUnauthenticated());
        return;
      }

      try {
        final response = await _api.getMe();
        final data = response.data;

        emit(
          AuthAuthenticated(
            user: {
              '_id': data['_id'],
              'name': data['name'],
              'email': data['email'],
              'phone': data['phone'],
            },
            business: data['business'],
            role: data['role'] ?? 'business',
          ),
        );
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          emit(
            AuthAuthenticated(
              user: {
                '_id': session.user.id,
                'name': session.user.userMetadata?['name'] ?? 'User',
                'email': session.user.email ?? '',
                'phone': session.user.userMetadata?['phone'],
              },
              role: session.user.userMetadata?['role'] ?? 'business',
            ),
          );
          return;
        }
        rethrow;
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      try {
        final response = await _api.login({
          'email': event.email,
          'password': event.password,
        });

        final data = response.data;
        final token = data['token'];

        await _tokenService.setJwtToken(token);

        emit(
          AuthAuthenticated(
            user: {
              '_id': data['_id'],
              'name': data['name'],
              'email': data['email'],
              'phone': data['phone'],
            },
            business: data['business'],
            role: data['role'] ?? 'business',
          ),
        );
        return;
      } on DioException catch (dioError) {
        if (dioError.type == DioExceptionType.connectionTimeout ||
            dioError.type == DioExceptionType.receiveTimeout) {
          emit(
            AuthError(
              'Login timeout: ${dioError.error ?? 'Request took too long. Check your connection or server status.'}',
            ),
          );
          return;
        }

        if (dioError.type == DioExceptionType.connectionError) {
          emit(
            AuthError(
              'Connection failed: Cannot reach server at 192.168.6.14:5000. Make sure:\n'
              '1. Your device is on the same network\n'
              '2. The server is running\n'
              '3. The IP address is correct',
            ),
          );
          return;
        }
        rethrow;
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignup(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _api.signup({
        'name': event.name,
        'email': event.email,
        'password': event.password,
        'role': event.role,
        'phone': event.phone,
      });

      final data = response.data;
      final token = data['token'];
      await _tokenService.setJwtToken(token);

      emit(
        AuthAuthenticated(
          user: {
            '_id': data['_id'],
            'name': data['name'],
            'email': data['email'],
            'phone': data['phone'],
          },
          business: data['business'],
          role: data['role'] ?? 'business',
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _tokenService.clearAllTokens();
    try {
      if (_hasSupabase) await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    emit(AuthUnauthenticated());
  }

  Future<void> _onBusinessUpdated(
    AuthBusinessUpdated event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is AuthAuthenticated) {
      emit(AuthAuthenticated(user: current.user, business: event.business, role: current.role));
    }
  }
}
