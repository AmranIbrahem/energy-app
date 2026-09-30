// lib/screens/diagnosis/diagnosis_search_screen.dart

import 'dart:async';
import 'dart:ui' as ui;

import 'package:GeniusHouse/models/diagnosis_models.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/diagnosis_api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'diagnosis_flow_screen.dart';

class DiagnosisSearchScreen extends StatefulWidget {
  final ApiService apiService;

  const DiagnosisSearchScreen({super.key, required this.apiService});

  @override
  State<DiagnosisSearchScreen> createState() => _DiagnosisSearchScreenState();
}

class _DiagnosisSearchScreenState extends State<DiagnosisSearchScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color red = Color(0xFFDC2626);
  static const Color amber = Color(0xFFF59E0B);
  static const Color green = Color(0xFF10B981);

  late final DiagnosisApiService _api;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  List<SearchResult> _results = [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  static const List<String> _quickSuggestions = [
    'بطارية',
    'شرر',
    'ماء',
    'دخان',
    'حرارة',
    'قاطع',
    'لمبة',
    'محول',
  ];

  @override
  void initState() {
    super.initState();
    _api = DiagnosisApiService(api: widget.apiService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _loading = false;
        _errorMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.search(query: query);

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        final searchRes =
            SearchResponse.fromJson(Map<String, dynamic>.from(res['data']));
        setState(() {
          _results = searchRes.results;
          _hasSearched = true;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = res['message']?.toString() ?? 'فشل البحث';
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

  void _submitQuickSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _performSearch(suggestion);
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

  String _categoryLabel(String c) {
    switch (c) {
      case 'solar':
        return 'شمسي';
      case 'electricity':
        return 'كهرباء';
      case 'lighting':
        return 'إنارة';
      default:
        return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildSearchField(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: primaryBlue, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'البحث في الأعطال',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onTextChanged,
        style: GoogleFonts.cairo(fontSize: 15),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'ابحث عن عطل... (بطارية، شرر، ماء)',
          hintStyle: GoogleFonts.cairo(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
          prefixIcon:
              const Icon(Icons.search_rounded, color: secondaryBlue, size: 22),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.grey, size: 20),
                  onPressed: () {
                    _controller.clear();
                    _onTextChanged('');
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
              color: secondaryBlue.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: secondaryBlue, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: secondaryBlue),
            const SizedBox(height: 16),
            Text('جاري البحث...',
                style: GoogleFonts.cairo(
                    fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade700)),
        ),
      );
    }

    if (!_hasSearched) {
      return _buildSuggestions();
    }

    if (_results.isEmpty) {
      return _buildNoResults();
    }

    return _buildResults();
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'اقتراحات سريعة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((s) {
              return GestureDetector(
                onTap: () => _submitQuickSuggestion(s),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: secondaryBlue.withOpacity(0.2)),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: primaryBlue,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  color: Colors.grey.shade400, size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد نتائج',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرّب كلمة أخرى مثل "بطارية"، "شرر"، "حرارة"',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_results.length} نتيجة',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        final result = _results[index - 1];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    final sevColor = _severityColor(result.severity);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagnosisFlowScreen(
              apiService: widget.apiService,
              mode: 'symptom',
              prefilledFaultId: result.id,
              prefilledFaultTitle: result.title,
              prefilledCategory: result.category,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: sevColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
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
                          color: secondaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _categoryLabel(result.category),
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: secondaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        result.device,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios_rounded,
                color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}
