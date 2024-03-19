import 'dart:async';
import 'dart:io';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}
class _RecordScreenState extends State<RecordScreen> {
  EdScreenRecorder? screenRecorder;
  RecordOutput? _response;
  bool inProgress = false;
  @override
  void initState() {
    super.initState();
    screenRecorder = EdScreenRecorder();
  }
  Future<void> startRecord({required String fileName, required int width, required int height}) async {
  try {
     var startResponse = await screenRecorder?.startRecordScreen(
        fileName: "Ilyas",
        audioEnable: false,
        width: width,
        height: height,
      );
    setState(() {
      _response = startResponse;
    });
  } on PlatformException {
    kDebugMode ? debugPrint("Error: An error occurred while starting the recording!") : null;
  }
}
Future<void> stopRecord() async {
  try {
    var stopResponse = await screenRecorder?.stopRecord();
    if (stopResponse != null && await File(stopResponse.file.path).exists()) {
      // Dosya varsa ve başarıyla oluşturulmuşsa, galeriye kaydedilmiş olmalı.
      // Burada dosyanın yolunu ve dosya adını yazdırarak kontrol edebilirsiniz.
      kDebugMode ? debugPrint("File path: ${stopResponse.file.path}") : null;
      OpenFile.open(stopResponse.file.path);
    } else {
      // Dosya yoksa, kayıt işlemi başarısız olmuş olabilir veya dosya kaydedilmemiş olabilir.
      kDebugMode ? debugPrint("Error: The file does not exist.") : null;
    }
    setState(() {
      _response = stopResponse;
    });
  } on PlatformException catch (e) {
    kDebugMode ? debugPrint("Error: An error occurred while stopping recording. $e") : null;
  }
}



  Future<void> pauseRecord() async {
    try {
      await screenRecorder?.pauseRecord();
    } on PlatformException {
      kDebugMode ? debugPrint("Error: An error occurred while pause recording.") : null;
    }
  }

  Future<void> resumeRecord() async {
    try {
      await screenRecorder?.resumeRecord();
    } on PlatformException {
      kDebugMode ? debugPrint("Error: An error occurred while resume recording.") : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("File: ${_response?.file.path}"),
            Text("Status: ${_response?.success.toString()}"),
            Text("Event: ${_response?.eventName}"),
            Text("Progress: ${_response?.isProgress.toString()}"),
            Text("Message: ${_response?.message}"),
            Text("Video Hash: ${_response?.videoHash}"),
            Text("Start Date: ${(_response?.startDate).toString()}"),
            Text("End Date: ${(_response?.endDate).toString()}"),
            ElevatedButton(
              onPressed: () => startRecord(
                fileName: "eren",
                width: context.size?.width.toInt() ?? 0,
                height: context.size?.height.toInt() ?? 0,
              ),
              child: const Text('START RECORD'),
            ),
            ElevatedButton(onPressed: () => resumeRecord(), child: const Text('RESUME RECORD')),
            ElevatedButton(onPressed: () => pauseRecord(), child: const Text('PAUSE RECORD')),
            ElevatedButton(onPressed: () => stopRecord(), child: const Text('STOP RECORD')),
          ],
        );
  }
}