import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../constants/api_constants.dart';

class AuthResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? user;

  const AuthResponse({
    required this.success,
    required this.message,
    this.user,
  });
}

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isSessionReady;
  final String? errorMessage;
  final Map<String, dynamic>? user;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isSessionReady = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isSessionReady,
    String? errorMessage,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isSessionReady: isSessionReady ?? this.isSessionReady,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    checkToken();
  }

  Future<void> checkToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isAuthenticated: false,
          isSessionReady: true,
          user: null,
        );
        return;
      }

      // Validate token against backend /auth/me
      final response = await ApiClient.get(ApiConstants.me);

      if (response['success'] == true && response['user'] != null) {
        final userData = response['user'] is Map<String, dynamic>
            ? response['user'] as Map<String, dynamic>
            : Map<String, dynamic>.from(response['user']);

        await prefs.setString('user_name', userData['name'] ?? '');
        await prefs.setString('user_email', userData['email'] ?? '');
        if (userData['_id'] != null) {
          await prefs.setString('user_id', userData['_id'].toString());
        }

        state = state.copyWith(
          isAuthenticated: true,
          isSessionReady: true,
          user: userData,
        );
      } else {
        // If server returns 401 Unauthorized, token has expired or is invalid
        final statusCode = response['statusCode'];
        if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
          await prefs.remove('jwt_token');
          await prefs.remove('user_name');
          await prefs.remove('user_email');
          await prefs.remove('user_id');
          state = state.copyWith(
            isAuthenticated: false,
            isSessionReady: true,
            user: null,
          );
        } else {
          // If offline / network failure, keep previously cached session
          final cachedName = prefs.getString('user_name');
          final cachedEmail = prefs.getString('user_email');
          if (cachedEmail != null && cachedEmail.isNotEmpty) {
            state = state.copyWith(
              isAuthenticated: true,
              isSessionReady: true,
              user: {
                'name': cachedName ?? 'Rider',
                'email': cachedEmail,
              },
            );
          } else {
            state = state.copyWith(
              isAuthenticated: false,
              isSessionReady: true,
              user: null,
            );
          }
        }
      }
    } catch (_) {
      state = state.copyWith(
        isAuthenticated: false,
        isSessionReady: true,
        user: null,
      );
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final normalizedEmail = email.trim().toLowerCase();
    final response = await ApiClient.post(ApiConstants.login, {
      'email': normalizedEmail,
      'password': password,
    });

    if (response['success'] == true && response['token'] != null) {
      final token = response['token'] as String;
      final userData = response['user'] is Map<String, dynamic>
          ? response['user'] as Map<String, dynamic>
          : <String, dynamic>{};

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('user_name', userData['name'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? normalizedEmail);
      if (userData['id'] != null || userData['_id'] != null) {
        await prefs.setString('user_id', (userData['id'] ?? userData['_id']).toString());
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: userData,
        errorMessage: null,
      );

      return AuthResponse(
        success: true,
        message: response['message'] ?? 'Logged in successfully',
        user: userData,
      );
    } else {
      final errorMsg = response['message'] ?? 'Login failed. Please check your credentials.';
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: errorMsg,
      );

      return AuthResponse(
        success: false,
        message: errorMsg,
      );
    }
  }

  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final normalizedEmail = email.trim().toLowerCase();
    final response = await ApiClient.post(ApiConstants.signup, {
      'name': name.trim(),
      'email': normalizedEmail,
      'password': password,
      'confirmPassword': confirmPassword,
      'phone': phone?.trim() ?? '',
    });

    if (response['success'] == true) {
      state = state.copyWith(isLoading: false, errorMessage: null);
      return AuthResponse(
        success: true,
        message: response['message'] ?? 'Account created successfully! Please sign in.',
        user: response['user'] is Map<String, dynamic> ? response['user'] as Map<String, dynamic> : null,
      );
    } else {
      final errorMsg = response['message'] ?? 'Registration failed. Please try again.';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return AuthResponse(
        success: false,
        message: errorMsg,
      );
    }
  }

  Future<AuthResponse> forgotPassword(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final response = await ApiClient.post(ApiConstants.forgotPassword, {
      'email': normalizedEmail,
    });

    final success = response['success'] == true;
    final message = response['message'] ?? (success ? 'Reset request registered.' : 'Request failed.');

    return AuthResponse(
      success: success,
      message: message,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
    state = const AuthState(isAuthenticated: false, isSessionReady: true, user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
