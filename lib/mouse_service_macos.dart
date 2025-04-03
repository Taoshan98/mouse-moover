import 'dart:io';
import 'mouse_service_interface.dart';

/// macOS implementation of the mouse service
class MacOSMouseService implements MouseServiceInterface {
  bool _isCliclickAvailable = false;

  @override
  bool initialize() {
    try {
      // Check if cliclick is available
      Process.runSync('which', ['cliclick']);
      _isCliclickAvailable = true;
      return true;
    } catch (e) {
      print('cliclick is not available on this system. Please install it using:');
      print('brew install cliclick');
      _isCliclickAvailable = false;
      return false;
    }
  }

  @override
  void moveMouse(int x, int y) {
    if (!_isCliclickAvailable) {
      print('Cannot move mouse: cliclick is not available');
      return;
    }

    try {
      // Use cliclick to move the mouse
      Process.runSync('cliclick', ['m:$x,$y']);
    } catch (e) {
      print('Failed to move mouse on macOS: $e');
    }
  }
}
