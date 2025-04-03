import 'dart:io';
import 'dart:async';
import 'mouse_service_interface.dart';

/// macOS implementation of the mouse service
class MacOSMouseService implements MouseServiceInterface {
  bool _isCliclickAvailable = false;
  bool _hasTestedPermissions = false;
  bool _hasPermissions = false;
  
  // Stream controller to notify listeners about permission status changes
  final StreamController<bool> _permissionStatusController = StreamController<bool>.broadcast();
  
  /// Stream that emits permission status changes
  Stream<bool> get permissionStatusStream => _permissionStatusController.stream;

  @override
  bool initialize() {
    try {
      // Check if cliclick is available
      final result = Process.runSync('which', ['cliclick']);
      if (result.exitCode != 0) {
        print('cliclick is not available on this system. Please install it using:');
        print('brew install cliclick');
        _isCliclickAvailable = false;
        return false;
      }
      
      _isCliclickAvailable = true;
      
      // Test permissions by trying to move the mouse to the current position
      // This will trigger the permission dialog if permissions haven't been granted
      _testPermissions();
      
      return true;
    } catch (e) {
      print('Failed to initialize macOS mouse service: $e');
      _isCliclickAvailable = false;
      return false;
    }
  }
  
  /// Tests if the app has the necessary permissions to control the mouse
  void _testPermissions() {
    if (_hasTestedPermissions) return;
    
    try {
      // Try to get the current mouse position first (this will fail if no permissions)
      final posResult = Process.runSync('cliclick', ['p']);
      
      if (posResult.exitCode == 0) {
        _hasPermissions = true;
        _hasTestedPermissions = true;
        print('Successfully verified accessibility permissions');
      } else {
        _promptForPermissions();
      }
    } catch (e) {
      _promptForPermissions();
    }
  }
  
  /// Displays instructions for granting accessibility permissions
  void _promptForPermissions() {
    _hasPermissions = false;
    _hasTestedPermissions = true;
    
    print('===========================================================');
    print('ACCESSIBILITY PERMISSIONS REQUIRED');
    print('===========================================================');
    print('Mouse Moover needs accessibility permissions to control your mouse.');
    print('Please follow these steps:');
    print('1. Open System Preferences');
    print('2. Go to Security & Privacy > Privacy > Accessibility');
    print('3. Click the lock icon to make changes');
    print('4. Add or check the box for this application');
    print('5. Restart the application');
    print('===========================================================');
  }

  /// Checks if the app has accessibility permissions
  Future<bool> checkPermissions() async {
    if (!_isCliclickAvailable) {
      return false;
    }
    
    try {
      // Try to get the current mouse position as a test
      final result = await Process.run('cliclick', ['p']);
      _hasPermissions = result.exitCode == 0;
      _hasTestedPermissions = true;
      
      // Notify listeners about the permission status
      _permissionStatusController.add(_hasPermissions);
      
      return _hasPermissions;
    } catch (e) {
      _hasPermissions = false;
      _hasTestedPermissions = true;
      
      // Notify listeners about the permission status
      _permissionStatusController.add(false);
      
      return false;
    }
  }
  
  /// Opens System Preferences to help the user grant accessibility permissions
  Future<bool> openSystemPreferences() async {
    try {
      // Open System Preferences
      final result = await Process.run('open', ['/System/Applications/System Preferences.app']);
      
      if (result.exitCode == 0) {
        print('Opened System Preferences');
        return true;
      } else {
        // Try alternative path for older macOS versions
        final altResult = await Process.run('open', ['/Applications/System Preferences.app']);
        return altResult.exitCode == 0;
      }
    } catch (e) {
      print('Failed to open System Preferences: $e');
      return false;
    }
  }
  
  /// Opens Security & Privacy preferences directly (if possible)
  Future<bool> openSecurityPreferences() async {
    try {
      // This command attempts to open the Security & Privacy pane directly
      final result = await Process.run('open', ['x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility']);
      return result.exitCode == 0;
    } catch (e) {
      print('Failed to open Security preferences: $e');
      // Fall back to opening System Preferences
      return openSystemPreferences();
    }
  }
  
  @override
  void moveMouse(int x, int y) {
    if (!_isCliclickAvailable) {
      print('Cannot move mouse: cliclick is not available');
      return;
    }
    
    // If we haven't tested permissions yet, do it now
    if (!_hasTestedPermissions) {
      _testPermissions();
    }
    
    // If we still don't have permissions after testing, show a warning
    if (_hasTestedPermissions && !_hasPermissions) {
      print('Cannot move mouse: Missing accessibility permissions');
      _promptForPermissions();
      
      // Notify listeners about the permission status
      _permissionStatusController.add(false);
      
      return;
    }

    try {
      // Use cliclick to move the mouse
      final result = Process.runSync('cliclick', ['m:$x,$y']);
      
      if (result.exitCode != 0) {
        // If this fails, we might have lost permissions or encountered another issue
        print('Failed to move mouse: ${result.stderr}');
        _hasTestedPermissions = false; // Force re-test of permissions
        
        // Check if this is a permission issue
        if (result.stderr.toString().contains('Operation not permitted')) {
          _hasPermissions = false;
          _permissionStatusController.add(false);
        }
      }
    } catch (e) {
      print('Failed to move mouse on macOS: $e');
      if (e.toString().contains('Operation not permitted')) {
        _hasPermissions = false;
        _promptForPermissions();
        
        // Notify listeners about the permission status
        _permissionStatusController.add(false);
      }
    }
  }
  
  /// Dispose resources
  void dispose() {
    _permissionStatusController.close();
  }
}
