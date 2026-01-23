import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/kasir_controller.dart';

class SearchAndCategorySection extends StatelessWidget {
  final KasirController controller;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final double paddingScale;
  final double iconScale;
  final bool? useCleanLayout;
  final VoidCallback? onToggleLayout;

  const SearchAndCategorySection({
    super.key,
    required this.controller,
    required this.searchController,
    required this.searchFocusNode,
    required this.paddingScale,
    required this.iconScale,
    this.useCleanLayout,
    this.onToggleLayout,
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
          // Search Bar with toggle
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    onChanged: (value) {
                      controller.setSearchQuery(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: const Color(0xFF545BFF),
                        size: 20 * iconScale,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0x00FFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF545BFF), width: 1.4),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16 * paddingScale,
                        vertical: 12 * paddingScale,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              if (onToggleLayout != null) ...[
                SizedBox(width: 8 * paddingScale),
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
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onToggleLayout!();
                    },
                    icon: Icon(
                      useCleanLayout == true ? Icons.view_list_rounded : Icons.view_module_rounded,
                      color: const Color(0xFF545BFF),
                      size: 22 * iconScale,
                    ),
                    tooltip: useCleanLayout == true
                        ? 'Tampilan Vertikal'
                        : 'Tampilan Horizontal',
                    padding: EdgeInsets.all(10 * paddingScale),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ],
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


