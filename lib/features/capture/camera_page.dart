import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/capture_provider.dart';
import '../../shared/widgets/prototype_ui.dart';

class CameraPage extends ConsumerStatefulWidget {
  final String tipo;

  const CameraPage({super.key, required this.tipo});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  bool _proceeding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(captureProvider.notifier).clear();
    });
  }

  void _close() {
    ref.read(captureProvider.notifier).clear();
    context.go('/feed');
  }

  Future<void> _proceed() async {
    if (_proceeding) return;
    setState(() => _proceeding = true);

    final photos = ref.read(captureProvider);
    final fotoPath = photos.isNotEmpty ? photos.first.path : null;

    Position? position;
    String? cidade;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        cidade = placemarks.firstOrNull?.locality;
      } catch (_) {
        // GPS indisponível — continua sem coordenadas
      }
    }

    if (!mounted) return;
    context.go(
      '/wizard/${widget.tipo}',
      extra: {
        'fotoPath': fotoPath,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'capturedAt': DateTime.now().millisecondsSinceEpoch,
        'cidade': cidade,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(captureProvider);
    final notifier = ref.read(captureProvider.notifier);
    final tipo = widget.tipo.toUpperCase();

    return Scaffold(
      backgroundColor: ProtoColors.bg,
      appBar: AppBar(
        backgroundColor: ProtoColors.bg,
        foregroundColor: ProtoColors.text,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _close,
        ),
        title: Text('Registrar $tipo'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: photos.isEmpty
                  ? _emptyState()
                  : _photoGrid(photos, notifier),
            ),
            _bottomBar(notifier, photos.length),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ProtoColors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ProtoColors.border),
            ),
            child: const Icon(Icons.add_photo_alternate_outlined,
                size: 36, color: ProtoColors.muted),
          ),
          const SizedBox(height: 16),
          const Text('Nenhuma foto anexada',
              style: TextStyle(
                  color: ProtoColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Opcional — você pode continuar sem fotos',
              style: TextStyle(color: ProtoColors.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _photoGrid(List photos, CaptureNotifier notifier) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(photos[i].path),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => notifier.remove(i),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bottomBar(CaptureNotifier notifier, int count) {
    final canAdd = count < 10;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: const BoxDecoration(
        color: ProtoColors.surface,
        border: Border(top: BorderSide(color: ProtoColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ProtoColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: canAdd ? notifier.takePhoto : null,
                  icon: const Icon(Icons.camera_alt_outlined,
                      color: ProtoColors.text, size: 18),
                  label: const Text('Câmera',
                      style: TextStyle(color: ProtoColors.text)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ProtoColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: canAdd ? notifier.pickFromGallery : null,
                  icon: const Icon(Icons.photo_library_outlined,
                      color: ProtoColors.text, size: 18),
                  label: const Text('Galeria',
                      style: TextStyle(color: ProtoColors.text)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ProtoColors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _proceeding ? null : _proceed,
              child: _proceeding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      count > 0 ? 'Continuar com $count foto(s)' : 'Continuar sem foto',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900),
                    ),
            ),
          ),
          if (count == 10)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Limite de 10 fotos atingido',
                  style: TextStyle(color: ProtoColors.muted, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
