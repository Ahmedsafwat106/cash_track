import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/loading_indicator.dart';

class ReportsScreen extends StatefulWidget {
  final String token;
  const ReportsScreen({super.key, required this.token});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiService();
  bool _loading = true;

  double _totalBalance = 0;
  double _totalExpenses = 0;

  List<Map<String, dynamic>> _barData = [];

  List<Map<String, dynamic>> _lineData = [];

  double _monthExpense = 0;
  double _monthNetSalary = 0;
  double _monthIncome = 0;

  List<dynamic> _topCategories = [];

  List<dynamic> _latestTransactions = [];

  List<dynamic> _spentCategories = [];

  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getUserCurrentData(widget.token),
        _api.getBarChartData(widget.token),
        _api.getLineChartData(widget.token,
            month: _selectedMonth, year: _selectedYear),
        _api.getMonthSummary(widget.token,
            month: _selectedMonth, year: _selectedYear),
        _api.getTopCategories(widget.token),
        _api.getLatestTransactions(widget.token),
        _api.getSpentCategories(widget.token),
      ]);

      final rd = results[0]['data'] as Map<String, dynamic>?;
      if (rd != null) {
        _totalBalance  = (rd['totalBalance'] as num?)?.toDouble() ?? 0;
        _totalExpenses = (rd['totalExpenses'] as num?)?.toDouble() ?? 0;
      }

      final barList = (results[1]['data'] as List?) ?? [];
      _barData = barList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
          .reversed
          .toList();

      final lineList = (results[2]['data'] as List?) ?? [];
      _lineData = lineList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final ms = results[3]['data'] as Map<String, dynamic>?;
      if (ms != null) {
        _monthExpense   = (ms['expense'] as num?)?.toDouble() ?? 0;
        _monthNetSalary = (ms['netSalary'] as num?)?.toDouble() ?? 0;
        _monthIncome    = (ms['income'] as num?)?.toDouble() ?? 0;
      }

      _topCategories = (results[4]['data'] as List?) ?? [];

      _latestTransactions = (results[5]['data'] as List?) ?? [];

      _spentCategories = (results[6]['data'] as List?) ?? [];
    } catch (e) {
      print('Reports error: $e');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _SummaryRow(
                  totalBalance: _totalBalance,
                  totalExpenses: _totalExpenses),
              const SizedBox(height: 20),

              _MonthSummaryCard(
                selectedMonth: _selectedMonth,
                selectedYear: _selectedYear,
                expense: _monthExpense,
                income: _monthIncome,
                netSalary: _monthNetSalary,
                onMonthChanged: (m, y) {
                  setState(() {
                    _selectedMonth = m;
                    _selectedYear = y;
                  });
                  _loadAll();
                },
              ),
              const SizedBox(height: 20),

              if (_lineData.isNotEmpty) ...[
                _LineChartCard(lineData: _lineData),
                const SizedBox(height: 20),
              ],

              _BarChartCard(barData: _barData),
              const SizedBox(height: 20),

              if (_spentCategories.isNotEmpty) ...[
                _PieChartCard(spentCategories: _spentCategories),
                const SizedBox(height: 20),
              ],

              if (_topCategories.isNotEmpty) ...[
                _SectionTitle('Top Categories'),
                const SizedBox(height: 12),
                ..._topCategories.map((c) => _TopCategoryCard(cat: c)),
                const SizedBox(height: 20),
              ],

              if (_latestTransactions.isNotEmpty) ...[
                _SectionTitle('Recent Activity'),
                const SizedBox(height: 12),
                ..._latestTransactions.map((t) => _LatestTxTile(tx: t)),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double totalBalance, totalExpenses;
  const _SummaryRow({required this.totalBalance, required this.totalExpenses});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Row(children: [
      _SummaryCard(label: 'Balance',
          value: 'EGP ${fmt.format(totalBalance)}',
          color: AppColors.primary,
          icon: Icons.account_balance_wallet_outlined),
      const SizedBox(width: 10),
      _SummaryCard(label: 'Expenses',
          value: 'EGP ${fmt.format(totalExpenses)}',
          color: AppColors.error,
          icon: Icons.arrow_upward_rounded),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final int selectedMonth, selectedYear;
  final double expense, income, netSalary;
  final void Function(int month, int year) onMonthChanged;

  const _MonthSummaryCard({
    required this.selectedMonth, required this.selectedYear,
    required this.expense, required this.income, required this.netSalary,
    required this.onMonthChanged,
  });

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Month Summary', style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const Spacer(),
          // Month picker
          GestureDetector(
            onTap: () => _pickMonth(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${_months[selectedMonth - 1]} $selectedYear',
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down,
                    color: AppColors.primaryDark, size: 18),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _MiniStat(label: 'Expenses',
              value: 'EGP ${fmt.format(expense)}', color: AppColors.error),
          const SizedBox(width: 8),
          _MiniStat(label: 'Income',
              value: 'EGP ${fmt.format(income)}', color: AppColors.success),
          const SizedBox(width: 8),
          _MiniStat(label: 'Net',
              value: 'EGP ${fmt.format(netSalary)}', color: AppColors.primary),
        ]),
      ]),
    );
  }

  void _pickMonth(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Month', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8,
              children: List.generate(12, (i) {
                final m = i + 1;
                final isSelected = m == selectedMonth;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onMonthChanged(m, selectedYear);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(_months[i],
                        style: TextStyle(
                            color: isSelected
                                ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: color),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> lineData;
  const _LineChartCard({required this.lineData});

  @override
  Widget build(BuildContext context) {
    final spots = lineData.map((e) {
      final day = (e['dayNumber'] as num?)?.toDouble() ?? 0;
      final amt = (e['lastAmount'] as num?)?.toDouble() ?? 0;
      return FlSpot(day, amt);
    }).toList();

    final maxY = spots.isEmpty
        ? 1.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Daily Spending', style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: LineChart(LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(show: true, drawVerticalLine: false,
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
                  interval: 5,
                  getTitlesWidget: (val, meta) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(val.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary)),
                  ),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2.5,
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                dotData: const FlDotData(show: false),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.primaryDark,
                getTooltipItems: (spots) => spots.map((s) =>
                    LineTooltipItem(
                      'Day ${s.x.toInt()}\nEGP ${s.y.toStringAsFixed(0)}',
                      const TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w600),
                    )).toList(),
              ),
            ),
          )),
        ),
      ]),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> barData;
  const _BarChartCard({required this.barData});

  @override
  Widget build(BuildContext context) {
    final months =
    barData.map((e) => e['monthName']?.toString() ?? '').toList();
    final expenses = barData
        .map((e) => (e['totalExpense'] as num?)?.toDouble() ?? 0.0).toList();
    final balances = barData
        .map((e) => (e['totalBalance'] as num?)?.toDouble() ?? 0.0).toList();
    final maxVal =
    [...expenses, ...balances, 1.0].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Monthly Overview', style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Row(children: [
          _Dot(color: AppColors.primary, label: 'Expenses'),
          const SizedBox(width: 16),
          _Dot(color: const Color(0xFFB2DFDB), label: 'Balance'),
        ]),
        const SizedBox(height: 16),
        if (barData.isEmpty)
          const SizedBox(height: 80,
              child: Center(child: Text('No data',
                  style: TextStyle(color: AppColors.textHint))))
        else
          SizedBox(height: 160,
            child: BarChart(BarChartData(
              maxY: maxVal * 1.25, minY: 0,
              gridData: FlGridData(show: true, drawVerticalLine: false,
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
                      if (idx < 0 || idx >= months.length) return const SizedBox();
                      return Padding(padding: const EdgeInsets.only(top: 4),
                          child: Text(months[idx], style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)));
                    },
                  ),
                ),
              ),
              barGroups: List.generate(months.length, (i) =>
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: expenses[i], color: AppColors.primary,
                        width: 10, borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(toY: balances[i],
                        color: const Color(0xFFB2DFDB),
                        width: 10, borderRadius: BorderRadius.circular(4)),
                  ], barsSpace: 4)),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.primaryDark,
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    '${ri == 0 ? 'Exp' : 'Bal'}\nEGP ${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white, fontSize: 10,
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
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(
        fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

class _PieChartCard extends StatefulWidget {
  final List<dynamic> spentCategories;
  const _PieChartCard({required this.spentCategories});

  @override
  State<_PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<_PieChartCard> {
  int _touched = -1;
  static const _colors = [
    Color(0xFF4DB6AC), Color(0xFFEF4444), Color(0xFFF59E0B),
    Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFF3B82F6),
    Color(0xFFEC4899), Color(0xFF14B8A6),
  ];

  @override
  Widget build(BuildContext context) {
    final total = widget.spentCategories.fold<double>(0,
            (s, c) => s + ((c['totalSpent'] as num?)?.toDouble() ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Spending by Category', style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(height: 160, width: 160,
            child: PieChart(PieChartData(
              pieTouchData: PieTouchData(touchCallback: (event, response) {
                setState(() {
                  _touched = response?.touchedSection
                      ?.touchedSectionIndex ?? -1;
                });
              }),
              sections: List.generate(
                  widget.spentCategories.length, (i) {
                final c = widget.spentCategories[i];
                final spent = (c['totalSpent'] as num?)?.toDouble() ?? 0;
                final pct = total > 0 ? (spent / total * 100) : 0;
                final isTouched = i == _touched;
                return PieChartSectionData(
                  value: spent,
                  color: _colors[i % _colors.length],
                  radius: isTouched ? 65 : 55,
                  title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: Colors.white),
                );
              }),
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            )),
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
                widget.spentCategories.length.clamp(0, 5), (i) {
              final c = widget.spentCategories[i];
              final name = c['name']?.toString() ?? '';
              final spent = (c['totalSpent'] as num?)?.toDouble() ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(name,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis)),
                  Text('EGP ${NumberFormat('#,##0').format(spent)}',
                      style: const TextStyle(fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                ]),
              );
            }),
          )),
        ]),
      ]),
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  final dynamic cat;
  const _TopCategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final name   = cat['name']?.toString() ?? '';
    final spent  = (cat['totalSpent'] as num?)?.toDouble() ?? 0;
    final budget = (cat['budget'] as num?)?.toDouble() ?? 0;
    final pct    = (cat['budgetUsedPercentage'] as num?)?.toDouble() ?? 0;
    Color barColor = AppColors.primary;
    if (pct >= 100) barColor = AppColors.error;
    else if (pct >= 80) barColor = AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary))),
          Text('${pct.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: barColor)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: Text(
              'EGP ${NumberFormat('#,##0').format(spent)} / EGP ${NumberFormat('#,##0').format(budget)}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary))),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0, 1),
            backgroundColor: AppColors.primaryLight,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }
}

class _LatestTxTile extends StatelessWidget {
  final dynamic tx;
  const _LatestTxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final name      = tx['name']?.toString() ?? '';
    final isExpense = tx['isExpense'] as bool? ?? true;
    final amount    = (tx['amount'] as num?)?.toDouble() ?? 0;
    String dateStr  = '';
    try {
      final d = DateTime.parse(tx['date'].toString());
      dateStr = DateFormat('MMM d, yyyy').format(d);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(
                color: (isExpense ? AppColors.error : AppColors.success)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(
                isExpense
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isExpense ? AppColors.error : AppColors.success,
                size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(dateStr, style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
          ],
        )),
        Text(
          '${isExpense ? '-' : '+'}EGP ${NumberFormat('#,##0').format(amount)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: isExpense ? AppColors.error : AppColors.success),
        ),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));
}