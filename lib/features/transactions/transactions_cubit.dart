
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_service.dart';
import 'transactions_state.dart';

class TransactionsCubit extends Cubit<TransactionsState> {
  final ApiService _api;
  TransactionsCubit(this._api) : super(TransactionsInitial());

  List<dynamic> _allTransactions = [];

  Future<void> loadTransactions(String token,
      {int page = 1, String? orderBy}) async {
    if (page == 1) {
      _allTransactions = [];
      emit(TransactionsLoading());
    } else {
      emit(TransactionsLoadingMore(
        transactions: _allTransactions,
        hasNext: true,
        currentPage: page - 1,
      ));
    }
    try {
      final res =
      await _api.getAllTransactions(token, page, orderBy: orderBy);
      final list = (res['data'] as List?) ?? [];
      final hasNext = res['hasNextData'] == true;
      if (page == 1) {
        _allTransactions = list;
      } else {
        _allTransactions = [..._allTransactions, ...list];
      }
      emit(TransactionsLoaded(
        transactions: List.from(_allTransactions),
        hasNext: hasNext,
        currentPage: page,
      ));
    } catch (e) {
      emit(TransactionsFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> addExpense(String token,
      {required double amount,
        required String name,
        required String date,
        required String categoryName,
        required int paymentMethod,
        String? notes}) async {
    emit(TransactionsLoading());
    try {
      final res = await _api.addExpense(token,
          amount: amount,
          name: name,
          date: date,
          categoryName: categoryName,
          paymentMethod: paymentMethod,
          notes: notes);

      if (res['success'] == true) {
        final data = res['data'];
        int? expenseId;
        String message = 'Expense Added';
        int? status;

        if (data is Map<String, dynamic>) {
          expenseId = data['expenseId'] as int? ??
              data['id'] as int? ??
              data['ExpenseId'] as int?;
          message = data['message']?.toString() ??
              res['message']?.toString() ??
              'Expense Added';
          status = data['status'] as int?;
        } else if (data is int) {
          expenseId = data;
          message = res['message']?.toString() ?? 'Expense Added';
        } else {
          message = res['message']?.toString() ?? 'Expense Added';
        }

        emit(TransactionAdded(
            message: message, status: status, expenseId: expenseId));
      } else {
        emit(TransactionsFailure(
            res['error'] ?? res['message'] ?? 'Add Expense Failed'));
      }
    } catch (e) {
      emit(TransactionsFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> deleteTransaction(String token, int expenseId) async {
    try {
      await _api.deleteTransaction(token, expenseId);
      emit(TransactionDeleted());
    } catch (e) {
      emit(TransactionsFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> searchTransactions(String token, String query) async {
    emit(TransactionsLoading());
    try {
      final res = await _api.searchTransactions(token, query);
      final list = (res['data'] as List?) ?? [];
      emit(TransactionsSearchResult(list));
    } catch (e) {
      emit(TransactionsFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> getTransactionDetails(String token, int expenseId) async {
    emit(TransactionsLoading());
    try {
      final res = await _api.getTransactionDetails(token, expenseId);
      if (res['success'] == true && res['data'] != null) {
        emit(TransactionDetailLoaded(
            Map<String, dynamic>.from(res['data'])));
      } else {
        emit(TransactionsFailure(res['error'] ?? 'Not found'));
      }
    } catch (e) {
      emit(TransactionsFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}