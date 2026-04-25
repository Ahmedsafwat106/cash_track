import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../widgets/loading_indicator.dart';
import '../core/api_service.dart';
import 'AddIncomeScreen.dart';
import 'CategoriesScreen.dart';
import 'data_export_screen.dart';

class MoreScreen extends StatefulWidget {
  final String token;
  const MoreScreen({super.key, required this.token});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _api = ApiService();
  bool _loading = true;
  double _totalIncome = 0;
  double _totalExpenses = 0;
  int _incomeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final results = await Future.wait([
        _api.getUserCurrentData(widget.token),
        _api.getAllIncomes(widget.token, page: 1),
      ]);
      final rd = results[0]['data'] as Map<String, dynamic>?;
      if (rd != null) {
        _totalExpenses = (rd['totalExpenses'] as num?)?.toDouble() ?? 0;
        _totalIncome = (rd['totalBalance'] as num?)?.toDouble() ?? 0;
      }
      _incomeCount = (results[1]['count'] as int?) ?? 0;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: _loading
          ? const LoadingIndicator()
          : RefreshIndicator(
        onRefresh: () async {
          setState(() => _loading = true);
          await _loadSummary();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(children: [
                _StatCard(
                  label: 'Total Income',
                  value:
                  'EGP ${_fmt(_totalIncome)}',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Total Expenses',
                  value: 'EGP ${_fmt(_totalExpenses)}',
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.error,
                ),
              ]),
              const SizedBox(height: 20),

              _SectionTitle('Income'),
              _MenuSection(children: [
                _MenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Manage Income',
                  subtitle:
                  '$_incomeCount record${_incomeCount != 1 ? 's' : ''} — view, edit & delete',
                  color: AppColors.success,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            IncomeScreen(token: widget.token)),
                  ).then((_) {
                    setState(() => _loading = true);
                    _loadSummary();
                  }),
                ),
              ]),
              const SizedBox(height: 16),

              _SectionTitle('Tools'),
              _MenuSection(children: [
                _MenuItem(
                  icon: Icons.category_outlined,
                  label: 'Manage Categories',
                  subtitle:
                  'Add & manage your expense/income categories',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CategoriesScreen(token: widget.token))),
                ),
                _MenuItem(
                  icon: Icons.download_outlined,
                  label: 'Data Export',
                  subtitle: 'Export transactions as CSV or JSON',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              DataExportScreen(token: widget.token))),
                ),
              ]),
              const SizedBox(height: 16),

              _SectionTitle('Support'),
              _MenuSection(children: [
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Help & FAQ',
                  subtitle: 'Get answers to common questions',
                  onTap: () async {
                    final uri = Uri.parse(
                        'https://budgetapptry.runasp.net');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                ),
                _MenuItem(
                  icon: Icons.share_outlined,
                  label: 'Share App',
                  subtitle: 'Share BudgetApp with friends',
                  onTap: () => Share.share(
                      'Check out BudgetApp — the smart way to manage your money!'),
                ),
              ]),
              const SizedBox(height: 16),

              _SectionTitle('About'),
              _MenuSection(children: [
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'App Version',
                  subtitle: 'v1.0.0',
                  onTap: () {},
                  showArrow: false,
                ),
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ]),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color),
                      overflow: TextOverflow.ellipsis),
                ],
              )),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5)),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<Widget> children;
  const _MenuSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map((e) => Column(children: [
          e.value,
          if (e.key < children.length - 1)
            const Divider(
                height: 1,
                indent: 56,
                color: AppColors.divider),
        ]))
            .toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool showArrow;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.showArrow = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: c),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
      trailing: showArrow
          ? const Icon(Icons.chevron_right, color: AppColors.textHint)
          : null,
    );
  }
}