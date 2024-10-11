import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auto_desktop/auto_desktop.dart';
import 'package:hid_listener/hid_listener.dart';

void main() {
  if (!getListenerBackend()!.initialize()) {
    print("Failed to initialize listener backend");
  }

  getListenerBackend()!.addMouseListener(mouseListener);
  runApp(const MouseMoover());
}

void mouseListener(MouseEvent event) {
  print("mouse move");
}

class MouseMoover extends StatefulWidget {
  const MouseMoover({super.key});

  @override
  MouseMooverState createState() => MouseMooverState();
}

class MouseMooverState extends State<MouseMoover> {
  Timer? _timer;
  final Random _random = Random();
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _startMouseMovement();
  }

  void _startMouseMovement() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isRunning) {
        _moveMouseToRandomPosition();
      }
    });
  }

  void _moveMouseToRandomPosition() {
    int screenHeight = MediaQuery.of(context).size.height.toInt();
    int screenWidth = MediaQuery.of(context).size.width.toInt();

    int randomX = _random.nextInt(screenWidth);
    int randomY = _random.nextInt(screenHeight);

    mouseMove(randomX, randomY);
  }

  void _toggleMouseMovement() {
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mouse Moover',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simulatore di Movimento del Mouse'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRunning
                    ? 'Il mouse si muove in una posizione casuale ogni 5 secondi'
                    : 'Il movimento del mouse è stato fermato',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleMouseMovement,
                child: Text(
                  _isRunning ? 'Ferma Movimento' : 'Avvia Movimento',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
