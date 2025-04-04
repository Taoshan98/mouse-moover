import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'input_service_interface.dart';
import 'package:hid_listener/hid_listener.dart';

/// Linux implementation of the input service
class LinuxInputService implements InputServiceInterface {
  final Map<int, Function(MouseEventData)> _mouseListeners = {};
  final Map<int, Function(KeyboardEventData)> _keyboardListeners = {};
  int _nextMouseListenerId = 1;
  int _nextKeyboardListenerId = 1;
  bool _isInitialized = false;
  bool _isXinputAvailable = false;
  
  // Store the last known mouse position
  int _lastX = 0;
  int _lastY = 0;
  
  // Timer for polling mouse position
  Timer? _mousePollingTimer;

  @override
  bool initialize() {
    try {
      // Check if xinput is available
      final result = Process.runSync('which', ['xinput']);
      _isXinputAvailable = result.exitCode == 0;
      
      if (!_isXinputAvailable) {
        print('xinput is not available on this system. Please install it using:');
        print('sudo apt-get install xinput');
        return false;
      }
      
      // Start polling for mouse position
      _startMousePositionPolling();
      
      _isInitialized = getListenerBackend()!.initialize();
      return _isInitialized;
    } catch (e) {
      print('Failed to initialize Linux input service: $e');
      return false;
    }
  }
  
  void _startMousePositionPolling() {
    // Poll mouse position every 100ms
    _mousePollingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateMousePosition();
    });
  }
  
  void _updateMousePosition() {
    try {
      // Use xdotool to get mouse position
      final result = Process.runSync('xdotool', ['getmouselocation']);
      if (result.exitCode == 0) {
        // Parse output like "x:100 y:200 screen:0 window:12345"
        final output = result.stdout.toString();
        final xMatch = RegExp(r'x:(\d+)').firstMatch(output);
        final yMatch = RegExp(r'y:(\d+)').firstMatch(output);
        
        if (xMatch != null && yMatch != null) {
          final x = int.parse(xMatch.group(1)!);
          final y = int.parse(yMatch.group(1)!);
          
          // Check if position changed
          if (x != _lastX || y != _lastY) {
            _lastX = x;
            _lastY = y;
            
            // Notify listeners
            final event = MouseEventData(
              x: x,
              y: y,
              isMove: true,
            );
            
            for (final callback in _mouseListeners.values) {
              callback(event);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating mouse position: $e');
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
    return id;
  }

  @override
  bool removeMouseListener(int id) {
    if (!_mouseListeners.containsKey(id)) {
      return false;
    }

    _mouseListeners.remove(id);
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
    return true;
  }
  
  // Clean up resources
  void dispose() {
    _mousePollingTimer?.cancel();
  }
}
