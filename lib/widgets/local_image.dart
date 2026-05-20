/// Renders an image stored as a local file on the device.
///
/// Local files only exist on the mobile and desktop platforms. The
/// conditional import below resolves to the stub on web (no file system),
/// so callers there simply fall back to the drawn artwork.
library;

export 'local_image_stub.dart'
    if (dart.library.io) 'local_image_io.dart';
