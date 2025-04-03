/// Data class for mouse events
class MouseEventData {
  final int x;
  final int y;
  final bool isMove;
  final bool isLeftButton;
  final bool isRightButton;
  final bool isMiddleButton;

  MouseEventData({
    required this.x,
    required this.y,
    this.isMove = false,
    this.isLeftButton = false,
    this.isRightButton = false,
    this.isMiddleButton = false,
  });
}

/// Data class for keyboard events
class KeyboardEventData {
  final int keyCode;
  final bool isDown;
  final bool isUp;
  final bool isCtrl;
  final bool isShift;
  final bool isAlt;

  KeyboardEventData({
    required this.keyCode,
    this.isDown = false,
    this.isUp = false,
    this.isCtrl = false,
    this.isShift = false,
    this.isAlt = false,
  });
}

/// Interface for platform-specific input service implementations
abstract class InputServiceInterface {
  /// Initializes the input service
  bool initialize();

  /// Adds a mouse listener
  int? addMouseListener(Function(MouseEventData) callback);

  /// Removes a mouse listener
  bool removeMouseListener(int id);

  /// Adds a keyboard listener
  int? addKeyboardListener(Function(KeyboardEventData) callback);

  /// Removes a keyboard listener
  bool removeKeyboardListener(int id);
}

/// Stub implementation for unsupported platforms
class StubInputService implements InputServiceInterface {
  @override
  bool initialize() {
    print('Input service not supported on this platform');
    return false;
  }

  @override
  int? addMouseListener(Function(MouseEventData) callback) {
    print('Mouse listening not supported on this platform');
    return null;
  }

  @override
  bool removeMouseListener(int id) {
    print('Mouse listening not supported on this platform');
    return false;
  }

  @override
  int? addKeyboardListener(Function(KeyboardEventData) callback) {
    print('Keyboard listening not supported on this platform');
    return null;
  }

  @override
  bool removeKeyboardListener(int id) {
    print('Keyboard listening not supported on this platform');
    return false;
  }
}
