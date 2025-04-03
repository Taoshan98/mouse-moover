import 'mouse_service_interface.dart';

/// Stub implementation for unsupported platforms
class StubMouseService implements MouseServiceInterface {
  @override
  bool initialize() {
    print('Mouse service not supported on this platform');
    return false;
  }

  @override
  void moveMouse(int x, int y) {
    print('Mouse movement not supported on this platform');
  }
}
