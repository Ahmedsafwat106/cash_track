abstract class TransactionsState {}

class TransactionsInitial extends TransactionsState {}

class TransactionsLoading extends TransactionsState {}

class TransactionsLoaded extends TransactionsState {
  final List<dynamic> transactions;
  final bool hasNext;
  final int currentPage;
  TransactionsLoaded({
    required this.transactions,
    required this.hasNext,
    required this.currentPage,
  });
}

class TransactionsLoadingMore extends TransactionsLoaded {
  TransactionsLoadingMore({
    required super.transactions,
    required super.hasNext,
    required super.currentPage,
  });
}

class TransactionsFailure extends TransactionsState {
  final String error;
  TransactionsFailure(this.error);
}

class TransactionAdded extends TransactionsState {
  final String message;
  final int? status;
  final int? expenseId;

  TransactionAdded({
    required this.message,
    this.status,
    this.expenseId,
  });
}

class TransactionDeleted extends TransactionsState {}

class TransactionsSearchResult extends TransactionsState {
  final List<dynamic> results;
  TransactionsSearchResult(this.results);
}

class TransactionDetailLoaded extends TransactionsState {
  final Map<String, dynamic> detail;
  TransactionDetailLoaded(this.detail);
}