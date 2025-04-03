import 'dart:io';
import 'package:flutter/foundation.dart';
import 'mouse_service_interface.dart';
import 'mouse_service_windows.dart' if (dart.library.html) 'mouse_service_stub.dart';
import 'mouse_service_linux.dart' if (dart.library.html) 'mouse_service_stub.dart';
import 'mouse_service_macos.dart' if (dart.library.html) 'mouse_service_stub.dart';

/// A service that provides mouse movement functionality
class MouseService {
  static MouseServiceInterface? _instance;

  /// Gets the platform-specific implementation
  static MouseServiceInterface get instance {
    if (_instance == null) {
      if (Platform.isWindows) {
        _instance = WindowsMouseService();
      } else if (Platform.isLinux) {
        _instance = LinuxMouseService();
      } else if (Platform.isMacOS) {
        _instance = MacOSMouseService();
      } else {
        _instance = StubMouseService();
      }
    }
    return _instance!;
  }

  /// Moves the mouse to the specified position
  static void moveMouse(int x, int y) {
    try {
      instance.moveMouse(x, y);
    } catch (e) {
      debugPrint('Failed to move mouse: $e');
    }
  }

  /// Initializes the mouse service
  static bool initialize() {
    try {
      return instance.initialize();
    } catch (e) {
      debugPrint('Failed to initialize mouse service: $e');
      return false;
    }
  }
}
