import 'dart:async';
import 'dart:io';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key, required this.canvasGlobalKey}) : super(key: key);

  final GlobalKey canvasGlobalKey;

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
      RenderRepaintBoundary boundary = widget.canvasGlobalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      String dirPath = await (await getTemporaryDirectory()).path;
      if (await Permission.storage.request().isGranted) {
        var startResponse = await screenRecorder?.startRecordScreen(
          fileName: fileName,
          audioEnable: true,
          width: boundary.size.width.toInt(),
          height: boundary.size.height.toInt(),
          dirPathToSave: dirPath,
        );
        setState(() {
          _response = startResponse;
        });
      } else {
        // İzin reddedildiğinde yapılacak işlemleri burada gerçekleştirin
      }
    } on PlatformException {
      kDebugMode ? debugPrint("Hata: Kayıt başlatılırken bir hata oluştu!") : null;
    }
  }

  Future<void> stopRecord() async {
    const fileName = "ilyas";
    try {
      var stopResponse = await screenRecorder?.stopRecord();
      if (stopResponse != null) {
        File file = File(stopResponse.file.path);
        // Dosya yoksa varsayılan yolu kullanın
        if (!await file.exists()) {
          Directory? directory = await getExternalStorageDirectory();
          String path = '${directory!.path}/$fileName.mp4';
          file = File(path);
        }
        // Dosyayı kaydedin
        Uint8List bytes = await stopResponse.file.readAsBytes();
        if (await file.exists()) {
          await file.writeAsBytes(bytes);
          // Dosyayı aç
          OpenFile.open(file.path);
        } else {
          debugPrint("Dosya bulunamadı: ${file.path}");
        }
        setState(() {
          _response = stopResponse;
        });
      } else {
        kDebugMode ? debugPrint("Hata: Dosya mevcut değil.") : null;
      }
    } on PlatformException catch (e) {
      kDebugMode ? debugPrint("Hata: Kayıt durdurulurken bir hata oluştu. $e") : null;
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
            fileName: "ilyas",
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
