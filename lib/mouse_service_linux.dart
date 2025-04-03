import 'dart:io';
import 'mouse_service_interface.dart';

/// Linux implementation of the mouse service
class LinuxMouseService implements MouseServiceInterface {
  bool _isXdotoolAvailable = false;

  @override
  bool initialize() {
    try {
      // Check if xdotool is available
      Process.runSync('which', ['xdotool']);
      _isXdotoolAvailable = true;
      return true;
    } catch (e) {
      print('xdotool is not available on this system. Please install it using:');
      print('sudo apt-get install xdotool');
      _isXdotoolAvailable = false;
      return false;
    }
  }

  @override
  void moveMouse(int x, int y) {
    if (!_isXdotoolAvailable) {
      print('Cannot move mouse: xdotool is not available');
      return;
    }

    try {
      // Use xdotool to move the mouse
      Process.runSync('xdotool', ['mousemove', '$x', '$y']);
    } catch (e) {
      print('Failed to move mouse on Linux: $e');
    }
  }
}
