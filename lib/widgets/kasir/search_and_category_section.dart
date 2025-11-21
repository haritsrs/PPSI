import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/kasir_controller.dart';
import '../../utils/responsive_helper.dart';

class SearchAndCategorySection extends StatelessWidget {
  final KasirController controller;
  final TextEditingController searchController;
  final double paddingScale;
  final double iconScale;

  const SearchAndCategorySection({
    super.key,
    required this.controller,
    required this.searchController,
    required this.paddingScale,
    required this.iconScale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * paddingScale,
        vertical: 12 * paddingScale,
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                controller.setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: const Color(0xFF6366F1),
                  size: 20 * iconScale,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16 * paddingScale,
                  vertical: 12 * paddingScale,
                ),
              ),
            ),
          ),
          SizedBox(height: 12 * paddingScale),
          
          // Category Tabs
          SizedBox(
            height: 36 * paddingScale,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                final isSelected = controller.selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    controller.setSelectedCategory(category);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8 * paddingScale),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * paddingScale,
                      vertical: 8 * paddingScale,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

