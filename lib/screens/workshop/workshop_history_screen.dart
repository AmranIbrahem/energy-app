// lib/screens/workshop/workshop_history_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class WorkshopHistoryScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const WorkshopHistoryScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  @override
  State<WorkshopHistoryScreen> createState() => _WorkshopHistoryScreenState();
}

class _WorkshopHistoryScreenState extends State<WorkshopHistoryScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _selectedTab = 'all';

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late TabController _tabController;
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await widget.apiService.get(
        '/v1/user/workshop-requests/my-requests',
        requiresAuth: true,
      );

      if (response.containsKey('data') && mounted) {
        final data = response['data'];
        final requestsList = data['workshop_requests'] as List? ?? [];

        setState(() {
          _requests = requestsList
              .map((request) => Map<String, dynamic>.from(request))
              .toList();
          _isLoading = false;
          _isRefreshing = false;
        });

        _slideAnimationController.forward(from: 0.0);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'حدث خطأ في جلب الطلبات';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في الاتصال';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadRequests();
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedTab == 'all') return _requests;
    return _requests
        .where((request) => request['status'] == _selectedTab)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'جاري المعالجة';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'processing':
        return Icons.engineering_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  String _getUrgencyText(String urgency) {
    switch (urgency) {
      case 'normal':
        return 'عادي';
      case 'urgent':
        return 'مستعجل';
      default:
        return urgency;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'normal':
        return Colors.green;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelRequest(int requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.warning_rounded,
                      color: Colors.red.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Text('إلغاء الطلب',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, color: darkColor)),
              ],
            ),
            content: Text('هل أنت متأكد من إلغاء هذا الطلب؟',
                style: GoogleFonts.cairo(fontSize: 15, color: mediumGray)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('تراجع',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w600, color: mediumGray)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('تأكيد الإلغاء',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        final response = await widget.apiService.post(
          '/v1/user/workshop-requests/$requestId/cancel',
          requiresAuth: true,
          data: {},
        );

        if (response['success'] == true) {
          await _loadRequests();
          _showSnackBar('تم إلغاء الطلب بنجاح', primaryBlue);
        } else {
          setState(() => _isLoading = false);
          _showSnackBar(
              response['message'] ?? 'حدث خطأ في إلغاء الطلب', Colors.red);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar('حدث خطأ في الاتصال', Colors.red);
      }
    }
  }

  Future<void> _rateRequest(Map<String, dynamic> request) async {
    int selectedRating = 5;
    final TextEditingController commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تقييم العامل',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, color: darkColor),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (request['assigned_worker'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: primaryBlue.withOpacity(0.1),
                          child: Icon(Icons.person_rounded,
                              color: primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            request['assigned_worker']['full_name'] ?? 'العامل',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(selectedRating),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: GoogleFonts.cairo(color: darkColor),
                  decoration: InputDecoration(
                    hintText: 'أضف تعليقك (اختياري)...',
                    hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: lightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: primaryBlue, width: 2),
                    ),
                  ),
                ),
              ],
            ),
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
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('إرسال التقييم',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);

      try {
        final response = await widget.apiService.post(
          '/v1/user/workshop-requests/${request['id']}/rate',
          requiresAuth: true,
          data: {
            'rating': selectedRating,
            'rating_comment': commentController.text.trim().isEmpty
                ? null
                : commentController.text.trim(),
          },
        );

        if (response['success'] == true) {
          await _loadRequests();
          _showSnackBar('تم إرسال التقييم بنجاح 🎉', primaryBlue);
        } else {
          setState(() => _isLoading = false);
          _showSnackBar(
              response['message'] ?? 'حدث خطأ في إرسال التقييم', Colors.red);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar('حدث خطأ في الاتصال', Colors.red);
      }
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'سيء جداً';
      case 2:
        return 'سيء';
      case 3:
        return 'مقبول';
      case 4:
        return 'جيد';
      case 5:
        return 'ممتاز';
      default:
        return '';
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
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
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
        elevation: 5,
      ));
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.handyman_rounded,
                          color: primaryBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request['workshop_type'] ?? 'غير محدد',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow(
                    Icons.person_rounded, 'الاسم', request['name'] ?? '-'),
                _buildDetailRow(
                    Icons.phone_rounded, 'الهاتف', request['phone'] ?? '-'),
                _buildDetailRow(Icons.location_on_rounded, 'العنوان',
                    request['address'] ?? '-'),
                if (request['preferred_time'] != null)
                  _buildDetailRow(Icons.schedule_rounded, 'الوقت المفضل',
                      request['preferred_time']),
                if (request['booking_datetime'] != null)
                  _buildDetailRow(Icons.calendar_month_rounded, 'موعد الحجز',
                      request['booking_datetime']),
                if (request['problems'] != null &&
                    request['problems'].isNotEmpty)
                  _buildDetailRow(
                      Icons.warning_rounded, 'المشاكل', request['problems']),
                if (request['description'] != null &&
                    request['description'].isNotEmpty)
                  _buildDetailRow(Icons.description_rounded, 'الوصف',
                      request['description']),
                if (request['assigned_worker'] != null)
                  _buildDetailRow(
                    Icons.person_rounded,
                    'العامل المكلف',
                    request['assigned_worker']['full_name'] ?? '-',
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryBlue),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEFF6FF),
                Color(0xFFF5F7FA),
              ],
            ),
          ),
          child: Column(
            children: [
              ClipPath(
                clipper: _BottomCurveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded,
                                      color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseAnimationController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                              scale: 1.0 +
                                                  (_pulseAnimationController
                                                          .value *
                                                      0.1),
                                              child: child);
                                        },
                                        child: const Icon(
                                            Icons.handyman_rounded,
                                            color: Colors.yellow,
                                            size: 24),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('سجل طلبات الورشة',
                                          style: GoogleFonts.cairo(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20)),
                          child: TabBar(
                            controller: _tabController,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFF0F0F0)]),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: primaryBlue,
                            unselectedLabelColor: Colors.white70,
                            labelStyle: GoogleFonts.cairo(
                                fontSize: 12, fontWeight: FontWeight.w700),
                            unselectedLabelStyle: GoogleFonts.cairo(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            tabs: [
                              Tab(
                                  child:
                                      Text('الكل', style: GoogleFonts.cairo())),
                              Tab(
                                  child: Text('قيد الانتظار',
                                      style: GoogleFonts.cairo())),
                              Tab(
                                  child: Text('مكتمل',
                                      style: GoogleFonts.cairo())),
                              Tab(
                                  child:
                                      Text('ملغي', style: GoogleFonts.cairo())),
                            ],
                            onTap: (index) {
                              setState(() {
                                switch (index) {
                                  case 0:
                                    _selectedTab = 'all';
                                    break;
                                  case 1:
                                    _selectedTab = 'pending';
                                    break;
                                  case 2:
                                    _selectedTab = 'completed';
                                    break;
                                  case 3:
                                    _selectedTab = 'cancelled';
                                    break;
                                }
                                _loadRequests();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? _buildShimmerLoading()
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : _filteredRequests.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _refreshRequests,
                                color: primaryBlue,
                                backgroundColor: cardWhite,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredRequests.length,
                                  itemBuilder: (context, index) =>
                                      _buildRequestCard(
                                          _filteredRequests[index], index),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final status = request['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final urgency = request['urgency_level'] ?? 'normal';
    final isRated = request['is_rated'] ?? false;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: statusColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 5))
          ],
          border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.08),
                    statusColor.withOpacity(0.03)
                  ],
                ),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25)),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'workshop_status_${request['id']}',
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withOpacity(0.2),
                            statusColor.withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(_getStatusIcon(status),
                          size: 22, color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['workshop_type'] ?? 'غير محدد',
                          style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: darkColor),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          request['created_at'] != null
                              ? DateTime.parse(request['created_at'])
                                  .toString()
                                  .split(' ')[0]
                              : '',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: mediumGray),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.15),
                          statusColor.withOpacity(0.08)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(_getStatusText(status),
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.person_rounded,
                        label: request['name'] ?? '-',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: _getUrgencyColor(urgency) == Colors.red
                            ? Icons.priority_high_rounded
                            : Icons.low_priority_rounded,
                        label: _getUrgencyText(urgency),
                        color: _getUrgencyColor(urgency),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.location_on_rounded, 'العنوان',
                      request['address'] ?? '-'),
                  if (request['assigned_worker'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: primaryBlue.withOpacity(0.1),
                          child: Icon(Icons.person_rounded,
                              size: 16, color: primaryBlue),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'العامل: ${request['assigned_worker']['full_name'] ?? '-'}',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRequestDetails(request),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: primaryBlue, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('تفاصيل الطلب',
                              style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryBlue)),
                        ),
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _cancelRequest(request['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('إلغاء الطلب',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                      if (status == 'completed' && !isRated) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _rateRequest(request),
                            icon: const Icon(Icons.star_rounded, size: 18),
                            label: Text('تقييم',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: Colors.amber.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (status == 'completed' && isRated) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'تم التقييم: ${request['rating'] ?? 0}/5',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 220,
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handyman_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات سابقة',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم تقم بإرسال أي طلب ورشة بعد',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(0, size.height, 30, size.height);
    path.lineTo(size.width - 30, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
