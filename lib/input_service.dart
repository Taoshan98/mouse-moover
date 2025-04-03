import 'dart:io';
import 'package:flutter/foundation.dart';
import 'input_service_interface.dart';
import 'input_service_windows.dart' if (dart.library.html) 'input_service_stub.dart';
import 'input_service_linux.dart' if (dart.library.html) 'input_service_stub.dart';
import 'input_service_macos.dart' if (dart.library.html) 'input_service_stub.dart';

/// A service that provides input event listening functionality
class InputService {
  static InputServiceInterface? _instance;

  /// Gets the platform-specific implementation
  static InputServiceInterface get instance {
    if (_instance == null) {
      if (Platform.isWindows) {
        _instance = WindowsInputService();
      } else if (Platform.isLinux) {
        _instance = LinuxInputService();
      } else if (Platform.isMacOS) {
        _instance = MacOSInputService();
      } else {
        _instance = StubInputService();
      }
    }
    return _instance!;
  }

  /// Initializes the input service
  static bool initialize() {
    try {
      return instance.initialize();
    } catch (e) {
      debugPrint('Failed to initialize input service: $e');
      return false;
    }
  }

  /// Adds a mouse listener
  static int? addMouseListener(Function(MouseEventData) callback) {
    try {
      return instance.addMouseListener(callback);
    } catch (e) {
      debugPrint('Failed to add mouse listener: $e');
      return null;
    }
  }

  /// Removes a mouse listener
  static bool removeMouseListener(int id) {
    try {
      return instance.removeMouseListener(id);
    } catch (e) {
      debugPrint('Failed to remove mouse listener: $e');
      return false;
    }
  }

  /// Adds a keyboard listener
  static int? addKeyboardListener(Function(KeyboardEventData) callback) {
    try {
      return instance.addKeyboardListener(callback);
    } catch (e) {
      debugPrint('Failed to add keyboard listener: $e');
      return null;
    }
  }

  /// Removes a keyboard listener
  static bool removeKeyboardListener(int id) {
    try {
      return instance.removeKeyboardListener(id);
    } catch (e) {
      debugPrint('Failed to remove keyboard listener: $e');
      return false;
    }
  }
}
