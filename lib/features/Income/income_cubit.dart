
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
        emit(IncomeAdded(res['message'] ?? 'Income Added'));
      } else {
        emit(IncomeFailure(res['error'] ?? res['message'] ?? 'Add Income Failed'));
      }
    } catch (e) {
      emit(IncomeFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}