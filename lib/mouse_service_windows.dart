import 'package:auto_desktop/auto_desktop.dart';
import 'mouse_service_interface.dart';

/// Windows implementation of the mouse service
class WindowsMouseService implements MouseServiceInterface {
  @override
  bool initialize() {
    try {
      // The auto_desktop package should already be initialized
      return true;
    } catch (e) {
      print('Failed to initialize Windows mouse service: $e');
      return false;
    }
  }

  @override
  void moveMouse(int x, int y) {
    try {
      mouseMove(x, y);
    } catch (e) {
      print('Failed to move mouse on Windows: $e');
    }
  }
}
