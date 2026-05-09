import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const NotificationsScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _fetchUnreadCount();
  }

  Future<void> _fetchNotifications({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _notifications = [];
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final response = await widget.apiService.getAllNotifications(
        page: _currentPage,
        perPage: 20,
      );

      if (response.containsKey('data') && mounted) {
        final data = response['data'];
        final List<dynamic> notificationsJson = data['notifications'] ?? [];

        // ✅ عكس الترتيب: الأحدث (id أكبر) في الأعلى
        final List<NotificationModel> newNotifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList()
            .reversed
            .toList();

        final total = data['total'] ?? 0;
        final currentPage = data['current_page'] ?? _currentPage;
        final lastPage = data['last_page'] ?? 1;

        if (loadMore) {
          setState(() {
            _notifications.addAll(newNotifications);
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _notifications = newNotifications;
            _isLoading = false;
          });
        }

        setState(() {
          _hasMore = currentPage < lastPage;
          if (_hasMore) _currentPage = currentPage + 1;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل الإشعارات';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await widget.apiService.getUnreadNotificationsCount();
      if (response.containsKey('data') && mounted) {
        setState(() {
          _unreadCount = response['data']['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await widget.apiService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            readAt: DateTime.now(),
            createdAt: notification.createdAt,
          );
        }
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تحديد الكل كمقروء',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد تحديد جميع الإشعارات كمقروءة؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: Text('تأكيد', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.apiService.markAllAsRead();
        setState(() {
          for (var i = 0; i < _notifications.length; i++) {
            if (_notifications[i].readAt == null) {
              _notifications[i] = NotificationModel(
                id: _notifications[i].id,
                title: _notifications[i].title,
                body: _notifications[i].body,
                type: _notifications[i].type,
                readAt: DateTime.now(),
                createdAt: _notifications[i].createdAt,
              );
            }
          }
          _unreadCount = 0;
        });
        _showSnackBar('تم تحديد جميع الإشعارات كمقروءة', Colors.green);
      } catch (e) {
        _showSnackBar('حدث خطأ', Colors.red);
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'حذف الإشعار',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد حذف هذا الإشعار؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.apiService.deleteNotification(notification.id);
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
          if (!notification.isRead) {
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          }
        });
        _showSnackBar('تم حذف الإشعار', Colors.green);
      } catch (e) {
        _showSnackBar('حدث خطأ', Colors.red);
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (_notifications.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'حذف الكل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          'هل تريد حذف جميع الإشعارات؟ هذا الإجراء لا يمكن التراجع عنه.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('حذف الكل', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.apiService.deleteAllNotifications();
        setState(() {
          _notifications = [];
          _unreadCount = 0;
        });
        _showSnackBar('تم حذف جميع الإشعارات', Colors.green);
      } catch (e) {
        _showSnackBar('حدث خطأ', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'الإشعارات',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                } else if (value == 'delete_all') {
                  _deleteAllNotifications();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20, color: Color(0xFF4CAF50)),
                      SizedBox(width: 12),
                      Text('تحديد الكل كمقروء'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('حذف الكل'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _notifications.isEmpty
          ? _buildEmptyWidget()
          : _buildNotificationsList(),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length && _hasMore) {
          return _buildLoadMoreIndicator();
        }
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return GestureDetector(
      onTap: () => _markAsRead(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // النوع (أيقونة)
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // المحتوى
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        notification.formattedDate,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // زر الحذف
            IconButton(
              onPressed: () => _deleteNotification(notification),
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            height: 100,
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(color: Color(0xFF4CAF50))
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _fetchNotifications(),
            icon: const Icon(Icons.refresh),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر الإشعارات هنا عند استلامها',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'welcome':
        return Icons.celebration;
      case 'tips':
        return Icons.lightbulb;
      case 'order':
        return Icons.shopping_bag;
      case 'offer':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'welcome':
        return Colors.purple;
      case 'tips':
        return Colors.orange;
      case 'order':
        return Colors.blue;
      case 'offer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}