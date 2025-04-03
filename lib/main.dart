import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'platform_service.dart';
import 'mouse_service.dart';
import 'input_service.dart';
import 'input_service_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 850),
    minimumSize: Size(500, 850),
    maximumSize: Size(500, 850),
    center: true,
    backgroundColor: Colors.transparent,
    alwaysOnTop: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  // Prevent the window from closing when the user clicks the close button
  await windowManager.setPreventClose(true);
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  // Initialize platform services
  if (!PlatformService.initialize()) {
    print("Failed to initialize platform service");
  }
  
  // Initialize input service
  if (!InputService.initialize()) {
    print("Failed to initialize input service");
  }
  
  // Initialize mouse service
  if (!MouseService.initialize()) {
    print("Failed to initialize mouse service");
  }
  
  runApp(const MouseMoover());
}

class MouseMoover extends StatefulWidget {
  const MouseMoover({super.key});

  @override
  State createState() => _MouseMooverState();
}

class _MouseMooverState extends State<MouseMoover> with WindowListener, TrayListener {
  Timer? _timer;
  Timer? _inactivityTimer;
  Timer? _updateTimer;
  final Random _random = Random();
  bool _isRunning = false;
  int _remainingSeconds = 15;
  DateTime? _inactivityStartTime;
  Duration _inactivityDuration = const Duration(seconds: 15);
  int mouseListenerID = 0;
  int keyboardListenerID = 0;
  
  // UI state
  bool _showSettings = false;

  final TextEditingController _inputController = TextEditingController();

  // Theme colors
  final Color _primaryColor = const Color(0xFF6200EE);
  final Color _accentColor = const Color(0xFF03DAC6);
  final Color _backgroundColor = const Color(0xFF121212);
  final Color _surfaceColor = const Color(0xFF1E1E1E);
  final Color _errorColor = const Color(0xFFCF6679);

  @override
  void initState() {
    super.initState();
    
    // Set up window manager
    windowManager.addListener(this);
    
    // Set up tray manager
    trayManager.addListener(this);
    _initTray();
    
    // Add mouse listener
    mouseListenerID = InputService.addMouseListener(_handleMouseEvent) ?? 0;
    
    // Add keyboard listener
    keyboardListenerID = InputService.addKeyboardListener(_handleKeyboardEvent) ?? 0;
    
    _startUpdateTimer();
  }
  
  Future<void> _initTray() async {
    try {
      // Set up tray icon
      if (Platform.isWindows) {
        // Use a system icon for Windows
        await trayManager.setIcon('./assets/tray_icon.ico');
      } else if (Platform.isMacOS) {
        // Use a system icon for macOS
        await trayManager.setIcon('./assets/tray_icon.ico');
      } else {
        // Use a system icon for Linux
        await trayManager.setIcon('./assets/tray_icon.ico');
      }
      
      // Set up tray tooltip
      await trayManager.setToolTip('Mouse Moover');
      
      // Set up tray menu
      await _updateTrayMenu();
    } catch (e) {
      print("Failed to initialize tray: $e");
    }
  }
  
  Future<void> _updateTrayMenu() async {
    // Create tray menu items
    List<MenuItem> items = [
      MenuItem(
        label: 'Mostra Finestra',
        onClick: (_) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuItem.separator(),
      MenuItem(
        label: _isRunning ? 'Ferma Movimento Mouse' : 'Avvia Movimento Mouse',
        onClick: (_) {
          _toggleMouseMovement();
        },
      ),
      MenuItem.separator(),
      MenuItem(
        label: 'Esci',
        onClick: (_) {
          _exitApp();
        },
      ),
    ];
    
    // Set tray menu
    await trayManager.setContextMenu(Menu(items: items));
  }
  
  void _exitApp() async {
    await windowManager.destroy();
    exit(0);
  }
  
  // Handle window close event
  @override
  void onWindowClose() async {
    // Hide the window instead of closing the app
    await windowManager.hide();
    // Remove from taskbar but keep in system tray
    await windowManager.setSkipTaskbar(true);
    // Prevent the window from closing
    await windowManager.setPreventClose(true);
    
    setState(() {});
  }
  
  // Handle window show event
  @override
  void onWindowFocus() async {
    // Show in taskbar when window is shown
    await windowManager.setSkipTaskbar(false);
  }
  
  // Handle tray click event
  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }
  
  // Handle tray right-click event
  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inactivityTimer?.cancel();
    _updateTimer?.cancel();
    
    // Remove listeners
    if (mouseListenerID > 0) {
      InputService.removeMouseListener(mouseListenerID);
    }
    
