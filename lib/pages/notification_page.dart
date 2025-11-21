import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notifications/notification_app_bar.dart';
import '../widgets/notifications/notification_filter_section.dart';
import '../widgets/notifications/notification_card.dart';
import '../widgets/notifications/empty_notification_state.dart';
import '../widgets/notifications/delete_all_confirmation_dialog.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationController();
    _controller.addListener(_handleControllerChange);
    
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
    _loadNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadNotifications() async {
    try {
      await _controller.loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleMarkAsRead(notification) async {
    try {
      await _controller.markAsRead(notification);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    try {
      await _controller.markAllAsRead();
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sebagai dibaca'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteNotification(notification) async {
    try {
      await _controller.deleteNotification(notification);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAllNotifications() async {
    final confirmed = await DeleteAllConfirmationDialog.show(context);

    if (confirmed == true) {
      try {
        await _controller.deleteAllNotifications();
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Semua notifikasi dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: NotificationAppBar(
        unreadCount: _controller.unreadCount,
        onMarkAllAsRead: _controller.notifications.isNotEmpty &&
                _controller.unreadCount > 0
            ? _handleMarkAllAsRead
            : null,
        onDeleteAll: _controller.notifications.isNotEmpty
            ? _handleDeleteAllNotifications
            : null,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                )
              : Column(
                  children: [
                    NotificationFilterSection(
                      filters: _controller.filters,
                      selectedFilter: _controller.selectedFilter,
                      onFilterChanged: _controller.setFilter,
                    ),
                    Expanded(
                      child: _controller.filteredNotifications.isEmpty
                          ? EmptyNotificationState(
                              hasNotifications: _controller.notifications.isNotEmpty,
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _controller.filteredNotifications.length,
                                itemBuilder: (context, index) {
                                  final notification =
                                      _controller.filteredNotifications[index];
                                  return NotificationCard(
                                    notification: notification,
                                    onTap: () {
                                      if (!notification.isRead) {
                                        _handleMarkAsRead(notification);
                                      }
                                    },
                                    onDelete: () =>
                                        _handleDeleteNotification(notification),
                                  );
                                },
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

