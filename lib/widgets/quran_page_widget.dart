import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';

class QuranPageWidget extends StatefulWidget {
  final int pageNumber;
  final QuranReadingFilter filter;
  final QuranPageFit fit;
  final VoidCallback? onTap;

  const QuranPageWidget({
    super.key,
    required this.pageNumber,
    required this.filter,
    this.fit = QuranPageFit.stretchWidth,
    this.onTap,
  });

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  late TapDownDetails _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
      setState(() => _isZoomed = false);
    } else {
      final position = _doubleTapDetails.localPosition;
      final zoomedMatrix = Matrix4.diagonal3Values(2.2, 2.2, 1.0)
        ..setTranslationRaw(-position.dx * 1.2, -position.dy * 1.2, 0.0);
      _transformationController.value = zoomedMatrix;
      setState(() => _isZoomed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = QuranService.getPageAssetPath(widget.pageNumber);

    // Filter styling
    Color frameBgColor;
    ColorFilter? imageColorFilter;

    switch (widget.filter) {
      case QuranReadingFilter.original:
        frameBgColor = const Color(0xFFFBF8F1);
        imageColorFilter = null;
        break;
      case QuranReadingFilter.sepia:
        frameBgColor = const Color(0xFFF4E8D1);
        imageColorFilter = const ColorFilter.mode(
          Color(0x2CE2C896),
          BlendMode.multiply,
        );
        break;
      case QuranReadingFilter.dark:
        frameBgColor = const Color(0xFF121415);
        imageColorFilter = const ColorFilter.matrix(<double>[
          -1.0, 0.0, 0.0, 0.0, 255.0, // Red
          0.0, -1.0, 0.0, 0.0, 255.0, // Green
          0.0, 0.0, -1.0, 0.0, 255.0, // Blue
          0.0, 0.0, 0.0, 1.0, 0.0,    // Alpha
        ]);
        break;
      case QuranReadingFilter.mint:
        frameBgColor = const Color(0xFFEFF7F2);
        imageColorFilter = const ColorFilter.mode(
          Color(0x24D2E8DB),
          BlendMode.multiply,
        );
        break;
    }

    final fitType = widget.fit == QuranPageFit.stretchWidth ? BoxFit.fill : BoxFit.contain;

    Widget imageWidget = Image.asset(
      assetPath,
      fit: fitType,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'تعذر تحميل صفحة ${widget.pageNumber}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );

    if (imageColorFilter != null) {
      imageWidget = ColorFiltered(
        colorFilter: imageColorFilter,
        child: imageWidget,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: Container(
        color: frameBgColor,
        width: double.infinity,
        height: double.infinity,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 3.5,
          clipBehavior: Clip.hardEdge,
          onInteractionEnd: (_) {
            final scale = _transformationController.value.getMaxScaleOnAxis();
            if (scale <= 1.05 && _isZoomed) {
              setState(() => _isZoomed = false);
            } else if (scale > 1.05 && !_isZoomed) {
              setState(() => _isZoomed = true);
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: widget.filter == QuranReadingFilter.dark ? const Color(0xFF101213) : Colors.white,
            ),
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}

