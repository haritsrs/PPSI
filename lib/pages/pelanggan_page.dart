import 'package:flutter/material.dart';
import '../controllers/customer_controller.dart';
import '../widgets/responsive_page.dart';
import '../widgets/customers/customer_app_bar.dart';
import '../widgets/customers/customer_search_filter_section.dart';
import '../widgets/customers/customer_summary_section.dart';
import '../widgets/customers/customer_list_section.dart';
import '../widgets/customers/customer_detail_modal.dart';
import '../widgets/customers/customer_form_dialog.dart';
import '../widgets/customers/customer_delete_dialog.dart';
import '../models/customer_model.dart';

class PelangganPage extends StatefulWidget {
  const PelangganPage({super.key});

  @override
  State<PelangganPage> createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late CustomerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CustomerController()
      ..addListener(_onControllerChanged)
      ..initialize();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _showCustomerDetail(Customer customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomerDetailModal(
        customer: customer,
        databaseService: _controller.databaseService,
        onEdit: () {
          Navigator.pop(context);
          _showEditCustomerDialog(customer);
        },
      ),
    );
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        onSubmit: ({
          required String name,
          required String phone,
          String email = '',
          String address = '',
          String notes = '',
        }) => _controller.addCustomer(
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
        ),
      ),
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        customer: customer,
        onSubmit: ({
          required String name,
          required String phone,
          String email = '',
          String address = '',
          String notes = '',
        }) => _controller.updateCustomer(
          customer.id,
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Customer customer) {
    CustomerDeleteDialog.show(
      context,
      customer: customer,
      onConfirm: () => _controller.deleteCustomer(customer.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle error messages
    if (_controller.errorMessage != null && !_controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomerAppBar(
        onAddCustomer: _showAddCustomerDialog,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ResponsivePage(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerSearchFilterSection(controller: _controller),
                  const SizedBox(height: 24),
                  CustomerSummarySection(controller: _controller),
                  const SizedBox(height: 24),
                  CustomerListSection(
                    controller: _controller,
                    onAddCustomer: _showAddCustomerDialog,
                    onCustomerTap: _showCustomerDetail,
                    onEditCustomer: _showEditCustomerDialog,
                    onDeleteCustomer: _showDeleteConfirmation,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
