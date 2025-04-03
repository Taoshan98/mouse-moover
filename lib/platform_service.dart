import 'dart:io';
import 'package:flutter/foundation.dart';

/// A service that provides platform-specific functionality
class PlatformService {
  /// Returns true if the current platform is supported
  static bool get isPlatformSupported {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// Returns the name of the current platform
  static String get platformName {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    return 'Unknown';
  }

  /// Initializes the platform service
  static bool initialize() {
    try {
      // Platform-specific initialization can be added here
      return true;
    } catch (e) {
      debugPrint('Failed to initialize platform service: $e');
      return false;
    }
  }
}
