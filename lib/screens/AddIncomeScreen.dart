import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/loading_indicator.dart';

class IncomeScreen extends StatefulWidget {
  final String token;
  const IncomeScreen({super.key, required this.token});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _incomes = [];
  int _page = 1;
  bool _hasNext = false;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200 &&
          _hasNext) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page = 1;
    });
    try {
      final res = await _api.getAllIncomes(widget.token, page: 1);
      final list = (res['data'] as List?) ?? [];
      setState(() {
        _incomes = list;
        _hasNext = res['hasNextData'] == true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasNext) return;
    _page++;
    try {
      final res = await _api.getAllIncomes(widget.token, page: _page);
      final list = (res['data'] as List?) ?? [];
      setState(() {
        _incomes = [..._incomes, ...list];
        _hasNext = res['hasNextData'] == true;
      });
    } catch (_) {}
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomeFormSheet(
        token: widget.token,
        api: _api,
        onSaved: _load,
      ),
    );
  }

  void _showEditSheet(dynamic income) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomeFormSheet(
        token: widget.token,
        api: _api,
        onSaved: _load,
        editIncome: income,
      ),
    );
  }

  void _confirmDelete(int incomeId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Income',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to delete this income?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _api.deleteIncome(widget.token, incomeId);
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Income deleted'),
                        backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Income'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Income',
            style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const LoadingIndicator()
          : _incomes.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 72, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No income records yet',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _incomes.length + (_hasNext ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == _incomes.length) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
              );
            }
            final inc = _incomes[i];
            return _IncomeCard(
              income: inc,
              onEdit: () => _showEditSheet(inc),
              onDelete: () =>
                  _confirmDelete(inc['incomeId'] as int? ?? 0),
            );
          },
        ),
      ),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  final dynamic income;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IncomeCard(
      {required this.income,
        required this.onEdit,
        required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name = income['name']?.toString() ?? '';
    final cat = income['categoryName']?.toString() ?? '';
    final amount = (income['amount'] as num?)?.toDouble() ?? 0;
    String dateStr = '';
    try {
      final d = DateTime.parse(income['date'].toString());

      if (d.year > 1) {
        dateStr = DateFormat('MMM d, yyyy').format(d);
      }
    } catch (_) {}

    return Dismissible(
      key: Key(income['incomeId'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child:
        const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_downward_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(cat,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                  ],
                ],
              )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '+EGP ${NumberFormat('#,##0').format(amount)}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success),
            ),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_outlined,
                      size: 14, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline,
                      size: 14, color: AppColors.error),
                ),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _IncomeFormSheet extends StatefulWidget {
  final String token;
  final ApiService api;
  final VoidCallback onSaved;
  final dynamic editIncome;

  const _IncomeFormSheet({
    required this.token,
    required this.api,
    required this.onSaved,
    this.editIncome,
  });

  @override
  State<_IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<_IncomeFormSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _notesCtrl;
  bool _loading = false;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;

  bool get _isEdit => widget.editIncome != null;

  final _quickCategories = [
    'Salary', 'Bonus', 'Freelance', 'Investment', 'Gift', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    final inc = widget.editIncome;
    _nameCtrl =
        TextEditingController(text: inc != null ? inc['name']?.toString() ?? '' : '');
    _amountCtrl = TextEditingController(
        text: inc != null
            ? (inc['amount'] as num?)?.toStringAsFixed(0) ?? ''
            : '');
    _categoryCtrl = TextEditingController(
        text: inc != null ? inc['categoryName']?.toString() ?? '' : '');
    _selectedCategory =
    inc != null ? inc['categoryName']?.toString() : null;
    _dateCtrl = TextEditingController(
        text: DateFormat('MMM dd, yyyy').format(_selectedDate));
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
            const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: AppColors.error));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter income name'),
          backgroundColor: AppColors.error));
      return;
    }
    final category =
        _selectedCategory ?? _categoryCtrl.text.trim();
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select or enter a category'),
          backgroundColor: AppColors.error));
      return;
    }

    setState(() => _loading = true);

    try {
      Map<String, dynamic> res;

      if (_isEdit) {

        res = await widget.api.updateIncome(
          widget.token,
          incomeId: widget.editIncome['incomeId'] as int,
          name: _nameCtrl.text.trim(),
          categoryName: category,
          amount: amount,
        );
      } else {

        res = await widget.api.addIncome(
          widget.token,
          categoryName: category,
          incomeName: _nameCtrl.text.trim(),
          amount: amount,
          date: _selectedDate.toUtc().toIso8601String(),
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
        );

        if (res['success'] != true &&
            (res['error']?.toString().toLowerCase().contains('category') ==
                true ||
                res['error']?.toString().toLowerCase().contains('not found') ==
                    true)) {

          await widget.api.addCategory(
            widget.token,
            name: category,
            budget: amount * 12,
            isExpense: false,
          );

          res = await widget.api.addIncome(
            widget.token,
            categoryName: category,
            incomeName: _nameCtrl.text.trim(),
            amount: amount,
            date: _selectedDate.toUtc().toIso8601String(),
            notes: _notesCtrl.text.trim().isNotEmpty
                ? _notesCtrl.text.trim()
                : null,
          );
        }
      }

      if (res['success'] == true) {
        if (mounted) Navigator.pop(context);
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_isEdit
                  ? 'Income updated successfully!'
                  : 'Income added successfully!'),
              backgroundColor: AppColors.success));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(res['error'] ?? res['message'] ?? 'Failed'),
              backgroundColor: AppColors.error));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error));
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Edit Income' : 'Add Income',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // Amount
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider)),
                child: Row(children: [
                  const Text('EGP ',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success)),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          contentPadding: EdgeInsets.zero),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Name
              const Text('Income Name',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              CustomTextField(
                  hint: 'e.g. Monthly Salary', controller: _nameCtrl),
              const SizedBox(height: 16),

              // Category chips
              const Text('Category',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickCategories.map((c) {
                  final isSelected = _selectedCategory == c;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = c;
                      _categoryCtrl.text = '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider)),
                      child: Text(c,
                          style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              CustomTextField(
                hint: 'Or type custom category...',
                controller: _categoryCtrl,
                onChanged: (_) =>
                    setState(() => _selectedCategory = null),
              ),

              if (!_isEdit) ...[
                const SizedBox(height: 16),
                const Text('Date',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: 'Select date',
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  suffix: const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textHint),
                ),
                const SizedBox(height: 16),
                const Text('Notes (optional)',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                CustomTextField(
                    hint: 'Add a note...',
                    controller: _notesCtrl,
                    maxLines: 2),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text(
                    _isEdit ? 'Save Changes' : 'Add Income',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}