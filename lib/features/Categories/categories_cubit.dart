
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_service.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final ApiService _api;

  List<dynamic> expenseCategories = [];
  List<dynamic> incomeCategories = [];

  CategoriesCubit(this._api) : super(CategoriesInitial());

  Future<void> loadCategories(String token,
      {required bool isExpense}) async {

    emit(CategoriesLoading());

    try {
      final res = await _api.getAllCategories(token, isExpense);

      if (res['success'] == true) {
        final list = (res['data'] as List?) ?? [];

        if (isExpense) {
          expenseCategories = list;
        } else {
          incomeCategories = list;
        }

        emit(CategoriesLoaded(
          isExpense: isExpense,
          categories: list,
        ));
      } else {
        emit(CategoriesFailure(
            res['error'] ?? 'Add Category Failed'
        ));
      }
    } catch (e) {
      emit(CategoriesFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> addCategory(
      String token, {
        required String categoryName,
        required double budget,
        required bool isExpense,
      }) async {

    emit(CategoriesLoading());

    try {
      final res = await _api.addCategory(
        token,
        name: categoryName,
        budget: budget,
        isExpense: isExpense,
      );

      if (res['success'] == true) {
        await loadCategories(token, isExpense: isExpense);
        emit(CategoryAdded(res['message'] ?? 'Category Added'));
      } else {
        emit(CategoriesFailure(
            res['error'] ?? 'Add Category Failed'));
      }
    } catch (e) {
      emit(CategoriesFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}