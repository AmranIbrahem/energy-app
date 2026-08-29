// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/models/notification_model.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import '../auth/login_screen.dart';

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

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  bool get _isGuest => !widget.authService.isAuthenticated;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  void _initLoad() {
    if (_isGuest) {
      setState(() => _isLoading = false);
    } else {
      _fetchNotifications();
      _fetchUnreadCount();
    }
  }

  Future<void> _fetchNotifications({bool loadMore = false}) async {
    if (_isGuest) return;

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
    if (_isGuest) return;

    try {
      final response = await widget.apiService.getUnreadNotificationsCount();
      if (response.containsKey('data') && mounted) {
        setState(() {
          _unreadCount = response['data']['unread_count'] ?? 0;
        });
      }
    } catch (e) {}
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (_isGuest || notification.isRead) return;

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
    } catch (e) {}
  }

  Future<void> _markAllAsRead() async {
    if (_isGuest || _unreadCount == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تحديد الكل كمقروء',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: darkColor)),
        content: Text('هل تريد تحديد جميع الإشعارات كمقروءة؟',
            style: GoogleFonts.cairo(color: mediumGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    color: mediumGray, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('تأكيد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
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
        _showSnackBar('تم تحديد جميع الإشعارات كمقروءة', primaryBlue);
      } catch (e) {
        _showSnackBar('حدث خطأ', Colors.red);
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    if (_isGuest) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('حذف الإشعار',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: darkColor)),
        content: Text('هل تريد حذف هذا الإشعار؟',
            style: GoogleFonts.cairo(color: mediumGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    color: mediumGray, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('حذف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
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
        _showSnackBar('تم حذف الإشعار', primaryBlue);
      } catch (e) {
        _showSnackBar('حدث خطأ', Colors.red);
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (_isGuest || _notifications.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('حذف الكل',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
            'هل تريد حذف جميع الإشعارات؟ هذا الإجراء لا يمكن التراجع عنه.',
            style: GoogleFonts.cairo(color: mediumGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    color: mediumGray, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('حذف الكل',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
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
        _showSnackBar('تم حذف جميع الإشعارات', primaryBlue);
      } catch (e) {
        _showSnackBar('حدث خطأ', Colors.red);
      }
    }
  }

  // ✅ عرض تفاصيل الإشعار
  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ مقبض
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ رأس الإشعار
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getNotificationColor(notification.type)
                              .withOpacity(0.15),
                          _getNotificationColor(notification.type)
                              .withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.formattedDate,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // ✅ نص الإشعار الكامل
              Text(
                notification.body,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  color: mediumGray,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
              ),

              const SizedBox(height: 16),

              // ✅ معلومات إضافية
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getNotificationIcon(notification.type),
                      size: 18,
                      color: _getNotificationColor(notification.type),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getNotificationTypeLabel(notification.type),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkColor,
                      ),
                    ),
                    const Spacer(),
                    if (!notification.isRead)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'غير مقروء',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'مقروء',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ زر الحذف
              if (!_isGuest)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteNotification(notification);
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: Colors.red),
                    label: Text(
                      'حذف الإشعار',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ الحصول على اسم نوع الإشعار بالعربي
  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'welcome':
        return 'ترحيب';
      case 'tips':
        return 'نصائح';
      case 'order':
        return 'طلب';
      case 'offer':
        return 'عرض';
      default:
        return 'إشعار عام';
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == primaryBlue
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_rounded,
                color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              'الإشعارات',
              style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isGuest && _notifications.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: Colors.white, size: 22),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color: cardWhite,
                elevation: 10,
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    _markAllAsRead();
                  } else if (value == 'delete_all') {
                    _deleteAllNotifications();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.done_all_rounded,
                              size: 18, color: primaryBlue),
                        ),
                        const SizedBox(width: 12),
                        Text('تحديد الكل كمقروء',
                            style: GoogleFonts.cairo(
                                fontSize: 14, color: darkColor)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_sweep_rounded,
                              size: 18, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Text('حذف الكل',
                            style: GoogleFonts.cairo(
                                fontSize: 14, color: darkColor)),
                      ],
                    ),
                  ),
                ],
              ),
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
      onTap: () {
        // ✅ تحديد كمقروء
        _markAsRead(notification);
        // ✅ عرض تفاصيل الإشعار
        _showNotificationDetails(notification);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : primaryBlue.withOpacity(0.2),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: notification.isRead
                  ? Colors.black.withOpacity(0.03)
                  : primaryBlue.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getNotificationColor(notification.type).withOpacity(0.15),
                    _getNotificationColor(notification.type).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: mediumGray,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        notification.formattedDate,
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 12),
                      // ✅ زر عرض التفاصيل
                      GestureDetector(
                        onTap: () => _showNotificationDetails(notification),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'عرض التفاصيل',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 12, color: primaryBlue),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_isGuest)
              IconButton(
                onPressed: () => _deleteNotification(notification),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                ),
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
              color: cardWhite,
              borderRadius: BorderRadius.circular(20),
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
            ? const CircularProgressIndicator(color: primaryBlue)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardWhite,
              boxShadow: [
                BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Icon(Icons.error_outline_rounded,
                size: 50, color: Colors.red.shade300),
          ),
          const SizedBox(height: 20),
          Text(_errorMessage!,
              style: GoogleFonts.cairo(fontSize: 16, color: mediumGray)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _fetchNotifications(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text('إعادة المحاولة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardWhite,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              _isGuest
                  ? Icons.lock_outline_rounded
                  : Icons.notifications_none_rounded,
              size: 55,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isGuest ? 'سجل دخولك لعرض الإشعارات' : 'لا توجد إشعارات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isGuest
                ? 'يجب تسجيل الدخول للاطلاع على الإشعارات الخاصة بك'
                : 'ستظهر الإشعارات هنا عند استلامها',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: mediumGray,
            ),
          ),
          if (_isGuest) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      authService: widget.authService,
                      storageService: widget.authService.storageService,
                    ),
                  ),
                ).then((_) {
                  _initLoad();
                });
              },
              icon: const Icon(Icons.login_rounded, size: 20),
              label: Text(
                'تسجيل الدخول',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'welcome':
        return Icons.celebration_rounded;
      case 'tips':
        return Icons.lightbulb_rounded;
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'offer':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
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