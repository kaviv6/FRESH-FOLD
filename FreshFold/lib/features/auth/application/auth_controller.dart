import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/push/push_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../models/auth_result.dart';
import '../data/auth_repository.dart';

enum SessionStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    this.status = SessionStatus.unknown,
    this.userId,
    this.name,
    this.isRider = false,
    this.isAdmin = false,
    this.errorMessage,
  });

  final SessionStatus status;
  final int? userId;
  final String? name;
  final bool isRider;
  final bool isAdmin;
  final String? errorMessage;

  AppRole get role {
    if (isAdmin) return AppRole.admin;
    if (isRider) return AppRole.rider;
    return AppRole.customer;
  }

  AuthState copyWith({
    SessionStatus? status,
    int? userId,
    String? name,
    bool? isRider,
    bool? isAdmin,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isRider: isRider ?? this.isRider,
      isAdmin: isAdmin ?? this.isAdmin,
      errorMessage: errorMessage,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref, ref.watch(authRepositoryProvider), ref.watch(authStorageProvider));
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref, this._repository, this._storage) : super(const AuthState());

  final Ref _ref;
  final AuthRepository _repository;
  final AuthStorage _storage;

  /// Called once on app start to restore a persisted session without
  /// hitting the network.
  Future<void> restoreSession() async {
    final saved = await _storage.readAll();
    final token = saved['token'];
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: SessionStatus.unauthenticated);
      return;
    }
    state = AuthState(
      status: SessionStatus.authenticated,
      userId: int.tryParse(saved['userId'] ?? ''),
      name: saved['name'],
      isRider: saved['isRider'] == 'true',
      isAdmin: saved['isAdmin'] == 'true',
    );
    unawaited(registerPushToken(_ref));
  }

  Future<bool> login({required String username, required String password}) async {
    try {
      final result = await _repository.login(username: username, password: password);
      await _persist(result);
      return true;
    } catch (e) {
      state = state.copyWith(status: SessionStatus.unauthenticated, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String login,
    required String password,
    String? mobile,
    String? street,
    String? city,
  }) async {
    try {
      final result = await _repository.signup(
        name: name,
        login: login,
        password: password,
        mobile: mobile,
        street: street,
        city: city,
      );
      await _persist(result);
      return true;
    } catch (e) {
      state = state.copyWith(status: SessionStatus.unauthenticated, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> _persist(AuthResult result) async {
    await _storage.saveSession(
      token: result.token,
      userId: result.userId,
      name: result.name,
      isRider: result.isRider,
      isAdmin: result.isAdmin,
    );
    state = AuthState(
      status: SessionStatus.authenticated,
      userId: result.userId,
      name: result.name,
      isRider: result.isRider,
      isAdmin: result.isAdmin,
    );
    unawaited(registerPushToken(_ref));
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Best-effort server-side revoke; always clear local session below.
    }
    await _storage.clear();
    state = const AuthState(status: SessionStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
