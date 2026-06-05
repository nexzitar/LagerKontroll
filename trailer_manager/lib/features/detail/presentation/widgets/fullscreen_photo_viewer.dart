import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Fullscreen photo viewer with pinch-to-zoom and pan gestures
class FullscreenPhotoViewer extends StatefulWidget {
  final String photoUrl;
  final String? heroTag;

  const FullscreenPhotoViewer({
    super.key,
    required this.photoUrl,
    this.heroTag,
  });

  @override
  State<FullscreenPhotoViewer> createState() => _FullscreenPhotoViewerState();
}

class _FullscreenPhotoViewerState extends State<FullscreenPhotoViewer> {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // If zoomed in, reset to original
      _transformationController.value = Matrix4.identity();
    } else {
      // If not zoomed, zoom to 2x at the tap position
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx, -position.dy)
        ..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = CachedNetworkImage(
      imageUrl: widget.photoUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Failed to load image'),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
            tooltip: 'Reset zoom',
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: widget.heroTag != null
                ? Hero(
                    tag: widget.heroTag!,
                    child: imageWidget,
                  )
                : imageWidget,
          ),
        ),
      ),
    );
  }
}
