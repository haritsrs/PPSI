import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/product_model.dart';
import '../../../services/database_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/security_utils.dart';
import '../../../utils/error_helper.dart';
import '../../../utils/currency_input_formatter.dart';

class AddEditProductDialog extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaved;

  const AddEditProductDialog({
    super.key,
    this.product,
    required this.onSaved,
  });

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _supplierController = TextEditingController();
  final _categoryController = TextEditingController();
  final _barcodeController = TextEditingController();
  
  String _selectedEmoji = '📦';
  bool _isLoading = false;
  File? _selectedImageFile;
  String? _imageUrl;
  bool _isUploadingImage = false;
  
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Popular emojis for products
  final List<String> _emojiCategories = [
    '🍔', '🍕', '🍟', '🌮', '🌯', '🥗', '🍛', '🍜', '🍝', '🍱',
    '🍣', '🍤', '🍗', '🍖', '🥩', '🍳', '🧀', '🥚', '🥞', '🧇',
    '🥐', '🍞', '🥖', '🥨', '🧈', '🥓', '🥪', '🌭', '🍿', '🥜',
    '🍫', '🍬', '🍭', '🍮', '🍯', '🧁', '🍰', '🎂', '🍪', '🍩',
    '☕', '🍵', '🥤', '🧃', '🧉', '🍶', '🍺', '🍻', '🥂', '🍷',
    '🧊', '🥛', '🍼', '🍾', '🧂', '🥢', '🍴', '🥄', '🔪', '🍽️',
    '📦', '🛒', '🛍️', '💰', '💎', '🎁', '🎀', '🏷️',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      // Format price with periods
      final priceStr = widget.product!.price.toStringAsFixed(0);
      _priceController.text = priceStr.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
      _stockController.text = widget.product!.stock.toString();
      _minStockController.text = widget.product!.minStock.toString();
      _supplierController.text = widget.product!.supplier;
      _categoryController.text = widget.product!.category;
      _barcodeController.text = widget.product!.barcode;
      _selectedEmoji = widget.product!.image.isNotEmpty ? widget.product!.image : '📦';
      _imageUrl = widget.product!.imageUrl.isNotEmpty ? widget.product!.imageUrl : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _supplierController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _imageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _imageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteImage() async {
    if (_imageUrl != null && widget.product != null) {
      // Delete from Firebase Storage
      try {
        await StorageService.deleteProductImage(_imageUrl!);
      } catch (error) {
        if (mounted) {
          final message = getFriendlyErrorMessage(
            error,
            fallbackMessage: 'Gagal menghapus gambar produk.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
    
    setState(() {
      _selectedImageFile = null;
      _imageUrl = null;
    });
  }

  double? _tryParsePrice(String value) {
    if (value.isEmpty) return null;
    // Use CurrencyInputFormatter to parse formatted currency
    return CurrencyInputFormatter.parseFormattedCurrency(value);
  }

  double _parsePrice(String value) => _tryParsePrice(value) ?? 0;

  int? _tryParseInt(String value) {
    final sanitized = SecurityUtils.sanitizeNumber(value).replaceAll(RegExp(r'[^0-9-]'), '');
    if (sanitized.isEmpty) return null;
    return int.tryParse(sanitized);
  }

  int _parseInt(String value) => _tryParseInt(value) ?? 0;

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String finalImageUrl = _imageUrl ?? '';
      
      // Upload new image if selected
      if (_selectedImageFile != null) {
        setState(() {
          _isUploadingImage = true;
        });
        
        try {
          // Delete old image if exists
          if (widget.product != null && widget.product!.imageUrl.isNotEmpty) {
            await StorageService.deleteProductImage(widget.product!.imageUrl);
          }
          
          // Get product ID (use existing or generate new)
          final productId = widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
          
          // Upload new image
          finalImageUrl = await StorageService.uploadProductImage(
            imageFile: _selectedImageFile!,
            productId: productId,
          );
        } catch (error) {
          if (mounted) {
            final message = getFriendlyErrorMessage(
              error,
              fallbackMessage: 'Gagal mengunggah gambar produk.',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } finally {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }

      final productData = {
        'name': SecurityUtils.sanitizeInput(_nameController.text),
        'description': SecurityUtils.sanitizeInput(_descriptionController.text),
        'price': _parsePrice(_priceController.text),
        'stock': _parseInt(_stockController.text),
        'minStock': _tryParseInt(_minStockController.text) ?? 10,
        'supplier': SecurityUtils.sanitizeInput(_supplierController.text),
        'category': SecurityUtils.sanitizeInput(_categoryController.text),
        'barcode': SecurityUtils.sanitizeInput(_barcodeController.text),
        'image': _selectedEmoji,
        'imageUrl': finalImageUrl,
      };

      String productId;
      if (widget.product != null) {
        // Update existing product
        productId = widget.product!.id;
        await _databaseService.updateProduct(productId, productData);
      } else {
        // Add new product
        productId = await _databaseService.addProduct(productData);
        
        // If we have a new image but product ID wasn't available before, re-upload with correct ID
        if (_selectedImageFile != null && finalImageUrl.isEmpty) {
          try {
            finalImageUrl = await StorageService.uploadProductImage(
              imageFile: _selectedImageFile!,
              productId: productId,
            );
            await _databaseService.updateProduct(productId, {'imageUrl': finalImageUrl});
          } catch (error) {
            if (mounted) {
              final message = getFriendlyErrorMessage(
                error,
                fallbackMessage: 'Gagal memperbarui gambar produk.',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null 
                ? 'Produk berhasil diperbarui!' 
                : 'Produk berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        final message = getFriendlyErrorMessage(
          error,
          fallbackMessage: 'Gagal menyimpan data produk.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.product != null ? "Edit Produk" : "Tambah Produk",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Upload Section
                      Text(
                        "Gambar Produk",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Image Preview
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF6366F1).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: _isUploadingImage
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : _selectedImageFile != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: Image.file(
                                              _selectedImageFile!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : _imageUrl != null && _imageUrl!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: CachedNetworkImage(
                                                  imageUrl: _imageUrl!,
                                                  fit: BoxFit.cover,
                                                  memCacheHeight: 320,
                                                  memCacheWidth: 320,
                                                  fadeInDuration: const Duration(milliseconds: 200),
                                                  placeholder: (context, url) => const Center(
                                                    child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) => Center(
                                                    child: Text(
                                                      _selectedEmoji,
                                                      style: const TextStyle(fontSize: 48),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _selectedEmoji,
                                                      style: const TextStyle(fontSize: 48),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    const Icon(
                                                      Icons.add_photo_alternate_rounded,
                                                      size: 20,
                                                      color: Colors.grey,
                                                    ),
                                                  ],
                                                ),
                                              ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                                  label: const Text('Unggah Gambar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                if ((_selectedImageFile != null || (_imageUrl != null && _imageUrl!.isNotEmpty)) && !_isUploadingImage) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _deleteImage,
                                    icon: const Icon(Icons.delete_rounded),
                                    color: Colors.red,
                                    tooltip: 'Hapus Gambar',
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Emoji Selector
                      Text(
                        "Pilih Emoji",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Selected Emoji Preview
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _selectedEmoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Emoji Grid
                            SizedBox(
                              height: 200,
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _emojiCategories.length,
                                itemBuilder: (context, index) {
                                  final emoji = _emojiCategories[index];
                                  final isSelected = _selectedEmoji == emoji;
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedEmoji = emoji;
                                      });
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? const Color(0xFF6366F1).withOpacity(0.2)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected 
                                              ? const Color(0xFF6366F1)
                                              : Colors.grey.withOpacity(0.2),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Product Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Produk *',
                          hintText: 'Masukkan nama produk',
                          prefixIcon: const Icon(Icons.inventory_2_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          hintText: 'Masukkan deskripsi produk',
                          prefixIcon: const Icon(Icons.description_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      // Price and Stock in Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                labelText: 'Harga Jual *',
                                hintText: 'Contoh: 25.000',
                                helperText: 'Harga jual per unit',
                                helperMaxLines: 1,
                                prefixText: 'Rp ',
                                prefixIcon: Tooltip(
                                  message: 'Masukkan harga jual produk dalam Rupiah',
                                  child: const Icon(Icons.attach_money_rounded),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: Tooltip(
                                  message: 'Masukkan harga jual untuk pelanggan. Format: angka dengan pemisah ribuan (titik).',
                                  child: Icon(Icons.info_outline, size: 20, color: Colors.grey[500]),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Harga wajib diisi';
                                }
                                final parsed = _tryParsePrice(value);
                                if (parsed == null || parsed <= 0) {
                                  return 'Masukkan harga yang valid (lebih dari 0)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: InputDecoration(
                                labelText: 'Stok Awal *',
                                hintText: 'Contoh: 100',
                                helperText: 'Jumlah unit tersedia',
                                helperMaxLines: 1,
                                prefixIcon: Tooltip(
                                  message: 'Jumlah stok awal produk',
                                  child: const Icon(Icons.inventory_rounded),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Stok wajib diisi';
                                }
                                final parsed = _tryParseInt(value);
                                if (parsed == null || parsed < 0) {
                                  return 'Masukkan angka yang valid (≥0)';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Min Stock and Supplier
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minStockController,
                              decoration: InputDecoration(
                                labelText: 'Peringatan Stok Rendah',
                                hintText: '10 (opsional)',
                                prefixIcon: const Icon(Icons.warning_amber_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                helperText: 'Notifikasi akan muncul saat stok mencapai nilai ini',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final parsed = _tryParseInt(value);
                                  if (parsed == null || parsed < 0) {
                                    return 'Nilai tidak valid';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _supplierController,
                              decoration: InputDecoration(
                                labelText: 'Supplier',
                                hintText: 'Nama supplier',
                                prefixIcon: const Icon(Icons.business_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Category and Barcode
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _categoryController,
                              decoration: InputDecoration(
                                labelText: 'Kategori *',
                                hintText: 'Makanan, Minuman, dll',
                                prefixIcon: const Icon(Icons.category_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Kategori wajib diisi';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: InputDecoration(
                                labelText: 'Barcode',
                                hintText: 'Scan atau masukkan barcode',
                                prefixIcon: const Icon(Icons.qr_code_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded),
                            const SizedBox(width: 8),
                            Text(
                              widget.product != null ? "Simpan Perubahan" : "Simpan Produk",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

