// lib/screens/lighting/lighting_projects_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/models/lighting_design_models.dart';
import 'package:GeniusHouse/screens/lighting/lighting_project_summary_screen.dart';
import 'package:GeniusHouse/screens/lighting/lighting_room_wizard_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/lighting_api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class LightingProjectsScreen extends StatefulWidget {
  final ApiService? apiService;
  final StorageService? storageService;

  const LightingProjectsScreen({
    Key? key,
    this.apiService,
    this.storageService,
  }) : super(key: key);

  @override
  State<LightingProjectsScreen> createState() => _LightingProjectsScreenState();
}

class _LightingProjectsScreenState extends State<LightingProjectsScreen> {
  late final ApiService _api;
  late final StorageService _storage;

  List<LightingProject> _projects = [];
  List<LightingProject> _filteredProjects = [];
  bool _loading = true;
  String? _sessionId;

  String _filterStatus = 'all';
  String _sortBy = 'newest';

  bool get _isSypPreferred {
    try {
      return _storage.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  String _formatNumber(double number) {
    final parts = number.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    return '${buffer.toString()}.$decimalPart';
  }

  String _fmt(double amount, {String? currency}) {
    final curr = currency ?? (_isSypPreferred ? 'SYP' : 'USD');
    if (curr == 'SYP') {
      return '${_formatNumber(amount)} SYP';
    }
    return '\$${_formatNumber(amount)}';
  }

  String _fmtShort(double amount, {String? currency}) {
    final curr = currency ?? (_isSypPreferred ? 'SYP' : 'USD');
    if (curr == 'SYP') {
      return '${_formatNumber(amount).split('.').first} SYP';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  @override
  void initState() {
    super.initState();
    _storage = widget.storageService ?? StorageService();
    _api = widget.apiService ?? ApiService(storageService: _storage);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final token = _storage.getToken();
    final isGuest = token == null || token.isEmpty;

    if (isGuest) {
      _sessionId ??= _storage.getLightingSessionId();
      if (_sessionId == null || _sessionId!.isEmpty) {
        final startRes = await _api.lightingDesignStart(requiresAuth: false);
        if (startRes['success'] == true) {
          _sessionId = startRes['data']?['session_id']?.toString();
          if (_sessionId != null) {
            await _storage.saveLightingSessionId(_sessionId!);
          }
        }
      }
    }

    final res = await _api.lightingMyProjects(
      sessionId: isGuest ? _sessionId : null,
      requiresAuth: !isGuest,
    );

    if (!mounted) return;

    if (res['success'] == true && res['data'] is List) {
      final list = (res['data'] as List)
          .map((e) => LightingProject.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _projects = list;
        _applyFilters();
        _loading = false;
      });
    } else {
      setState(() {
        _projects = [];
        _filteredProjects = [];
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    var list = List<LightingProject>.from(_projects);

    if (_filterStatus != 'all') {
      list = list.where((p) => p.status == _filterStatus).toList();
    }

    switch (_sortBy) {
      case 'newest':
        list.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        break;
      case 'oldest':
        list.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
        break;
      case 'price_desc':
        list.sort((a, b) =>
            b.equipmentTotal.amount.compareTo(a.equipmentTotal.amount));
        break;
      case 'price_asc':
        list.sort((a, b) =>
            a.equipmentTotal.amount.compareTo(b.equipmentTotal.amount));
        break;
    }

    setState(() => _filteredProjects = list);
  }

  void _startNewProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LightingRoomWizardScreen(
          apiService: _api,
          storageService: _storage,
          initialSessionId: _sessionId,
        ),
      ),
    );

    if (result != null) _load();
  }

  void _openProject(int projectId) {
    Future.microtask(() {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LightingProjectSummaryScreen(
            apiService: _api,
            storageService: _storage,
            projectId: projectId,
            sessionId: _sessionId,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            _buildAppBarWithCurve(),
            Expanded(child: _buildBody()),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _startNewProject,
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'مشروع جديد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarWithCurve() {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Center(
                    child: Text(
                      'مشاريع الإنارة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 22),
                    onPressed: _load,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_projects.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1E3A8A),
      child: Column(
        children: [
          _buildFiltersBar(),
          _buildStatsBar(),
          Expanded(
            child: _filteredProjects.isEmpty
                ? _buildNoResults()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: _filteredProjects.length,
                    itemBuilder: (_, i) =>
                        _buildProjectCard(_filteredProjects[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'الكل', Icons.apps_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('draft', 'مسودة', Icons.edit_note_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('confirmed', 'مؤكد', Icons.check_circle_rounded),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: Colors.grey.shade300,
            ),
            const SizedBox(width: 16),
            _buildSortButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterStatus = value);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    final labels = {
      'newest': 'الأحدث',
      'oldest': 'الأقدم',
      'price_desc': 'السعر (تنازلي)',
      'price_asc': 'السعر (تصاعدي)',
    };

    return GestureDetector(
      onTap: _showSortSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              labels[_sortBy] ?? 'الترتيب',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    final options = [
      {
        'key': 'newest',
        'label': 'الأحدث أولاً',
        'icon': Icons.arrow_downward_rounded
      },
      {
        'key': 'oldest',
        'label': 'الأقدم أولاً',
        'icon': Icons.arrow_upward_rounded
      },
      {
        'key': 'price_desc',
        'label': 'السعر (الأعلى أولاً)',
        'icon': Icons.trending_down_rounded
      },
      {
        'key': 'price_asc',
        'label': 'السعر (الأقل أولاً)',
        'icon': Icons.trending_up_rounded
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ترتيب المشاريع',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((o) {
              final isSelected = _sortBy == o['key'];
              return ListTile(
                onTap: () {
                  setState(() => _sortBy = o['key'] as String);
                  _applyFilters();
                  Navigator.pop(context);
                },
                leading: Icon(
                  o['icon'] as IconData,
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : Colors.grey.shade600,
                ),
                title: Text(
                  o['label'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey.shade700,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF1E3A8A))
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalRooms = _projects.fold<int>(0, (sum, p) => sum + p.roomCount);
    final totalPower =
        _projects.fold<double>(0, (sum, p) => sum + p.totalPowerW);
    final totalAmount =
        _projects.fold<double>(0, (sum, p) => sum + p.equipmentTotal.amount);

    final displayCurrency = _isSypPreferred ? 'SYP' : 'USD';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF1E3A8A).withOpacity(0.05),
          const Color(0xFF3B82F6).withOpacity(0.02),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              '${_projects.length}', 'مشروع', Icons.home_work_rounded),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildStatItem('$totalRooms', 'غرفة', Icons.meeting_room_rounded),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildStatItem(_fmtNum(totalPower), 'واط', Icons.bolt_rounded),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildStatItem(
            _fmtShort(totalAmount, currency: displayCurrency),
            'إجمالي',
            Icons.payments_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد مشاريع مطابقة',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() => _filterStatus = 'all');
                _applyFilters();
              },
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: Text('مسح الفلتر', style: GoogleFonts.cairo(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  const Color(0xFF3B82F6).withOpacity(0.12),
                  const Color(0xFF8B5CF6).withOpacity(0.08),
                ]),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 64,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد مشاريع بعد',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بتصميم إنارة أول غرفة لك\nواحصل على 3 اقتراحات من منتجات Nex',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewProject,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'مشروع جديد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(LightingProject p) {
    final statusColor = _statusColor(p.status);
    final isDraft = p.status == 'draft';

    final amount = p.equipmentTotal.amount;
    final currency = p.equipmentTotal.currency;

    return Dismissible(
      key: Key('project-${p.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 32),
      ),
      confirmDismiss: (_) => _confirmDelete(p),
      child: GestureDetector(
        onTap: () => _openProject(p.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDraft
                  ? const Color(0xFFF59E0B).withOpacity(0.4)
                  : Colors.grey.shade200,
              width: isDraft ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.projectNumber,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (p.createdAt != null)
                          Text(
                            _formatDate(p.createdAt!),
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (p.isSyp)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SYP',
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p.statusAr,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (isDraft) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'مشروع لم يُعتمد بعد — اضغط للاستكمال',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade100, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStat(
                    Icons.meeting_room_rounded,
                    '${p.roomCount}',
                    'غرفة',
                  ),
                  const SizedBox(width: 20),
                  _buildStat(
                    Icons.bolt_rounded,
                    _fmtNum(p.totalPowerW),
                    'واط',
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الإجمالي',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        _fmt(amount, currency: currency),
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(LightingProject p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'حذف المشروع؟',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم حذف المشروع "${p.projectNumber}" نهائياً.\nلا يمكن التراجع عن هذا الإجراء.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('حذف',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteProject(p.id);
      return true;
    }
    return false;
  }

  Future<void> _deleteProject(int projectId) async {
    final token = _storage.getToken();
    final isGuest = token == null || token.isEmpty;

    try {
      final res = await _api.lightingDeleteProject(
        projectId: projectId,
        sessionId: isGuest ? _sessionId : null,
        requiresAuth: !isGuest,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _projects.removeWhere((p) => p.id == projectId);
          _applyFilters();
        });

        _showSnackBar('تم حذف المشروع ✅', isSuccess: true);
      } else {
        _showSnackBar(res['message']?.toString() ?? 'فشل حذف المشروع');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('خطأ في الحذف: $e');
    }
  }

  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(fontSize: 14)),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'ordered':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _fmtNum(dynamic n) {
    final v = double.tryParse(n.toString()) ?? 0;
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
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
