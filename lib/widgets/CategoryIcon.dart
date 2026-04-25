import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIcon({super.key, required this.category, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final data = _getCategoryData(category.toLowerCase());
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: data['bg'] as Color,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(data['icon'] as IconData,
          color: data['color'] as Color, size: size * 0.55),
    );
  }

  Map<String, dynamic> _getCategoryData(String cat) {
    if (cat.contains('food') || cat.contains('dining') || cat.contains('eat')) {
      return {'bg': AppColors.foodBg, 'icon': Icons.restaurant, 'color': Colors.orange};
    } else if (cat.contains('transport') || cat.contains('car') || cat.contains('uber')) {
      return {'bg': AppColors.transportBg, 'icon': Icons.directions_car, 'color': Colors.blue};
    } else if (cat.contains('shop') || cat.contains('cloth')) {
      return {'bg': AppColors.shoppingBg, 'icon': Icons.shopping_bag, 'color': Colors.purple};
    } else if (cat.contains('util') || cat.contains('electric') || cat.contains('water')) {
      return {'bg': AppColors.utilitiesBg, 'icon': Icons.bolt, 'color': Colors.green};
    } else if (cat.contains('entertain') || cat.contains('netflix') || cat.contains('movie')) {
      return {'bg': AppColors.entertainmentBg, 'icon': Icons.movie, 'color': Colors.pink};
    } else if (cat.contains('health') || cat.contains('medical')) {
      return {'bg': const Color(0xFFE8F5E9), 'icon': Icons.medical_services, 'color': Colors.teal};
    } else if (cat.contains('education') || cat.contains('course') || cat.contains('udemy')) {
      return {'bg': const Color(0xFFFFF8E1), 'icon': Icons.school, 'color': Colors.amber};
    }
    return {'bg': AppColors.otherBg, 'icon': Icons.category, 'color': Colors.grey};
  }
}