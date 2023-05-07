import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MugScreen extends StatefulWidget {
  const MugScreen({super.key, required this.mugUUID});
  final String mugUUID;

  @override
  State<MugScreen> createState() => _MugState();
}

class _MugState extends State<MugScreen> {
  String _mugState = "Unknown";
  String _mugTemp = "Unknown";
  String _mugTargetTemp = "Unknown";
  String _mugBattery = "Unknown";

  void updateMugDetails(String mugUUID) async {
    Future<String> mugStateResult = Future(() => "Unknown (no update)");
    Future<String> mugTempResult = Future(() => "Unknown (no update)");
    Future<String> mugTargetTempResult = Future(() => "Unknown (no update)");
    Future<String> mugBatteryResult = Future(() => "Unknown (no update)");

    BluetoothDevice device = BluetoothDevice.fromId(mugUUID.toString());
    List<BluetoothService> services = await device.discoverServices();
    BluetoothCharacteristic? characteristic;
    services.forEach((service) {
      service.characteristics.forEach((c) {
        switch (c.uuid.toString()) {
          case "fc540008-236c-4c94-8fa9-944a3e5353fa":
            mugStateResult = mugState(c);
            sleep(Duration(milliseconds: 500));
            print("New mug state is ${mugStateResult}");
            break;
          case "fc540002-236c-4c94-8fa9-944a3e5353fa":
            mugTempResult = mugTemp(c);
            sleep(Duration(milliseconds: 500));
            break;
          case "fc540007-236c-4c94-8fa9-944a3e5353fa":
            mugBatteryResult = readBattery(c);
            sleep(Duration(milliseconds: 500));
            break;
          case "fc540003-236c-4c94-8fa9-944a3e5353fa":
            mugTargetTempResult = readTargetTemp(c);
            sleep(Duration(milliseconds: 500));
            break;
        }
      });
    });

    //Grab new results
    String mugStateUpdated = await mugStateResult;
    String mugTempUpdated = await mugTempResult;
    String mugTargetTempUpdated = await mugTargetTempResult;
    String mugBatteryUpdated = await mugBatteryResult;

    // Update the screen
    setState(() {
      _mugState = mugStateUpdated;
      _mugTemp = mugTempUpdated;
      _mugTargetTemp = mugTargetTempUpdated;
      _mugBattery = mugBatteryUpdated;
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer.periodic(Duration(seconds: 10), (timer) {
        updateMugDetails(widget.mugUUID);
      }); // Call that keeps repeating
    });
    return Scaffold(
      appBar: AppBar(
        title: Text("Mug"),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Mug state -> $_mugState"),
            Text("Mug Temp-> $_mugTemp"),
            Text("Mug target temp-> $_mugTargetTemp"),
            Text("Mug Battery-> $_mugBattery"),
            TextField(
              keyboardType: TextInputType.number,
              decoration: new InputDecoration(labelText: "Target temp"),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onChanged: (value) => {setTargetTemp(widget.mugUUID, value)},
            )
          ],
        ),
      ),
    );
  }
}

Future<String> mugTemp(BluetoothCharacteristic characteristic) async {
  List<int> data;
  try {
    data = await characteristic.read();
  } catch (err) {
    print("error getting the data -> ${err}");
    return Future(() => "No data");
  }

  ByteData byteData = ByteData.sublistView(Uint8List.fromList(data));
  int intValue = byteData.getUint16(0, Endian.little);
  double temp = intValue * 0.01;
  print(
      "Bluetooth result ! -> ${data} which is ${intValue} so that's ${temp}c");

  return temp.toString();
}

Future<String> readTargetTemp(BluetoothCharacteristic characteristic) async {
  List<int> data;
  try {
    data = await characteristic.read();
  } catch (err) {
    print("error getting the data -> ${err}");
    return Future(() => "No data");
  }

  ByteData byteData = ByteData.sublistView(Uint8List.fromList(data));
  int intValue = byteData.getUint16(0, Endian.little);
  double temp = intValue * 0.01;
  print(
      "Bluetooth result ! -> ${data} which is ${intValue} so that's ${temp}c");

  return temp.toString();
}

Future<String> readBattery(BluetoothCharacteristic characteristic) async {
  List<int> data;
  try {
    data = await characteristic.read();
  } catch (err) {
    print("error getting the data -> ${err}");
    return Future(() => "No data");
  }

  int percentage = data[0];
  String charging = "Not Charging";
  switch (data[1]) {
    case 0:
      charging = "Not Charging";
      break;
    case 1:
      charging = "Charging";
  }

  print("Data $data, percentage $percentage charging $charging");

  return "${percentage}% - ${charging}";
}

setTargetTemp(String mugUUID, String tempString) async {
  double tempToSet = double.parse(tempString);
  if (tempToSet < 30 || tempToSet > 60) {
    print("Temp setter too low");
    return;
  }
  if (tempToSet != 0) {
    tempToSet = tempToSet / 0.01;
  }

  int intValue = tempToSet.truncate();
  int uint16Value = intValue & 0xFFFF; // mask with 0xFFFF to get uint16 value

  if (tempToSet == 0) {
    uint16Value = 0000;
  }

  ByteData byteData = ByteData(2); // create a 2-byte buffer
  byteData.setUint16(
      0, uint16Value, Endian.little); // write uint16 value to buffer
  List<int> bytes = byteData.buffer.asUint8List();

  print(
      "Setting the temp to ${tempToSet} which is uint16 ${uint16Value} or ${bytes}");
}

Future<String> mugState(BluetoothCharacteristic characteristic) async {
  List<int> data;
  try {
    data = await characteristic.read();
  } catch (err) {
    print("error getting the data -> ${err}");
    return Future(() => "No data");
  }
  print("Bluetooth result ! -> ${data} which is ${String.fromCharCodes(data)}");
  print("First element.. ${data[0]} or ${data.first}");
  switch (data.first) {
    case 1:
      return "Empty";
    case 2:
      return "Filling";
    case 3:
      return "Unknown";
    case 4:
      return "Cooling";
    case 5:
      return "Heating";
    case 6:
      return "Stable";
  }
  return "Unknown";
}
