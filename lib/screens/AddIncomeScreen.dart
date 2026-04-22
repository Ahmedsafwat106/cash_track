
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../features/Categories/categories_cubit.dart';
import '../features/Categories/categories_state.dart';
import '../features/Income/income_cubit.dart';
import '../features/Income/income_state.dart';
import '../utils/app_colors.dart';
import '../widgets/CategoryIcon.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';


class AddIncomeScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onAdded;
  const AddIncomeScreen({super.key, required this.token, this.onAdded});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [];
  DateTime _selectedDate = DateTime.now();

  late IncomeCubit _incomeCubit;
  late CategoriesCubit _catCubit;

  @override
  void initState() {
    super.initState();
    _incomeCubit = IncomeCubit(ApiService());
    _catCubit = CategoriesCubit(ApiService());
    _catCubit.loadCategories(widget.token, isExpense: false);
    _dateCtrl.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    _incomeCubit.close();
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _incomeCubit),
        BlocProvider.value(value: _catCubit),
      ],
      child: BlocListener<IncomeCubit, IncomeState>(
        listener: (ctx, state) {
          if (state is IncomeAdded) {
            Navigator.pop(context);
            widget.onAdded?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is IncomeFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.error),
                  backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<IncomeCubit, IncomeState>(
          builder: (ctx, incomeState) {
            final isLoading = incomeState is IncomeLoading;
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Add Income'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => _submit(ctx),
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
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.success,
                              Color(0xFF059669)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Text('EGP ',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Expanded(
                              child: TextFormField(
                                controller: _amountCtrl,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                                 style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),

                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
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
                      const SizedBox(height: 20),

                      _buildLabel('Income Name'),
                      CustomTextField(
                        hint: 'e.g. Freelance',
                        controller: _nameCtrl,
                        prefix: const Icon(Icons.work_outline,
                            color: AppColors.textHint),
                        validator: (v) =>
                        v!.isEmpty ? 'Enter income name' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Category'),
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
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.divider),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              hint: const Text('Select Category'),
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    CategoryIcon(
                                        category: c, size: 20),
                                    const SizedBox(width: 8),
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
                                    horizontal: 16, vertical: 4),
                              ),
                              dropdownColor: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Date'),
                      CustomTextField(
                        hint: 'Select date',
                        controller: _dateCtrl,
                        readOnly: true,
                        onTap: _pickDate,
                        prefix: const Icon(Icons.calendar_today_outlined,
                            color: AppColors.textHint),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Notes (optional)'),
                      CustomTextField(
                        hint: 'Add a note...',
                        controller: _notesCtrl,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      CustomButton(
                        label: 'Save Income',
                        isLoading: isLoading,
                        onTap: () => _submit(ctx),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    _incomeCubit.addIncome(
      widget.token,
      categoryName: _selectedCategory!,
      incomeName: _nameCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      date: _selectedDate.toUtc().toIso8601String(),
      notes: _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : null,
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary)),
  );
}