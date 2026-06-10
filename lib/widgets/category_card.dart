import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CategoryCard extends StatelessWidget {
  final String categoryName;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.categoryName,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'Vegetables':
        return Icons.grass_rounded;
      case 'Fruits':
        return Icons.apple_rounded;
      case 'Groceries':
        return Icons.local_mall_rounded;
      case 'Pickles':
        return Icons.restaurant_menu_rounded;
      case 'Snacks':
        return Icons.cookie_rounded;
      case 'Stationery':
        return Icons.menu_book_rounded;
      case 'Dairy':
        return Icons.opacity_rounded;
      case 'Personal Care':
        return Icons.clean_hands_rounded;
      default:
        return Icons.shopping_basket_rounded;
    }
  }

  Color _getCategoryColor(String name) {
    switch (name) {
      case 'Vegetables':
        return Colors.green.shade600;
      case 'Fruits':
        return Colors.orange.shade500;
      case 'Groceries':
        return Colors.brown.shade500;
      case 'Pickles':
        return Colors.red.shade500;
      case 'Snacks':
        return Colors.amber.shade700;
      case 'Stationery':
        return Colors.blue.shade500;
      case 'Dairy':
        return Colors.teal.shade500;
      case 'Personal Care':
        return Colors.purple.shade400;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(categoryName);
    final icon = _getCategoryIcon(categoryName);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? catColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? catColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: catColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : catColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
