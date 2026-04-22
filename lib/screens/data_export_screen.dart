import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../core/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/loading_indicator.dart';

class DataExportScreen extends StatefulWidget {
  final String token;
  const DataExportScreen({super.key, required this.token});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _loading = true;
  bool _exporting = false;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiService().getAllTransactions(widget.token, 1);
      setState(() {
        _transactions = (res['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportCSV() async {
    setState(() => _exporting = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln('Name,Category,Amount,Date,Payment Method');
      for (final t in _transactions) {
        final name = t['expenseName']?.toString() ?? '';
        final cat = t['categoryName']?.toString() ?? '';
        final amount = (t['amount'] as num?)?.toDouble() ?? 0;
        String dateStr = '';
        try {
          dateStr = DateFormat('yyyy-MM-dd')
              .format(DateTime.parse(t['date'].toString()));
        } catch (_) {}
        final method = t['paymentMethod']?.toString() ?? '';
        buffer.writeln(
            '"$name","$cat",$amount,"$dateStr","$method"');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/transactions_export.csv');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)],
          text: 'My Transactions Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _exportJSON() async {
    setState(() => _exporting = true);
    try {
      final jsonStr =
      const JsonEncoder.withIndent('  ').convert(_transactions);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/transactions_export.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)],
          text: 'My Transactions Export (JSON)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Data Export'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const LoadingIndicator()
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primaryDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_transactions.length} transactions ready to export',
                      style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Export Format',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _ExportCard(
              icon: Icons.table_chart_outlined,
              title: 'CSV File',
              subtitle:
              'Compatible with Excel, Google Sheets, and any spreadsheet app',
              onTap: _exporting ? null : _exportCSV,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _ExportCard(
              icon: Icons.code_outlined,
              title: 'JSON File',
              subtitle: 'Raw data format, useful for developers',
              onTap: _exporting ? null : _exportJSON,
              color: Colors.orange,
            ),
            if (_exporting) ...[
              const SizedBox(height: 24),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('Preparing export...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;

  const _ExportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.download_outlined, color: color),
          ],
        ),
      ),
    );
  }
}