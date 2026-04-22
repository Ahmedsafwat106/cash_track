
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/api_service.dart';
import '../features/Categories/categories_cubit.dart';
import '../features/Categories/categories_state.dart';
import '../utils/app_colors.dart';
import '../widgets/CategoryIcon.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/loading_indicator.dart';


class CategoriesScreen extends StatefulWidget {
  final String token;
  const CategoriesScreen({super.key, required this.token});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late CategoriesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _cubit = CategoriesCubit(ApiService());
    _cubit.loadCategories(widget.token, isExpense: true);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _cubit.loadCategories(
          widget.token,
          isExpense: _tabCtrl.index == 0,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Cash Track'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddSheet(context),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Now',
              style: TextStyle(color: Colors.white)),
        ),
        body: BlocConsumer<CategoriesCubit, CategoriesState>(
          listener: (ctx, state) {
            if (state is CategoryAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
              _cubit.loadCategories(widget.token,
                  isExpense: _tabCtrl.index == 0);
            } else if (state is CategoriesFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.error),
                    backgroundColor: AppColors.error),
              );
            }
          },
          builder: (ctx, state) {
            if (state is CategoriesLoading) {
              return const LoadingIndicator();
            }

            return TabBarView(
              controller: _tabCtrl,
              children: [
                _CategoriesList(categories: _cubit.expenseCategories, totalBudget: 25000),
                _CategoriesList(categories: _cubit.incomeCategories, totalBudget: 25000),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddCategorySheet(
        onAdd: (name, budget, isExpense) {
          _cubit.addCategory(widget.token,
              categoryName: name,
              budget: budget,
              isExpense: isExpense);
          Navigator.pop(context);
        },
        isExpense: _tabCtrl.index == 0,
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  final List<dynamic> categories;
  final double totalBudget;
  const _CategoriesList(
      {required this.categories, required this.totalBudget});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined,
                size: 72, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No categories yet. Tap "Add Now"!',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Overall budget
        _OverallBudget(total: totalBudget, used: totalBudget * 0.8),
        const SizedBox(height: 20),
        const Text('Category Budgets',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...categories.map((c) {
          final name = c['name']?.toString() ?? '';
          final budget = (c['budget'] as num?)?.toDouble() ?? 5000;
          final spent =
              (c['spent'] as num?)?.toDouble() ?? 0;
          return _CategoryBudgetCard(
              name: name, spent: spent, budget: budget);
        }),
      ],
    );
  }
}

class _OverallBudget extends StatelessWidget {
  final double total;
  final double used;
  const _OverallBudget({required this.total, required this.used});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (used / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overall Monthly Budget',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                  'EGP ${(used).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('  /  EGP ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0, 1),
              backgroundColor: AppColors.primaryLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  final String name;
  final double spent;
  final double budget;
  const _CategoryBudgetCard(
      {required this.name, required this.spent, required this.budget});

  @override
  Widget build(BuildContext context) {
    final pct =
    budget > 0 ? (spent / budget * 100).clamp(0, 100) : 0.0;
    Color color = AppColors.primary;
    String label = '${pct.toStringAsFixed(0)}%';
    if (pct >= 100) { color = AppColors.error; label = 'Exceeded!'; }
    else if (pct >= 90) { color = AppColors.warning; label = '90% - Warning!'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CategoryIcon(category: name, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.primaryLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  final Function(String name, double budget, bool isExpense) onAdd;
  final bool isExpense;
  const _AddCategorySheet(
      {required this.onAdd, required this.isExpense});

  @override
  State<_AddCategorySheet> createState() =>
      _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isExpense
                  ? 'Add Expense Category'
                  : 'Add Income Category',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            const Text('Category Name',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            CustomTextField(
              hint: 'e.g. Food & Dining',
              controller: _nameCtrl,
              validator: (v) =>
              v!.isEmpty ? 'Enter category name' : null,
            ),
            const SizedBox(height: 16),
            const Text('Budget (EGP)',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            CustomTextField(
              hint: '0.00',
              controller: _budgetCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v!.isEmpty) return 'Enter a budget';
                if (double.tryParse(v) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Add Category',
              onTap: () {
                if (_formKey.currentState!.validate()) {
                  widget.onAdd(
                    _nameCtrl.text.trim(),
                    double.parse(_budgetCtrl.text),
                    widget.isExpense,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}