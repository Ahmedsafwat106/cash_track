import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/CategoryIcon.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/section_header.dart';
import 'TransactionDetailScreen.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _transactions = [];
  String _errorMsg = '';

  double _totalBalance = 0;
  double _totalExpenses = 0;
  double _remainingBudget = 0;

  List<Map<String, dynamic>> _barData = [];
  final Map<String, double> _categoryTotals = {};

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadData(silent: true);
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMsg = '';
      });
    }
    try {
      final results = await Future.wait([
        _api.getUserCurrentData(widget.token),
        _api.getAllTransactions(widget.token, 1),
        _api.getBarChartData(widget.token),
      ]);

      final reportData = results[0]['data'] as Map<String, dynamic>?;
      if (reportData != null) {
        _totalBalance =
            (reportData['totalBalance'] as num?)?.toDouble() ?? 0;
        _totalExpenses =
            (reportData['totalExpenses'] as num?)?.toDouble() ?? 0;
        _remainingBudget =
            (reportData['remainigBudget'] as num?)?.toDouble() ?? 0;
      }

      final list = (results[1]['data'] as List?) ?? [];
      _transactions = list.take(5).toList();
      _categoryTotals.clear();
      for (final t in list) {
        final amount = (t['amount'] as num?)?.toDouble() ?? 0;
        final cat = t['categoryName']?.toString() ?? 'Other';
        _categoryTotals[cat] = (_categoryTotals[cat] ?? 0) + amount;
      }

      final barList = (results[2]['data'] as List?) ?? [];
      _barData = barList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      if (!silent) {
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final usedPercent = (_totalExpenses + _remainingBudget) > 0
        ? (_totalExpenses / (_totalExpenses + _remainingBudget) * 100)
        .clamp(0.0, 100.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const LoadingIndicator()
          : RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              title: const Text('Home'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.primary),
                  onPressed: _loadData,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BalanceCard(
                      totalBalance: _totalBalance,
                      totalExpenses: _totalExpenses,
                      remaining: _remainingBudget,
                      usedPercent: usedPercent,
                    ),
                    const SizedBox(height: 24),
                    _MonthlySummaryCard(barData: _barData),
                    const SizedBox(height: 24),

                    if (_categoryTotals.isNotEmpty) ...[
                      const SectionHeader(
                          title: 'Top Spending Categories'),
                      const SizedBox(height: 12),
                      _TopCategoriesRow(
                          categories: _categoryTotals,
                          total: _totalExpenses),
                      const SizedBox(height: 24),
                    ],
                    if (_errorMsg.isNotEmpty)
                      _ErrorWidget(msg: _errorMsg)
                    else if (_transactions.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Recent Transactions',
                        action: 'See all',
                        onAction: () {},
                      ),
                      const SizedBox(height: 12),
                      ..._transactions.map((t) => _TransactionTile(
                        transaction: t,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionDetailScreen(
                              token: widget.token,
                              expenseId:
                              t['expenseId'] as int? ?? 0,
                              categoryName:
                              t['categoryName'] ?? '',
                              amount:
                              (t['amount'] as num?)?.toDouble() ??
                                  0,
                              date: t['date']?.toString() ?? '',
                            ),
                          ),
                        ).then((_) => _loadData()),
                      )),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double totalBalance, totalExpenses, remaining, usedPercent;
  const _BalanceCard(
      {required this.totalBalance,
        required this.totalExpenses,
        required this.remaining,
        required this.usedPercent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'EGP ${NumberFormat('#,##0.00').format(totalBalance)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _InfoChip(
                    label: 'Total Expenses',
                    value:
                    'EGP ${NumberFormat('#,##0').format(totalExpenses)}')),
            const SizedBox(width: 12),
            Expanded(
                child: _InfoChip(
                    label: 'Remaining Budget',
                    value:
                    'EGP ${NumberFormat('#,##0').format(remaining)}')),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Budget Used',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 12)),
            Text('${usedPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usedPercent / 100,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                usedPercent >= 100
                    ? AppColors.error
                    : usedPercent >= 80
                    ? AppColors.warning
                    : Colors.white,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
            TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> barData;
  const _MonthlySummaryCard({required this.barData});

  @override
  Widget build(BuildContext context) {
    final months =
    barData.map((e) => e['monthName']?.toString() ?? '').toList();
    final expenses = barData
        .map((e) => (e['totalExpense'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final balances = barData
        .map((e) => (e['totalBalance'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final maxVal =
    [...expenses, ...balances, 1.0].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Monthly Summary',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Row(children: [
          _Dot(color: AppColors.primary, label: 'Expenses'),
          const SizedBox(width: 16),
          _Dot(color: const Color(0xFFB2DFDB), label: 'Balance'),
        ]),
        const SizedBox(height: 16),
        if (barData.isEmpty)
          const SizedBox(
              height: 80,
              child: Center(
                  child: Text('No data yet',
                      style: TextStyle(color: AppColors.textHint))))
        else
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              maxY: maxVal * 1.25,
              minY: 0,
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: AppColors.divider, strokeWidth: 0.8)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= months.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(months[idx],
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(
                  months.length,
                      (i) => BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                        toY: expenses[i],
                        color: AppColors.primary,
                        width: 10,
                        borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(
                        toY: balances[i],
                        color: const Color(0xFFB2DFDB),
                        width: 10,
                        borderRadius: BorderRadius.circular(4)),
                  ], barsSpace: 4)),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.primaryDark,
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    '${ri == 0 ? 'Expenses' : 'Balance'}\nEGP ${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )),
          ),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
        width: 10,
        height: 10,
        decoration:
        BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label,
        style: const TextStyle(
            fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

class _TopCategoriesRow extends StatelessWidget {
  final Map<String, double> categories;
  final double total;
  const _TopCategoriesRow(
      {required this.categories, required this.total});

  @override
  Widget build(BuildContext context) {
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    return Row(
      children: top.map((e) {
        final pct = total > 0 ? (e.value / total * 100) : 0;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 8)
              ],
            ),
            child: Column(children: [
              CategoryIcon(category: e.key, size: 40),
              const SizedBox(height: 8),
              Text(e.key,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
              Text('${pct.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic transaction;
  final VoidCallback onTap;
  const _TransactionTile(
      {required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = transaction['expenseName']?.toString() ?? '';
    final cat = transaction['categoryName']?.toString() ?? '';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    String dateStr = '';
    try {
      final d = DateTime.parse(transaction['date'].toString());
      dateStr = DateFormat('MMM d, yyyy').format(d);
    } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Row(children: [
          CategoryIcon(category: cat, size: 42),
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
                    const SizedBox(height: 2),
                    Text(cat,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('EGP ${NumberFormat('#,##0.00').format(amount)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(dateStr,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String msg;
  const _ErrorWidget({required this.msg});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(msg,
            style: const TextStyle(color: AppColors.error))),
  );
}