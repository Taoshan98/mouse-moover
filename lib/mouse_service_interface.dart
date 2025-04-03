/// Interface for platform-specific mouse service implementations
abstract class MouseServiceInterface {
  /// Initializes the mouse service
  bool initialize();

  /// Moves the mouse to the specified position
  void moveMouse(int x, int y);
}

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
