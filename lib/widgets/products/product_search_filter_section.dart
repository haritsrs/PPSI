import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/product_controller.dart';

class ProductSearchFilterSection extends StatefulWidget {
  final ProductController controller;

  const ProductSearchFilterSection({
    super.key,
    required this.controller,
  });

  @override
  State<ProductSearchFilterSection> createState() => _ProductSearchFilterSectionState();
}

class _ProductSearchFilterSectionState extends State<ProductSearchFilterSection> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        widget.controller.setSearchQuery(value);
      }
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (mounted) {
      widget.controller.setSearchQuery('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cari & Filter Produk",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari produk, supplier, atau barcode...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
              suffixIcon: widget.controller.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      tooltip: 'Bersihkan pencarian',
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF6366F1)),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 16),
          // Category Filter
          Text(
            "Kategori",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.controller.categories.map((category) {
                final isSelected = widget.controller.selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    widget.controller.setSelectedCategory(category);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Stock Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filter Stok",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              DropdownButton<String>(
                value: widget.controller.selectedFilter,
                onChanged: (String? newValue) {
                  widget.controller.setSelectedFilter(newValue!);
                },
                underline: Container(),
                items: widget.controller.filters.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  );
                }).toList(),
                icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF6366F1)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

