import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/CategoryIcon.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_textfield.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String token;
  final int expenseId;
  final String categoryName;
  final double amount;
  final String date;

  const TransactionDetailScreen({
    super.key,
    required this.token,
    required this.expenseId,
    required this.categoryName,
    required this.amount,
    required this.date,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _detail;
  List<dynamic> _receipts = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getTransactionDetails(widget.token, widget.expenseId),
        _api.getAllUploads(widget.token, widget.expenseId),
      ]);
      _detail = results[0]['data'] as Map<String, dynamic>?;
      final uploadsData = results[1]['data'];
      if (uploadsData is List) {
        _receipts = uploadsData;
      } else if (uploadsData is Map) {
        final list = uploadsData['uploads'] ??
            uploadsData['files'] ??
            uploadsData['items'] ?? [];
        _receipts = list is List ? list : [];
      } else {
        _receipts = [];
      }
    } catch (e) {
      print('Detail error: $e');
    }
    setState(() => _loading = false);
  }

  String _extractUrl(dynamic receipt) {
    if (receipt is! Map) return '';
    return receipt['url']?.toString() ??
        receipt['fileUrl']?.toString() ??
        receipt['imageUrl']?.toString() ??
        receipt['filePath']?.toString() ??
        receipt['path']?.toString() ?? '';
  }

  int _extractId(dynamic receipt) {
    if (receipt is! Map) return 0;
    return (receipt['uploadId'] as int?) ??
        (receipt['id'] as int?) ??
        (receipt['fileId'] as int?) ?? 0;
  }

  void _showEditSheet(BuildContext context) {
    final amountCtrl = TextEditingController(
        text: widget.amount.toStringAsFixed(0));
    final nameCtrl = TextEditingController(
        text: _detail?['name']?.toString() ?? '');
    String selectedCategory =
        _detail?['categoryName']?.toString() ?? widget.categoryName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Expense',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                const Text('Amount',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                CustomTextField(
                  hint: 'Amount',
                  controller: amountCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                const Text('Name',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                CustomTextField(hint: 'Expense name', controller: nameCtrl),
                const SizedBox(height: 12),
                const Text('Category',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                CustomTextField(
                  hint: 'Category name',
                  controller:
                  TextEditingController(text: selectedCategory),
                  onChanged: (v) => selectedCategory = v,
                ),
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
                    onPressed: () async {
                      final amount = double.tryParse(amountCtrl.text);
                      if (amount == null || nameCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Fill all fields'),
                              backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      try {
                        final res = await _api.updateExpense(
                          widget.token,
                          expenseId: widget.expenseId,
                          amount: amount,
                          categoryName: selectedCategory,
                          expenseName: nameCtrl.text.trim(),
                        );
                        if (res['success'] == true) {
                          await _loadDetail();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Updated successfully'),
                                  backgroundColor: AppColors.success),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(res['error'] ??
                                      'Update failed'),
                                  backgroundColor: AppColors.error),
                            );
                          }
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
                    child: const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = '';
    try {
      final d = DateTime.parse(widget.date);
      dateStr = DateFormat('MMM d, yyyy • hh:mm a').format(d);
    } catch (_) {
      dateStr = widget.date;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const LoadingIndicator()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(children: [
                CategoryIcon(category: widget.categoryName, size: 60),
                const SizedBox(height: 12),
                Text(
                  _detail?['name']?.toString() ?? widget.categoryName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  _detail?['categoryName']?.toString() ??
                      widget.categoryName,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  'EGP ${NumberFormat('#,##0.00').format(widget.amount)}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary)),
                if (_detail?['notes'] != null &&
                    _detail!['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.notes_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_detail!['notes'].toString(),
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),

            // Receipts
            Row(children: [
              const Text('Receipts',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (_receipts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${_receipts.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 12),

            if (_receipts.isEmpty)
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 36, color: AppColors.textHint),
                      SizedBox(height: 8),
                      Text('No receipts attached',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _receipts.length,
                  itemBuilder: (ctx, i) {
                    final receipt = _receipts[i];
                    final url = _extractUrl(receipt);
                    final uploadId = _extractId(receipt);
                    return GestureDetector(
                      onTap: () =>
                          _viewFullscreen(context, url, uploadId),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 130,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Stack(fit: StackFit.expand, children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: url.isNotEmpty
                                ? CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                  child:
                                  CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2)),
                              errorWidget: (_, __, ___) =>
                              const Center(
                                  child: Icon(
                                      Icons
                                          .broken_image_outlined,
                                      color:
                                      AppColors.textHint,
                                      size: 32)),
                            )
                                : const Center(
                                child: Icon(
                                    Icons.receipt_long_outlined,
                                    color: AppColors.textHint,
                                    size: 40)),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => _confirmDeleteReceipt(
                                  context, uploadId),
                              child: Container(
                                width: 24, height: 24,
                                decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 4, right: 4,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.fullscreen,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Actions
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () => _showEditSheet(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () => _confirmDelete(context),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _viewFullscreen(BuildContext context, String url, int uploadId) {
    if (url.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Receipt', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteReceipt(context, uploadId);
            },
          ),
        ],
      ),
      body: Center(child: InteractiveViewer(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          errorWidget: (_, __, ___) => const Icon(
              Icons.broken_image_outlined, color: Colors.white, size: 80),
        ),
      )),
    )));
  }

  void _confirmDeleteReceipt(BuildContext context, int uploadId) {
    if (uploadId == 0) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Receipt',
          style: TextStyle(fontWeight: FontWeight.w600)),
      content: const Text('Delete this receipt?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await _api.deleteUpload(widget.token, uploadId);
              await _loadDetail();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt deleted'),
                      backgroundColor: AppColors.success),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()),
                      backgroundColor: AppColors.error),
                );
              }
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Transaction',
          style: TextStyle(fontWeight: FontWeight.w600)),
      content: const Text('Are you sure?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await _api.deleteTransaction(widget.token, widget.expenseId);
              if (mounted) Navigator.pop(context);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(e.toString()
                          .replaceFirst('Exception: ', '')),
                      backgroundColor: AppColors.error),
                );
              }
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }
}