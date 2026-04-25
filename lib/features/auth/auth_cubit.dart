import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiService _api;
  AuthCubit(this._api) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final res = await _api.login(email, password);
      if (res['success'] == true && res['data'] != null) {
        final token = res['data'].toString();
        emit(AuthSuccess(token: token));
      } else {
        final err = res['error'] ?? res['message'] ?? 'Login Failed';
        if (err.toString().contains('Confirm')) {
          emit(AuthEmailNotConfirmed());
        }else {
          emit(AuthFailure('Token is null'));
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('Confirm')) {
        emit(AuthEmailNotConfirmed());
      } else {
        emit(AuthFailure(msg));
      }
    }
  }

  Future<void> register(
      String fullName,
      String email,
      String password,
      double budget,
      ) async {
    emit(AuthLoading());
    try {
      final res =
      await _api.register(fullName, email, password, password, budget);
      if (res['success'] == true) {
        emit(AuthSuccess(message: res['message'] ?? 'Registered! Check email.'));
      } else {
        emit(AuthFailure(res['error'] ?? res['message'] ?? 'Register Failed'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    try {
      await _api.forgotPassword(
          email, 'https://budgetapptry.runasp.net/reset-password');
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> resetPassword(
      String email, String token, String password) async {
    emit(AuthLoading());
    try {
      final res =
      await _api.resetPassword(email, token, password, password);
      if (res['success'] == true) {
        emit(AuthPasswordResetSuccess());
      } else {
        emit(AuthFailure(res['error'] ?? res['message'] ?? 'Reset Failed'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> resendConfirmation(String email) async {
    emit(AuthLoading());
    try {
      await _api.resendConfirmationEmail(email);
      emit(AuthSuccess(message: 'Confirmation email resent!'));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}