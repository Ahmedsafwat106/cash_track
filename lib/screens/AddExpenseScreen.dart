
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../features/Categories/categories_cubit.dart';
import '../features/Categories/categories_state.dart';
import '../features/transactions/transactions_cubit.dart';
import '../features/transactions/transactions_state.dart';
import '../utils/app_colors.dart';
import '../widgets/CategoryIcon.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class AddExpenseScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onAdded;
  const AddExpenseScreen({super.key, required this.token, this.onAdded});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [];
  int _paymentMethod = 1;
  DateTime _selectedDate = DateTime.now();
  String? _receiptPath;
  bool _uploadingReceipt = false;

  late TransactionsCubit _txCubit;
  late CategoriesCubit _catCubit;

  @override
  void initState() {
    super.initState();
    _txCubit = TransactionsCubit(ApiService());
    _catCubit = CategoriesCubit(ApiService());
    _catCubit.loadCategories(widget.token, isExpense: true);
    _dateCtrl.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    _txCubit.close();
    _catCubit.close();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
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

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xfile != null) {
      setState(() => _receiptPath = xfile.path);
    }
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    _txCubit.addExpense(
      widget.token,
      amount: double.parse(_amountCtrl.text),
      name: _nameCtrl.text.trim(),
      date: _selectedDate.toUtc().toIso8601String(),
      categoryName: _selectedCategory!,
      paymentMethod: _paymentMethod,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );
  }

  Future<void> _uploadReceiptIfSelected(int expenseId) async {
    if (_receiptPath == null) return;
    setState(() => _uploadingReceipt = true);
    try {
      final res = await ApiService().uploadReceipt(
        widget.token,
        expenseId,
        _receiptPath!,
      );
      print('=== UPLOAD RECEIPT RESPONSE: $res ===');
      if (res['success'] != true) {
        print('=== UPLOAD FAILED: ${res['error']} ===');
      }
    } catch (e) {
      print('=== UPLOAD EXCEPTION: $e ===');
    } finally {
      setState(() => _uploadingReceipt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _txCubit),
        BlocProvider.value(value: _catCubit),
      ],
      child: BlocListener<TransactionsCubit, TransactionsState>(
        listener: (ctx, state) async {
          if (state is TransactionAdded) {

            final expenseId = state.expenseId;

            if (_receiptPath != null && expenseId != null && expenseId > 0) {
              await _uploadReceiptIfSelected(expenseId);
            }

            Navigator.pop(context);
            widget.onAdded?.call();

            Color snackColor = AppColors.success;
            String msg = state.message;
            if (state.status == 2) snackColor = AppColors.error;
            if (state.status == 1) snackColor = AppColors.warning;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: snackColor),
            );
          } else if (state is TransactionsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.error),
                  backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<TransactionsCubit, TransactionsState>(
          builder: (ctx, txState) {
            final isLoading =
                txState is TransactionsLoading || _uploadingReceipt;
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          isLoading && _uploadingReceipt
                              ? 'Uploading receipt...'
                              : 'Add Expense',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        TextButton(
                          onPressed: isLoading ? null : () => _submit(ctx),
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isLoading
                                  ? AppColors.textHint
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // ── Amount ──────────────────────────
                            const Text('Expense',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                children: [
                                  const Text('EGP ',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _amountCtrl,
                                      keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '0.00',
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      validator: (v) {
                                        if (v!.isEmpty) return 'Enter amount';
                                        if (double.tryParse(v) == null) {
                                          return 'Invalid amount';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            const Text('Description',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hint: 'e.g. Dinner at Zooba',
                              controller: _nameCtrl,
                              validator: (v) =>
                              v!.isEmpty ? 'Enter a description' : null,
                            ),
                            const SizedBox(height: 16),

                            const Text('Date',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hint: 'Select date',
                              controller: _dateCtrl,
                              readOnly: true,
                              onTap: _pickDate,
                              suffix: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppColors.textHint),
                            ),
                            const SizedBox(height: 16),

                            const Text('Category',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            BlocBuilder<CategoriesCubit, CategoriesState>(
                              builder: (ctx, catState) {
                                if (catState is CategoriesLoaded) {
                                  _categories = catState.categories
                                      .map((c) => c['name'].toString())
                                      .toList();
                                }
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.divider),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    hint: const Text('Select Category',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textHint)),
                                    items: _categories
                                        .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          CategoryIcon(
                                              category: c,
                                              size: 22),
                                          const SizedBox(
                                              width: 8),
                                          Text(c),
                                        ],
                                      ),
                                    ))
                                        .toList(),
                                    onChanged: (v) => setState(
                                            () => _selectedCategory = v),
                                    validator: (v) => v == null
                                        ? 'Select a category'
                                        : null,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4),
                                    ),
                                    dropdownColor: AppColors.surface,
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            const Text('Payment Method',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            _PaymentMethodPicker(
                              selected: _paymentMethod,
                              onChanged: (v) =>
                                  setState(() => _paymentMethod = v),
                            ),
                            const SizedBox(height: 16),

                            const Text('Notes (optional)',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hint: 'Add a note...',
                              controller: _notesCtrl,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),

                            const Text('Receipt (optional)',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickReceipt,
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _receiptPath != null
                                      ? AppColors.success.withOpacity(0.08)
                                      : AppColors.surface,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _receiptPath != null
                                        ? AppColors.success
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _receiptPath != null
                                          ? Icons.check_circle_outline
                                          : Icons.upload_file_outlined,
                                      color: _receiptPath != null
                                          ? AppColors.success
                                          : AppColors.textHint,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _receiptPath != null
                                          ? 'Receipt selected ✓ (will upload after save)'
                                          : 'Upload Image/PDF',
                                      style: TextStyle(
                                        color: _receiptPath != null
                                            ? AppColors.success
                                            : AppColors.textHint,
                                        fontSize: 13,
                                        fontWeight: _receiptPath != null
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_receiptPath != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _receiptPath = null),
                                child: const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.close,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                    SizedBox(width: 4),
                                    Text('Remove receipt',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 32),

                            CustomButton(
                              label: _uploadingReceipt
                                  ? 'Uploading receipt...'
                                  : 'Save Expense',
                              isLoading: isLoading,
                              onTap: () => _submit(ctx),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaymentMethodPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _PaymentMethodPicker(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'label': 'Cash', 'value': 1, 'icon': Icons.money},
      {'label': 'Card', 'value': 2, 'icon': Icons.credit_card},
      {'label': 'Online', 'value': 3, 'icon': Icons.phone_android},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonFormField<int>(
        value: selected,
        items: methods
            .map((m) => DropdownMenuItem<int>(
          value: m['value'] as int,
          child: Row(
            children: [
              Icon(m['icon'] as IconData,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(m['label'] as String),
            ],
          ),
        ))
            .toList(),
        onChanged: (v) => onChanged(v!),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        dropdownColor: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}