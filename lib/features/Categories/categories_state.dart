abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}
class CategoriesLoading extends CategoriesState {}
class CategoriesLoaded extends CategoriesState {
  final List<dynamic> categories;
  final bool isExpense;

  CategoriesLoaded({
    required this.categories,
    required this.isExpense,
  });
}
class CategoryAdded extends CategoriesState {
  final String message;
  CategoryAdded(this.message);
}
class CategoriesFailure extends CategoriesState {
  final String error;
  CategoriesFailure(this.error);
}