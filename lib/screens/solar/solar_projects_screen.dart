// lib/screens/solar/solar_projects_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/models/solar_design_models.dart';
import 'package:GeniusHouse/screens/solar/solar_project_summary_screen.dart';
import 'package:GeniusHouse/screens/solar/solar_wizard_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/solar_api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class SolarProjectsScreen extends StatefulWidget {
  final ApiService? apiService;
  final StorageService? storageService;

  const SolarProjectsScreen({
    Key? key,
    this.apiService,
    this.storageService,
  }) : super(key: key);

  @override
  State<SolarProjectsScreen> createState() => _SolarProjectsScreenState();
}

class _SolarProjectsScreenState extends State<SolarProjectsScreen> {
  late final ApiService _api;
  late final StorageService _storage;

  List<SolarProject> _projects = [];
  List<SolarProject> _filtered = [];
  bool _loading = true;
  String? _sessionId;

  String _sortBy = 'newest';

  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  bool get _isSypPreferred {
    try {
      return _storage.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  String _formatNumber(double n) {
    final parts = n.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final dec = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${buf.toString()}.$dec';
  }

  String _fmt(double amount, {String? currency}) {
    final curr = currency ?? (_isSypPreferred ? 'SYP' : 'USD');
    if (curr == 'SYP') return '${_formatNumber(amount)} SYP';
    return '\$${_formatNumber(amount)}';
  }

  String _fmtShort(double amount, {String? currency}) {
    final curr = currency ?? (_isSypPreferred ? 'SYP' : 'USD');
    if (curr == 'SYP') return '${_formatNumber(amount).split('.').first} SYP';
    return '\$${amount.toStringAsFixed(0)}';
  }

  String _fmtNum(dynamic n) {
    final v = double.tryParse(n.toString()) ?? 0;
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
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
      _sessionId ??= _storage.getGuestSolarSessionId();
    }

    final res = await _api.solarMyProjects(
      sessionId: isGuest ? _sessionId : null,
      requiresAuth: !isGuest,
    );

    if (!mounted) return;

    if (res['success'] == true && res['data'] is List) {
      final list = (res['data'] as List)
          .map((e) => SolarProject.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _projects = list;
        _applyFilters();
        _loading = false;
      });
    } else {
      setState(() {
        _projects = [];
        _filtered = [];
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final list = List<SolarProject>.from(_projects);
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
    setState(() => _filtered = list);
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        if (_selectedIds.length >= 3) {
          _showSnackBar('يمكنك اختيار 3 مشاريع كحد أقصى');
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _openCompare() async {
    if (_selectedIds.length < 2) {
      _showSnackBar('اختر مشروعين على الأقل');
      return;
    }

    final token = _storage.getToken();
    final isGuest = token == null || token.isEmpty;

    final res = await _api.solarCompareProjects(
      projectIds: _selectedIds.toList(),
      sessionId: isGuest ? _sessionId : null,
      requiresAuth: !isGuest,
    );

    if (!mounted) return;

    if (res['success'] == true && res['data'] is Map) {
      final projects = (res['data']['projects'] as List? ?? [])
          .map((e) => SolarProject.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SolarCompareScreen(projects: projects),
        ),
      ).then((_) => _exitSelectionMode());
    } else {
      _showSnackBar(res['message']?.toString() ?? 'فشل المقارنة');
    }
  }

  void _startNewDesign() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolarWizardScreen(
          apiService: _api,
          storageService: _storage,
        ),
      ),
    );
    if (result != null) _load();
  }

  void _openProject(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolarProjectSummaryScreen(
          apiService: _api,
          storageService: _storage,
          projectId: id,
          sessionId: _sessionId,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildBody()),
          ],
        ),
        floatingActionButton: _selectionMode
            ? FloatingActionButton.extended(
                onPressed: _openCompare,
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.compare_arrows_rounded),
                label: Text(
                  'قارن (${_selectedIds.length})',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              )
            : FloatingActionButton.extended(
                onPressed: _startNewDesign,
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'تصميم جديد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
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
                    icon: Icon(
                      _selectionMode
                          ? Icons.close_rounded
                          : Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _selectionMode
                        ? _exitSelectionMode
                        : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Center(
                    child: Text(
                      _selectionMode
                          ? 'اختر مشاريع للمقارنة (${_selectedIds.length}/3)'
                          : 'مشاريع المنظومات الشمسية',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!_selectionMode)
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
                  )
                else
                  const SizedBox(width: 48),
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
          _buildStatsBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _buildProjectCard(_filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalKwh = _projects.fold<double>(0, (s, p) => s + p.dailyEnergyKwh);
    final totalAmount =
        _projects.fold<double>(0, (s, p) => s + p.equipmentTotal.amount);
    final displayCurrency = _isSypPreferred ? 'SYP' : 'USD';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          _statItem('${_projects.length}', 'مشروع', Icons.home_work_rounded),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _statItem(
              '${totalKwh.toStringAsFixed(1)}', 'kWh', Icons.bolt_rounded),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _statItem(
            _fmtShort(totalAmount, currency: displayCurrency),
            'إجمالي',
            Icons.payments_rounded,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            )),
        Text(label,
            style: GoogleFonts.cairo(
              fontSize: 9,
              color: Colors.grey.shade500,
            )),
      ],
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
              child: const Icon(Icons.solar_power_rounded,
                  size: 64, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 20),
            Text('لا توجد مشاريع بعد',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                )),
            const SizedBox(height: 8),
            Text(
              'ابدأ بتصميم أول منظومة شمسية\nواحفظها كمسودة للرجوع إليها لاحقًا',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewDesign,
              icon: const Icon(Icons.add_rounded),
              label: Text('تصميم جديد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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

  Widget _buildProjectCard(SolarProject p) {
    final isSelected = _selectedIds.contains(p.id);
    final amount = p.equipmentTotal.amount;
    final currency = p.equipmentTotal.currency;

    return Dismissible(
      key: Key('solar-project-${p.id}'),
      direction:
          _selectionMode ? DismissDirection.none : DismissDirection.endToStart,
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
        onTap: () {
          if (_selectionMode) {
            _toggleSelection(p.id);
          } else {
            _openProject(p.id);
          }
        },
        onLongPress: () {
          if (!_selectionMode) {
            setState(() {
              _selectionMode = true;
              _selectedIds.add(p.id);
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFFF59E0B).withOpacity(0.4),
              width: isSelected ? 2 : 1.5,
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
                  if (_selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF8B5CF6)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.solar_power_rounded,
                        color: Color(0xFF1E3A8A)),
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
                                fontSize: 11, color: Colors.grey.shade500),
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
                      child: Text('SYP',
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          )),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p.statusAr,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
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
                        'مسودة — اضغط للاطلاع على التفاصيل',
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
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade100, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _stat(Icons.devices_rounded, '${p.loadsCount}', 'جهاز'),
                  const SizedBox(width: 14),
                  _stat(Icons.bolt_rounded, p.dailyEnergyKwh.toStringAsFixed(1),
                      'kWh'),
                  const SizedBox(width: 14),
                  _stat(Icons.speed_rounded, p.continuousKw.toStringAsFixed(2),
                      'kW'),
                  const Spacer(),
                  if (p.chosenPlanKey != null && p.chosenPlanKey!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(p.planKeyAr,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B5CF6),
                          )),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('الإجمالي',
                          style: GoogleFonts.cairo(
                              fontSize: 10, color: Colors.grey.shade500)),
                      Text(
                        _fmt(amount, currency: currency),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
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

  Widget _stat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Text(value,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            )),
        const SizedBox(width: 2),
        Text(label,
            style:
                GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }

  Future<bool> _confirmDelete(SolarProject p) async {
    final ok = await showDialog<bool>(
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
            Text('حذف المشروع؟',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                )),
            const SizedBox(height: 8),
            Text(
              'سيتم حذف "${p.projectNumber}" نهائيًا.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.5),
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

    if (ok == true) {
      await _deleteProject(p.id);
      return true;
    }
    return false;
  }

  Future<void> _deleteProject(int projectId) async {
    final token = _storage.getToken();
    final isGuest = token == null || token.isEmpty;

    final res = await _api.solarDeleteProject(
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
      _showSnackBar(res['message']?.toString() ?? 'فشل الحذف');
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

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class SolarCompareScreen extends StatelessWidget {
  final List<SolarProject> projects;

  const SolarCompareScreen({Key? key, required this.projects})
      : super(key: key);

  bool get _isSypPreferred {
    return false;
  }

  String _fmt(dynamic amount, String currency) {
    final v = double.tryParse(amount.toString()) ?? 0;
    final n = v.toStringAsFixed(2);
    if (currency == 'SYP') return '$n SYP';
    return '\$$n';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: Text('مقارنة المشاريع',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRow(
                  'رقم المشروع', projects.map((p) => p.projectNumber).toList()),
              _buildRow(
                  'التاريخ', projects.map((p) => p.createdAt ?? '—').toList()),
              _buildRow('المحافظة',
                  projects.map((p) => p.governorate ?? '—').toList()),
              _buildRow('عدد الأجهزة',
                  projects.map((p) => '${p.loadsCount}').toList()),
              _buildRow(
                  'الاستهلاك اليومي (kWh)',
                  projects
                      .map((p) => p.dailyEnergyKwh.toStringAsFixed(2))
                      .toList()),
              _buildRow(
                  'الحمل المتزامن (kW)',
                  projects
                      .map((p) => p.continuousKw.toStringAsFixed(2))
                      .toList()),
              _buildRow(
                  'الخطة',
                  projects
                      .map((p) => p.planKeyAr.isEmpty ? '—' : p.planKeyAr)
                      .toList()),
              _buildRow(
                  'الألواح', projects.map((p) => '${p.panelUnits}').toList()),
              _buildRow('البطاريات',
                  projects.map((p) => '${p.batteryUnits}').toList()),
              _buildRow(
                  'العاكس (W)',
                  projects
                      .map((p) => p.inverterRatedW.toStringAsFixed(0))
                      .toList()),
              _buildRow('مصفوفة PV (W)',
                  projects.map((p) => p.pvArrayW.toStringAsFixed(0)).toList()),
              _buildRow(
                  'الإجمالي',
                  projects
                      .map((p) => _fmt(
                          p.equipmentTotal.amount, p.equipmentTotal.currency))
                      .toList(),
                  highlight: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, List<String> values,
      {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF10B981).withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? const Color(0xFF10B981).withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              )),
          const SizedBox(height: 6),
          Row(
            children: values
                .map((v) => Expanded(
                      child: Text(
                        v,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight:
                              highlight ? FontWeight.bold : FontWeight.w600,
                          color: highlight
                              ? const Color(0xFF10B981)
                              : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ))
                .toList(),
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
