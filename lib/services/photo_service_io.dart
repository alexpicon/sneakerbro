import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Where a sneaker photo should be picked from.
enum PhotoSource { camera, library }

/// Mobile/desktop photo picking. The picked file is copied into a stable
/// app folder, and that local path is what gets stored on the sneaker.
class PhotoService {
  PhotoService._();

  static final ImagePicker _picker = ImagePicker();

  /// Picks a photo from [source], persists it, and returns its local file
  /// path. Returns null if the user cancels the picker.
  static Future<String?> pick(PhotoSource source) async {
    final picked = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 88,
    );
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final photos = Directory('${dir.path}/sneaker_photos');
    if (!photos.existsSync()) {
      photos.createSync(recursive: true);
    }
    final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    final dest =
        '${photos.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(picked.path).copy(dest);
    return dest;
  }
}
