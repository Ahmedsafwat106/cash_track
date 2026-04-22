import 'package:flutter/cupertino.dart';

class AmountCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color bgColor;
  final Color textColor;

  const AmountCard({
    super.key,
    required this.title,
    required this.amount,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(amount,
              style: TextStyle(
                  fontSize: 18,
                  color: textColor,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}