    if (keyboardListenerID > 0) {
      InputService.removeKeyboardListener(keyboardListenerID);
    }
    
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    
    _inputController.dispose();
    super.dispose();
  }

  void _handleMouseEvent(MouseEventData event) {
    if (_isRunning) {
      // Only stop if automatic movement is running
      _stopAndReset();
    }
    _resetInactivityTimer(); // Always reset the inactivity timer
  }

  void _handleKeyboardEvent(KeyboardEventData event) {
    if (_isRunning) {
      // Only stop if automatic movement is running
      _stopAndReset();
    }
    _resetInactivityTimer(); // Always reset the inactivity timer
  }

  void _startMouseMovement() {
    if (_isRunning) {
      _moveMouseToRandomPosition();
    }
  }

  void _moveMouseToRandomPosition() {
    try {
      final size = MediaQuery.of(context).size;
      final randomX = _random.nextInt(size.width.toInt());
      final randomY = _random.nextInt(size.height.toInt());
      
      // Use our platform-specific mouse service
      MouseService.moveMouse(randomX, randomY);
      
      // Set up a timer to move the mouse again after a short delay
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 2), _startMouseMovement);
    } catch (e) {
      print("Errore nel movimento del mouse: $e");
    }
  }

  void _toggleMouseMovement() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _startMouseMovement();
      } else {
        _timer?.cancel();
      }
    });
    
    // Update the tray menu to reflect the new state
    _updateTrayMenu();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityStartTime = DateTime.now();
    _inactivityTimer = Timer(_inactivityDuration, () {
      setState(() {
        _isRunning = true;
        _startMouseMovement();
      });
    });
  }

  void _resetInactivityTimer() {
    if (!_isRunning) {
      // Don't reset if automatic movement is active
      _inactivityTimer?.cancel();
      _startInactivityTimer();
    }
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_inactivityStartTime != null &&
          _inactivityTimer != null &&
          _inactivityTimer!.isActive) {
        final remaining = _inactivityDuration -
            DateTime.now().difference(_inactivityStartTime!);
        setState(() {
          _remainingSeconds = remaining.inSeconds;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
          }
        });
      }
    });
  }

  void _stopAndReset() {
    setState(() {
      _isRunning = false;
      _timer?.cancel();
      _remainingSeconds = _inactivityDuration.inSeconds;
      _inactivityStartTime = null; // Reset the inactivity start time
      _inactivityTimer?.cancel();
      _startInactivityTimer(); // Restart the inactivity timer
    });
    
    // Update the tray menu to reflect the new state
    _updateTrayMenu();
  }

  void _updateTimerSettings() {
    int newValue;
    try {
      newValue = int.parse(_inputController.text);
      setState(() {
        _remainingSeconds = newValue;
        _inactivityDuration = Duration(seconds: newValue);
        _stopAndReset(); // Reset the timers with the new values
        _showSettings = false; // Hide settings after applying
      });
    } catch (e) {
      // Handle parsing error
      print("Input non valido: ${_inputController.text}");
    }
  }
  
  /// Builds platform-specific setup instructions
  Widget _buildPlatformInstructions() {
    String instructions = '';
    
    if (PlatformService.platformName == 'Windows') {
      instructions = 'Windows: No additional setup required.';
    } else if (PlatformService.platformName == 'Linux') {
      instructions = 'Linux: Please install xdotool using:\n'
                    'sudo apt-get install xdotool\n'
                    'This is required for mouse movement and tracking.';
    } else if (PlatformService.platformName == 'macOS') {
      instructions = 'macOS: Please install cliclick using:\n'
                    'brew install cliclick\n'
                    'This is required for mouse movement and tracking.';
    } else {
      instructions = 'Your platform is not supported.';
    }
    
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Platform Setup Instructions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms, delay: 300.ms)
    .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad);
  }

  @override
  Widget build(BuildContext context) {
    String inactivityStatusText =
        _inactivityTimer != null && _inactivityTimer!.isActive
            ? 'Attivazione automatica tra $_remainingSeconds secondi'
            : 'Attivazione automatica disattivata/scaduta';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.dark(
          primary: _primaryColor,
          secondary: _accentColor,
          surface: _surfaceColor,
          background: _backgroundColor,
          error: _errorColor,
        ),
        scaffoldBackgroundColor: _backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: _surfaceColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardTheme(
          color: _surfaceColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _accentColor, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mouse,
                color: _accentColor,
              ),
              const SizedBox(width: 8),
              const Text('Mouse Moover'),
            ],
          ),
          actions: [
            // Platform indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Chip(
                backgroundColor: _surfaceColor.withOpacity(0.5),
                label: Text(
                  'Platform: ${PlatformService.platformName}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                avatar: Icon(
                  Platform.isWindows
                      ? Icons.window
                      : Platform.isMacOS
                          ? Icons.laptop_mac
                          : Icons.laptop,
                  size: 16,
                  color: _accentColor,
                ),
              ),
            ),
            // Settings button
            IconButton(
              icon: Icon(
                Icons.settings,
                color: _accentColor,
              ),
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _backgroundColor,
                _backgroundColor.withBlue((_backgroundColor.blue + 15).clamp(0, 255)),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status Card
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Status Icon
                            Icon(
                              _isRunning ? Icons.mouse : Icons.mouse_outlined,
                              size: 64,
                              color: _isRunning ? _accentColor : Colors.white.withOpacity(0.7),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                              autoPlay: _isRunning,
                            )
                            .shimmer(
                              duration: 2.seconds,
                              color: _accentColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            
                            // Status Text
                            Text(
                              _isRunning
                                  ? 'Movimento del mouse attivo'
                                  : 'Movimento del mouse disattivato',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: _isRunning ? _accentColor : Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.2, end: 0, duration: 500.ms),
                            
                            const SizedBox(height: 8),
                            
                            // Inactivity Status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _surfaceColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 18,
                                    color: _accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    inactivityStatusText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 200.ms)
                            .slideY(begin: 0.2, end: 0, duration: 500.ms),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Control Button
                    ElevatedButton.icon(
                      onPressed: _toggleMouseMovement,
                      icon: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        size: 24,
                      ),
                      label: Text(_isRunning ? 'Ferma Movimento' : 'Avvia Movimento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning ? _errorColor : _primaryColor,
                        minimumSize: const Size(250, 50),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, duration: 500.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Settings Panel (conditionally shown)
                    if (_showSettings)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: _accentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Impostazioni',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Timer Settings
                              Text(
                                'Tempo di inattività (secondi)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _inputController,
                                      decoration: InputDecoration(
                                        labelText: 'Imposta secondi',
                                        hintText: 'Inserisci un numero intero',
                                        prefixIcon: Icon(
                                          Icons.timer,
                                          color: _accentColor.withOpacity(0.7),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _updateTimerSettings,
                                    child: const Text('Applica'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 300.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Platform Instructions
                    _buildPlatformInstructions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
