import 'input_service_interface.dart';

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
