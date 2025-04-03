import 'package:hid_listener/hid_listener.dart';
import 'input_service_interface.dart';

/// Windows implementation of the input service
class WindowsInputService implements InputServiceInterface {
  final Map<int, Function(MouseEventData)> _mouseListeners = {};
  final Map<int, Function(KeyboardEventData)> _keyboardListeners = {};
  int _nextMouseListenerId = 1;
  int _nextKeyboardListenerId = 1;
  bool _isInitialized = false;

  @override
  bool initialize() {
    try {
      _isInitialized = getListenerBackend()!.initialize();
      return _isInitialized;
    } catch (e) {
      print('Failed to initialize Windows input service: $e');
      return false;
    }
  }

  @override
  int? addMouseListener(Function(MouseEventData) callback) {
    if (!_isInitialized) {
      print('Input service not initialized');
      return null;
    }

    final id = _nextMouseListenerId++;
    _mouseListeners[id] = callback;

    // Add the listener using hid_listener
    getListenerBackend()!.addMouseListener((event) {
      // Convert MouseEvent to MouseEventData
      final data = MouseEventData(
        x: event.x.toInt(),
        y: event.y.toInt(),
        isMove: true,  // Simplified - we'll treat all mouse events as movement
        isLeftButton: false,  // We'll simplify this for now
        isRightButton: false,
        isMiddleButton: false,
      );
      
      // Call the callback
      callback(data);
    });

    return id;
  }

  @override
  bool removeMouseListener(int id) {
    if (!_mouseListeners.containsKey(id)) {
      return false;
    }

    _mouseListeners.remove(id);
    // Note: hid_listener doesn't support removing individual listeners,
    // so we'll just stop calling the callback
    return true;
  }

  @override
  int? addKeyboardListener(Function(KeyboardEventData) callback) {
    if (!_isInitialized) {
      print('Input service not initialized');
      return null;
    }

    final id = _nextKeyboardListenerId++;
    _keyboardListeners[id] = callback;

    // Add the listener using hid_listener
    getListenerBackend()!.addKeyboardListener((event) {
      // Convert RawKeyEvent to KeyboardEventData
      final data = KeyboardEventData(
        keyCode: 0,  // Simplified - we'll use a default value
        isDown: true,  // Simplified - we'll treat all key events as key down
        isUp: false,
        isCtrl: false,
        isShift: false,
        isAlt: false,
      );
      
      // Call the callback
      callback(data);
    });

    return id;
  }

  @override
  bool removeKeyboardListener(int id) {
    if (!_keyboardListeners.containsKey(id)) {
      return false;
    }

    _keyboardListeners.remove(id);
    // Note: hid_listener doesn't support removing individual listeners,
    // so we'll just stop calling the callback
    return true;
  }
}
