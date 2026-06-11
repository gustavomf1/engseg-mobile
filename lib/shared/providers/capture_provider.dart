import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const _maxPhotos = 10;

class CaptureNotifier extends Notifier<List<XFile>> {
  final _picker = ImagePicker();

  @override
  List<XFile> build() => [];

  Future<void> takePhoto() async {
    if (state.length >= _maxPhotos) return;
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null) state = [...state, photo];
  }

  Future<void> pickFromGallery() async {
    final remaining = _maxPhotos - state.length;
    if (remaining <= 0) return;
    final photos = await _picker.pickMultiImage(
      imageQuality: 85,
      limit: remaining,
    );
    if (photos.isNotEmpty) state = [...state, ...photos];
  }

  void remove(int index) {
    final list = [...state];
    list.removeAt(index);
    state = list;
  }

  void clear() => state = [];
}

final captureProvider = NotifierProvider<CaptureNotifier, List<XFile>>(
  CaptureNotifier.new,
);
