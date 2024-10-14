import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:auto_desktop/auto_desktop.dart';
import 'package:hid_listener/hid_listener.dart';

void main() {
  if (!getListenerBackend()!.initialize()) {
    print("Failed to initialize listener backend");
  }
  runApp(const MouseMoover());
}

class MouseMoover extends StatefulWidget {
  const MouseMoover({super.key});

  @override
  State createState() => _MouseMooverState();
}

class _MouseMooverState extends State<MouseMoover> {
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

  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    mouseListenerID = getListenerBackend()!.addMouseListener(mouseListener)!;
    keyboardListenerID =
        getListenerBackend()!.addKeyboardListener(keyboardListener)!;
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inactivityTimer?.cancel();
    _updateTimer?.cancel();
    getListenerBackend()!
        .removeMouseListener(mouseListenerID); // Remove listener

    getListenerBackend()!
        .removeKeyboardListener(keyboardListenerID); // Remove listener
    _inputController.dispose();
    super.dispose();
  }

  void mouseListener(MouseEvent event) {
    if (_isRunning) {
      // Only stop if automatic movement is running
      _stopAndReset();
    }
    _resetInactivityTimer(); // Always reset the inactivity timer
  }

  void keyboardListener(RawKeyEvent event) {
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
      mouseMove(randomX, randomY);
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
  }

  void _updateTimerSettings() {
    int newValue;
    try {
      newValue = int.parse(_inputController.text);
      setState(() {
        _remainingSeconds = newValue;
        _inactivityDuration = Duration(seconds: newValue);
        _stopAndReset(); // Reset the timers with the new values
      });
    } catch (e) {
      // Handle parsing error
      print("Input non valido: ${_inputController.text}");
    }
  }

  @override
  Widget build(BuildContext context) {
    String inactivityStatusText =
        _inactivityTimer != null && _inactivityTimer!.isActive
            ? 'Attivazione automatica tra $_remainingSeconds secondi'
            : 'Attivazione automatica disattivata/scaduta';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mouse Moover')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRunning
                    ? 'Movimento del mouse attivo'
                    : 'Movimento del mouse disattivato',
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 10),
              Text(
                inactivityStatusText,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 400,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          labelText: 'Imposta secondi',
                          hintText: 'Inserisci un numero intero',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Space between TextField and Button
                    ElevatedButton(
                      onPressed: _updateTimerSettings,
                      child: const Text('Imposta'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleMouseMovement,
                child: Text(_isRunning ? 'Ferma Movimento' : 'Avvia Movimento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
