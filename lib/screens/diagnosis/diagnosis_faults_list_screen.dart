// lib/screens/diagnosis/diagnosis_faults_list_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/models/diagnosis_models.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/diagnosis_api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'diagnosis_flow_screen.dart';

class DiagnosisFaultsListScreen extends StatefulWidget {
  final ApiService apiService;
  final String category;
  final String device;
  final Color categoryColor;

  const DiagnosisFaultsListScreen({
    super.key,
    required this.apiService,
    required this.category,
    required this.device,
    required this.categoryColor,
  });

  @override
  State<DiagnosisFaultsListScreen> createState() =>
      _DiagnosisFaultsListScreenState();
}

class _DiagnosisFaultsListScreenState extends State<DiagnosisFaultsListScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color red = Color(0xFFDC2626);
  static const Color amber = Color(0xFFF59E0B);
  static const Color green = Color(0xFF10B981);
  static const Color secondaryBlue = Color(0xFF3B82F6);

  late final DiagnosisApiService _api;
  final TextEditingController _searchController = TextEditingController();

  List<DiagnosticFault> _allFaults = [];
  List<DiagnosticFault> _filteredFaults = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _api = DiagnosisApiService(api: widget.apiService);
    _loadFaults();
    _searchController.addListener(_applyLocalFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFaults() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.listFaults(
        category: widget.category,
        device: widget.device,
      );

      if (!mounted) return;

      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => DiagnosticFault.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        setState(() {
          _allFaults = list;
          _filteredFaults = list;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = res['message']?.toString() ?? 'فشل تحميل الأعطال';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطأ في الاتصال: $e';
      });
    }
  }

  void _applyLocalFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredFaults = _allFaults);
      return;
    }

    setState(() {
      _filteredFaults = _allFaults.where((f) {
        final title = f.title.toLowerCase();
        return title.contains(query);
      }).toList();
    });
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'danger':
        return red;
      case 'urgent':
        return amber;
      default:
        return green;
    }
  }

  String _severityLabel(String s) {
    switch (s) {
      case 'danger':
        return 'خطر';
      case 'urgent':
        return 'عاجل';
      default:
        return 'عادي';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            _buildHeader(),
            if (!_loading && _errorMessage == null) _buildSearchBar(),
            Expanded(
              child: _loading
                  ? _buildLoading()
                  : _errorMessage != null
                      ? _buildError()
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اختر المشكلة الأقرب لحالتك',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_loading && _allFaults.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_allFaults.length}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ابحث داخل أعطال ${widget.device}...',
          hintStyle: GoogleFonts.cairo(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF3B82F6), size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _applyLocalFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: const Color(0xFF3B82F6).withOpacity(0.15), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: widget.categoryColor),
          const SizedBox(height: 16),
          Text('جاري تحميل الأعطال...',
              style:
                  GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline_rounded, color: red, size: 48),
            ),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 14, color: Colors.grey.shade700)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadFaults,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('حاول مرة أخرى', style: GoogleFonts.cairo()),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.categoryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_filteredFaults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded,
                    color: Colors.grey.shade400, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'لا توجد أعطال'
                    : 'لا نتائج لـ "${_searchController.text}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _filteredFaults.length,
      itemBuilder: (context, index) {
        final fault = _filteredFaults[index];
        return _buildFaultCard(fault);
      },
    );
  }

  Widget _buildFaultCard(DiagnosticFault fault) {
    final sevColor = _severityColor(fault.severity);
    final sevLabel = _severityLabel(fault.severity);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagnosisFlowScreen(
              apiService: widget.apiService,
              mode: 'symptom',
              prefilledFaultId: fault.id,
              prefilledFaultTitle: fault.title,
              prefilledCategory: widget.category,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 78,
              decoration: BoxDecoration(
                color: sevColor,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fault.title,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sevColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sevLabel,
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: sevColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            fault.id,
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.grey.shade400, size: 18),
            ),
          ],
        ),
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
