abstract class IncomeState {}
class IncomeInitial extends IncomeState {}
class IncomeLoading extends IncomeState {}
class IncomeAdded extends IncomeState { final String message; IncomeAdded(this.message); }
class IncomeFailure extends IncomeState { final String error; IncomeFailure(this.error); }