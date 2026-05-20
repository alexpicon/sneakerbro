import 'package:image_picker/image_picker.dart';

/// Where a sneaker photo should be picked from.
enum PhotoSource { camera, library }

/// Web photo picking. Web has no persistent file system, so the picked
/// object URL is returned as-is; [SneakerImage] renders it as a network
/// image for the session.
class PhotoService {
  PhotoService._();

  static final ImagePicker _picker = ImagePicker();

  /// Picks a photo from [source] and returns its object URL, or null if the
  /// user cancels the picker.
  static Future<String?> pick(PhotoSource source) async {
    final picked = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 88,
    );
    return picked?.path;
  }
}
