/// Picks and stores sneaker photos.
///
/// The implementation is split by platform. On mobile and desktop the picked
/// photo is copied into the app's documents directory so it survives the OS
/// clearing temporary files. On web there is no persistent file system, so
/// the stub keeps the picked object URL for the session instead.
library;

export 'photo_service_stub.dart'
    if (dart.library.io) 'photo_service_io.dart';
