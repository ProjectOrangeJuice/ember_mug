import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'mug.dart';

void main() {
  runApp(const MyApp());
}

FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
bool scanning = false;

void scanForMug(BuildContext context, Function(String) updateText) {
  if (scanning) {
    print("Already scanning");
    // return;
  }
  scanning = true;
  updateText("Starting bluetooth scan");

  // Start scanning for devices
  flutterBlue.scan(timeout: const Duration(seconds: 10)).listen((scanResult) {
    print(
        "Device -> ${scanResult.device.name}, with address ${scanResult.device.id} (general ${scanResult})");
    if (scanResult.device.name == "Ember Ceramic Mug") {
      updateText("Found mug - Connecting now");
      flutterBlue.stopScan();
      connectToMug(scanResult.device, context, updateText);
    }
  }, onDone: () {
    // Restart scanning after 10 seconds
    Future.delayed(Duration(seconds: 30)).then((value) => () {
          updateText("Nothing found - Restarting scan");
          flutterBlue.stopScan();
          sleep(const Duration(seconds: 1));
          print("Starting new scan");
          scanForMug(context, updateText);
        });
  }, onError: (error) {
    updateText("Error scanning!");
    print('Error during scan: $error');
    scanning = false;
  });
}

void connectToMug(
    BluetoothDevice device, BuildContext context, Function(String) updateText) {
  print("Connecting to this mug -> $device");

  device.connect().then((value) {
    updateText("Connected to the mug");
    // Do something after successfully connecting
    print("Connected to device!");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => MugScreen(mugUUID: device.id.toString())),
    );
  }).catchError((error) {
    updateText("Failed to connect to mug");
    // Handle the error
    print('Error connecting to device: $error');
    scanning = false;
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _progressText = "";

  void updateText(String text) {
    setState(() {
      _progressText = text; // new text to display
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              onPressed: () {
                scanForMug(context, updateText);
              },
              icon: const ImageIcon(
                AssetImage('assets/images/mug.png'),
              ),
              iconSize: 150,
            ),
            Text(_progressText)
          ],
        ),
      ),
    );
  }
}
