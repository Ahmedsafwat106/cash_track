import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../features/transactions/transactions_cubit.dart';
import '../features/transactions/transactions_state.dart';
import '../utils/app_colors.dart';
import '../widgets/CategoryIcon.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/loading_indicator.dart';
import 'TransactionDetailScreen.dart';

class TransactionsScreen extends StatefulWidget {
  final String token;
  const TransactionsScreen({super.key, required this.token});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late TransactionsCubit _cubit;
  bool _isSearching = false;
  List<dynamic> _displayed = [];
  int _currentPage = 1;
  bool _hasNext = false;
  String? _orderBy; // null = by date, 'Amount' = by amount

  @override
  void initState() {
    super.initState();
    _cubit = TransactionsCubit(ApiService());
    _cubit.loadTransactions(widget.token, page: 1, orderBy: _orderBy);
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200 &&
        _hasNext &&
        !_isSearching) {
      _cubit.loadTransactions(widget.token,
          page: _currentPage + 1, orderBy: _orderBy);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearch(String q) {
    if (q.trim().isEmpty) {
      setState(() => _isSearching = false);
      _cubit.loadTransactions(widget.token, page: 1, orderBy: _orderBy);
    } else {
      setState(() => _isSearching = true);
      _cubit.searchTransactions(widget.token, q.trim());
    }
  }

  void _setSort(String? orderBy) {
    setState(() => _orderBy = orderBy);
    _cubit.loadTransactions(widget.token, page: 1, orderBy: orderBy);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Transactions'),
          actions: [

            PopupMenuButton<String?>(
              icon: Icon(Icons.sort,
                  color: _orderBy != null ? AppColors.primary : null),
              tooltip: 'Sort',
              onSelected: _setSort,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: null,
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 18,
                        color: _orderBy == null
                            ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Sort by Date',
                        style: TextStyle(
                            color: _orderBy == null
                                ? AppColors.primary : AppColors.textPrimary)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'Amount',
                  child: Row(children: [
                    Icon(Icons.attach_money, size: 18,
                        color: _orderBy == 'Amount'
                            ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Sort by Amount',
                        style: TextStyle(
                            color: _orderBy == 'Amount'
                                ? AppColors.primary : AppColors.textPrimary)),
                  ]),
                ),
              ],
            ),
          ],
        ),
        body: Column(children: [

          if (_orderBy != null)
            Container(
              color: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                const Icon(Icons.sort, size: 14, color: AppColors.primaryDark),
                const SizedBox(width: 6),
                Text('Sorted by: ${_orderBy == 'Amount' ? 'Amount' : 'Date'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primaryDark)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _setSort(null),
                  child: const Text('Clear',
                      style: TextStyle(fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: CustomTextField(
              hint: 'Search by note, category',
              controller: _searchCtrl,
              prefix: const Icon(Icons.search, color: AppColors.textHint),
              suffix: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textHint),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearch('');
                  })
                  : null,
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: BlocConsumer<TransactionsCubit, TransactionsState>(
              listener: (ctx, state) {
                if (state is TransactionsLoaded) {
                  setState(() {
                    _displayed = state.transactions;
                    _currentPage = state.currentPage;
                    _hasNext = state.hasNext;
                  });
                } else if (state is TransactionsSearchResult) {
                  setState(() => _displayed = state.results);
                } else if (state is TransactionDeleted) {
                  _cubit.loadTransactions(widget.token,
                      page: 1, orderBy: _orderBy);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted'),
                        backgroundColor: AppColors.success),
                  );
                }
              },
              builder: (ctx, state) {
                if (state is TransactionsLoading && _displayed.isEmpty) {
                  return const LoadingIndicator();
                }
                if (state is TransactionsFailure && _displayed.isEmpty) {
                  return _ErrorState(
                    msg: state.error,
                    onRetry: () => _cubit.loadTransactions(widget.token,
                        page: 1, orderBy: _orderBy),
                  );
                }
                if (_displayed.isEmpty) return const _EmptyState();

                // Group by date
                final grouped = <String, List<dynamic>>{};
                for (final t in _displayed) {
                  String key = 'Unknown';
                  try {
                    final d = DateTime.parse(t['date'].toString());
                    key = DateFormat('MMM d').format(d);
                  } catch (_) {}
                  grouped.putIfAbsent(key, () => []).add(t);
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: grouped.keys.length +
                      (_hasNext && !_isSearching ? 1 : 0),
                  itemBuilder: (ctx, idx) {
                    final keys = grouped.keys.toList();
                    if (idx == keys.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator(
                            color: AppColors.primary)),
                      );
                    }
                    final key = keys[idx];
                    final items = grouped[key]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(key,
                              style: const TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                        ),
                        ...items.map((t) => _TransactionCard(
                          transaction: t,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(
                                token: widget.token,
                                expenseId: t['expenseId'] as int? ?? 0,
                                categoryName: t['categoryName'] ?? '',
                                amount: (t['amount'] as num?)
                                    ?.toDouble() ?? 0,
                                date: t['date']?.toString() ?? '',
                              ),
                            ),
                          ).then((_) => _cubit.loadTransactions(
                              widget.token, page: 1, orderBy: _orderBy)),
                          onDelete: () => _confirmDelete(
                              ctx, t['expenseId'] as int? ?? 0),
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          if (_displayed.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.surface,
              child: Text(
                'Showing ${_displayed.length} transaction${_displayed.length != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, int expenseId) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Transaction',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content:
        const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(ctx);
              _cubit.deleteTransaction(widget.token, expenseId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final dynamic transaction;
  final VoidCallback onTap, onDelete;
  const _TransactionCard(
      {required this.transaction, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name   = transaction['expenseName']?.toString() ?? '';
    final cat    = transaction['categoryName']?.toString() ?? '';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    String dateStr = '';
    try {
      final d = DateTime.parse(transaction['date'].toString());
      dateStr = DateFormat('MMM d, yyyy').format(d);
    } catch (_) {}

    return Dismissible(
      key: Key(transaction['expenseId'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: AppColors.error,
            borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async { onDelete(); return false; },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            CategoryIcon(category: cat, size: 44),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(cat, style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('EGP ${NumberFormat('#,##0').format(amount)}',
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Text(dateStr, style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorState({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 60, color: AppColors.error),
      const SizedBox(height: 12),
      Text(msg, textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 72, color: AppColors.textHint),
      SizedBox(height: 12),
      Text('No transactions found',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
    ]),
  );
}