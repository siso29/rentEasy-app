import 'dart:io';
import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Thrown when a photo cannot be selected from the camera or gallery.
class PhotoPickerException implements Exception {
  const PhotoPickerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Handles picking and storing property photos on the device.
///
/// Picked files are copied from the temporary cache into the application
/// documents directory so they survive app restarts.
class PropertyImageService {
  PropertyImageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const maxPhotos = 8;
  static const _folderName = 'property_images';

  final ImagePicker _picker;

  Future<List<String>> pickFromGallery({required int remainingSlots}) async {
    if (remainingSlots <= 0) {
      return const [];
    }

    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );

      return await _persistAll(files.take(remainingSlots));
    } catch (_) {
      throw const PhotoPickerException(
        'Could not open your gallery. Please check photo permissions and try again.',
      );
    }
  }

  Future<String?> pickFromCamera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (file == null) {
        return null;
      }

      return await _persist(file);
    } catch (_) {
      throw const PhotoPickerException(
        'Could not open the camera. Please check camera permissions and try again.',
      );
    }
  }

  Future<void> deleteIfManaged(String path) async {
    try {
      final directory = await _imagesDirectory();
      final normalizedFile = p.normalize(path);
      final normalizedDirectory = p.normalize(directory.path);

      if (!normalizedFile.startsWith(normalizedDirectory)) {
        return;
      }

      final file = File(normalizedFile);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Cleanup is best-effort and must never break the UI flow.
    }
  }

  Future<List<String>> _persistAll(Iterable<XFile> files) async {
    final paths = <String>[];
    for (final file in files) {
      paths.add(await _persist(file));
    }
    return paths;
  }

  Future<String> _persist(XFile file) async {
    final directory = await _imagesDirectory();
    await directory.create(recursive: true);

    final extension = _safeExtension(file.name);
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}$extension';
    final destination = p.join(directory.path, fileName);

    final copied = await File(file.path).copy(destination);
    return copied.path;
  }

  Future<Directory> _imagesDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, _folderName));
  }

  String _safeExtension(String name) {
    final extension = p.extension(name).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};
    return allowed.contains(extension) ? extension : '.jpg';
  }
}
