// lib/screens/lighting/lighting_visualization_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:GeniusHouse/models/lighting_design_models.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/lighting_api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/constants.dart';

class LightingVisualizationScreen extends StatefulWidget {
  final ApiService apiService;
  final LightingRoomInput room;
  final List<LightingSelectedItem> confirmedItems;
  final LightingDistributionPlan distribution;
  final String? localImagePath;

  final String? sessionId;
  final int? projectId;
  final int? roomIdDb;
  final int? attemptId;
  final bool isLoggedIn;

  const LightingVisualizationScreen({
    Key? key,
    required this.apiService,
    required this.room,
    required this.confirmedItems,
    required this.distribution,
    this.localImagePath,
    this.sessionId,
    this.projectId,
    this.roomIdDb,
    this.attemptId,
    this.isLoggedIn = false,
  }) : super(key: key);

  @override
  State<LightingVisualizationScreen> createState() =>
      _LightingVisualizationScreenState();
}

class _LightingVisualizationScreenState
    extends State<LightingVisualizationScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _payload;

  bool _isGenerating = false;
  String? _generatedImageUrl;
  String? _generatedImageRef;
  String? _genError;
  int _remainingAttempts = 2;
  int _genCount = 0;
  List<String> _missingImages = [];

  bool _isSaving = false;

  bool get _canGenerate {
    if (widget.sessionId == null || widget.sessionId!.isEmpty) return false;
    if (widget.roomIdDb == null || widget.roomIdDb == 0) return false;
    if (widget.attemptId == null || widget.attemptId == 0) return false;
    if (widget.projectId == null || widget.projectId == 0) return false;
    if (_remainingAttempts <= 0) return false;
    if (widget.localImagePath == null) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _buildPayload();
  }

  Future<void> _buildPayload() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await widget.apiService.lightingVisualizationPayload(
      room: widget.room.toJson(),
      confirmedItems: widget.confirmedItems.map((e) => e.toJson()).toList(),
      distribution: widget.distribution.toJson(),
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _payload = Map<String, dynamic>.from(res['data']);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'فشل تجهيز المعاينة';
        _loading = false;
      });
    }
  }

  Future<void> _generateImage() async {
    if (!_canGenerate || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _genError = null;
    });

    try {
      final res = await widget.apiService.lightingGenerateRoomImage(
        sessionId: widget.sessionId!,
        projectId: widget.projectId,
        roomIdDb: widget.roomIdDb!,
        attemptId: widget.attemptId!,
        confirmedItems: widget.confirmedItems.map((e) => e.toJson()).toList(),
        distribution: widget.distribution.toJson(),
        aspectRatio: '4:3',
        requiresAuth: widget.isLoggedIn,
      );

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        final data = Map<String, dynamic>.from(res['data']);
        setState(() {
          _isGenerating = false;
          _generatedImageRef = data['design_image_ref']?.toString();
          _generatedImageUrl = data['design_image_url']?.toString() ??
              _buildAbsoluteUrl(_generatedImageRef);
          _remainingAttempts =
              int.tryParse((data['remaining_attempts'] ?? 0).toString()) ?? 0;
          _genCount = int.tryParse((data['gen_count'] ?? 1).toString()) ?? 1;
          _missingImages = (data['missing_images'] as List? ?? [])
              .map((e) => e.toString())
              .toList();
        });
      } else {
        setState(() {
          _isGenerating = false;
          _genError = res['message']?.toString() ?? 'فشل توليد الصورة';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _genError = 'حدث خطأ في الاتصال: $e';
      });
    }
  }

  String? _buildAbsoluteUrl(String? ref) {
    if (ref == null || ref.isEmpty) return null;
    if (ref.startsWith('http')) return ref;
    return '${_baseUrl()}/$ref';
  }

  Future<void> _saveImageToGallery(String imageUrl) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('فشل تحميل الصورة (${response.statusCode})');
      }

      final Uint8List bytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'nex_lighting_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'image/jpeg')],
        text: 'تصميم إضاءة من Nex',
        subject: 'معاينة إضاءة',
      );

      if (!mounted) return;
      _showSnackBar('اختر "حفظ الصورة" من قائمة المشاركة', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('فشل حفظ الصورة: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openFullscreenImage(String imageUrl, {String? title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenImageViewer(
          imageUrl: imageUrl,
          title: title,
          onSave: () => _saveImageToGallery(imageUrl),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(fontSize: 13)),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {},
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: Column(
            children: [
              _buildAppBarWithCurve(),
              Expanded(child: _buildBody()),
            ],
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
                    onPressed: () {
                      Navigator.pop(context, {
                        'remaining_attempts': _remainingAttempts,
                        'gen_count': _genCount,
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Center(
                    child: Text(
                      'المعاينة البصرية',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (_generatedImageUrl != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_alt_rounded,
                              color: Colors.white, size: 24),
                      onPressed: _isSaving
                          ? null
                          : () => _saveImageToGallery(_generatedImageUrl!),
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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 15, color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _buildPayload,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final payload = _payload!;
    final photoRef = payload['photo_ref']?.toString() ?? '';
    final refs = (payload['product_references'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _generatedImageUrl != null
            ? _buildGeneratedImageCard(_generatedImageUrl!)
            : _buildImageCard(photoRef),
        const SizedBox(height: 16),
        _buildGenerateCard(),
        if (_missingImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMissingImagesWarning(),
        ],
        const SizedBox(height: 16),
        _buildProductsCard(refs),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildImageCard(String photoRef) {
    final hasLocal = widget.localImagePath != null &&
        File(widget.localImagePath!).existsSync();

    final imageUrl =
        photoRef.startsWith('http') ? photoRef : '${_baseUrl()}/$photoRef';

    return GestureDetector(
      onTap: () => hasLocal
          ? _openLocalFullscreen(File(widget.localImagePath!))
          : _openFullscreenImage(imageUrl, title: 'صورة الغرفة'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  const Icon(Icons.image_rounded,
                      size: 18, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 6),
                  Text(
                    'صورة الغرفة الأصلية',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.open_in_full_rounded,
                      size: 16, color: Colors.grey.shade500),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: hasLocal
                    ? Image.file(File(widget.localImagePath!),
                        fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.grey.shade300),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported_rounded,
                              size: 48, color: Colors.grey),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLocalFullscreen(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LocalFullscreenImageViewer(
          file: file,
          title: 'صورة الغرفة',
        ),
      ),
    );
  }

  Widget _buildGeneratedImageCard(String imageUrl) {
    return GestureDetector(
      onTap: () => _openFullscreenImage(imageUrl, title: 'معاينة إضاءة'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'صورة الغرفة المولّدة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'محاولة $_genCount',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.grey.shade300),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_full_rounded,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'انقر للتوسيع',
                              style: GoogleFonts.cairo(
                                fontSize: 10.5,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateCard() {
    if (!_canGenerate && _generatedImageUrl == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.orange.shade800, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _remainingAttempts <= 0
                    ? 'تم استنفاد الحد الأقصى لتوليد الصور (محاولتان)'
                    : 'لا يمكن توليد الصورة — تأكد من رفع صورة الغرفة واعتماد الخطة',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  color: Colors.orange.shade900,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isGenerating) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'جاري توليد الصورة...',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'قد يستغرق التوليد من 20 إلى 60 ثانية',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_genError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _genError!,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _generateImage,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('إعادة المحاولة',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.08),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _generatedImageUrl != null
                          ? 'معاينة جاهزة ✨'
                          : 'جاهز لتوليد الصورة',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'المحاولات المتبقية: $_remainingAttempts من 2',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateImage,
              icon: const Icon(Icons.auto_awesome_rounded, size: 20),
              label: Text(
                _generatedImageUrl != null
                    ? 'توليد نسخة أخرى'
                    : 'توليد صورة الغرفة',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          if (_remainingAttempts > 0) ...[
            const SizedBox(height: 6),
            Text(
              'المحاولة القادمة ستستهلك واحدة من المحاولات المتبقية',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissingImagesWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                'منتجات بدون صورة تصميم:',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._missingImages.map((name) => Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 2),
                child: Text(
                  '• $name',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: Colors.amber.shade900,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProductsCard(List<Map<String, dynamic>> refs) {
    if (refs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: Color(0xFF1E3A8A), size: 20),
              const SizedBox(width: 8),
              Text(
                'المنتجات المعتمدة (${refs.length})',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...refs.map(_buildProductRefRow),
        ],
      ),
    );
  }

  Widget _buildProductRefRow(Map<String, dynamic> ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                size: 18, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ref['title_ar']?.toString() ?? '',
              style:
                  GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '× ${ref['quantity'] ?? 1}',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  String _baseUrl() {
    return AppConstants.baseUrl;
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final Future<void> Function()? onSave;

  const _FullscreenImageViewer({
    required this.imageUrl,
    this.title,
    this.onSave,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  bool _localSaving = false;

  Future<void> _handleSave() async {
    if (_localSaving) return;
    setState(() => _localSaving = true);
    try {
      await widget.onSave?.call();
    } finally {
      if (mounted) setState(() => _localSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title ?? 'معاينة',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (widget.onSave != null)
              IconButton(
                icon: _localSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_alt_rounded),
                tooltip: 'حفظ / مشاركة الصورة',
                onPressed: _localSaving ? null : _handleSave,
              ),
          ],
        ),
        body: PhotoView(
          imageProvider: CachedNetworkImageProvider(widget.imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.image_not_supported_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalFullscreenImageViewer extends StatelessWidget {
  final File file;
  final String? title;

  const _LocalFullscreenImageViewer({
    required this.file,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            title ?? 'معاينة',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: PhotoView(
          imageProvider: FileImage(file),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
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
