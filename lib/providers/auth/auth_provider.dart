import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/google_drive_storage.dart';
import '../../ui/router/app_router.dart';

final googleDriveStorageProvider = Provider<GoogleDriveStorage>((ref) {
  return GoogleDriveStorage();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(googleDriveStorageProvider);
  final notifier = AuthNotifier(storage);
  notifier.initialize();
  return notifier;
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? userEmail;
  final String? userName;
  final String? userPhotoUrl;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.error,
    this.userEmail,
    this.userName,
    this.userPhotoUrl,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? userEmail,
    String? userName,
    String? userPhotoUrl,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final GoogleDriveStorage _storage;

  AuthNotifier(this._storage) : super(const AuthState());

  Future<void> initialize() async {
    try {
      await _storage.initialize();
      if (_storage.isAuthenticated) {
        final user = _storage.currentAccount;
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          userEmail: user?.email,
          userName: user?.displayName,
          userPhotoUrl: user?.photoUrl,
        );
        authRouterNotifier.update(true);
      } else {
        state = const AuthState(isAuthenticated: false, isLoading: false);
        authRouterNotifier.update(false);
      }
    } catch (e) {
      state = AuthState(isAuthenticated: false, isLoading: false, error: e.toString());
      authRouterNotifier.update(false);
    }
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _storage.signIn();
      final user = _storage.currentAccount;
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userEmail: user?.email,
        userName: user?.displayName,
        userPhotoUrl: user?.photoUrl,
      );
      authRouterNotifier.update(true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      authRouterNotifier.update(false);
    }
  }

  Future<void> signOut() async {
    await _storage.logout();
    state = const AuthState(isAuthenticated: false, isLoading: false);
    authRouterNotifier.update(false);
  }
}
