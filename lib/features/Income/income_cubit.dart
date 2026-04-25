import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_service.dart';
import 'income_state.dart';

class IncomeCubit extends Cubit<IncomeState> {
  final ApiService _api;
  IncomeCubit(this._api) : super(IncomeInitial());

  Future<void> addIncome(
      String token, {
        required String categoryName,
        required String incomeName,
        required double amount,
        required String date,
        String? notes,
      }) async {
    emit(IncomeLoading());
    try {
      final res = await _api.addIncome(
        token,
        categoryName: categoryName,
        incomeName: incomeName,
        amount: amount,
        date: date,
        notes: notes,
      );

      if (res['success'] == true) {
        emit(IncomeAdded("Added!"));
      } else {
        emit(IncomeFailure(res['error'] ?? 'Add failed'));
      }
    } catch (e) {
      emit(IncomeFailure(e.toString()));
    }
  }

  Future<void> updateIncome({
    required String token,
    required int id,
    required String name,
    required String category,
    required double amount,
  }) async {
    emit(IncomeLoading());
    try {
      final res = await _api.updateIncome(
        token,
        incomeId: id,
        name: name,
        categoryName: category,
        amount: amount,
      );

      if (res['success'] == true) {
        emit(IncomeAdded("Updated!"));
      } else {
        emit(IncomeFailure(res['error'] ?? 'Update failed'));
      }
    } catch (e) {
      emit(IncomeFailure(e.toString()));
    }
  }

  Future<void> deleteIncome(String token, int id) async {
    emit(IncomeLoading());
    try {
      final res = await _api.deleteIncome(token, id);

      if (res['success'] == true) {
        emit(IncomeAdded("Deleted!"));
      } else {
        emit(IncomeFailure(res['error'] ?? 'Delete failed'));
      }
    } catch (e) {
      emit(IncomeFailure(e.toString()));
    }
  }
}