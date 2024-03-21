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
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key, required this.canvasGlobalKey})
      : super(key: key);

  final GlobalKey canvasGlobalKey;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  EdScreenRecorder? screenRecorder;
  var _fileName = '';
  bool isRecording = false;
  bool isPaused = false;
  CanvasPosition? _canvasPosition;
  @override
  void initState() {
    super.initState();
    screenRecorder = EdScreenRecorder();
  }

  Future<void> startRecord({required int width, required int height}) async {
    try {
      RenderRepaintBoundary boundary = widget.canvasGlobalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      Offset position = boundary!.localToGlobal(Offset.zero);

      double xPosition = position.dx;
      double yPosition = position.dy;
      double height = boundary!.size.height;
      double width = boundary!.size.width;
      final fileName = 'video_${DateTime.now().millisecond}';
      String dirPath = (await getTemporaryDirectory()).path;
      if (await Permission.storage.request().isGranted) {
        await screenRecorder?.startRecordScreen(
          fileName: fileName,
          audioEnable: true,
          width: width.toInt(),
          height: height.toInt(),
          dirPathToSave: dirPath,
        );
        setState(() {
          _fileName = fileName;
          isRecording = true;
          _canvasPosition = CanvasPosition(xPosition, yPosition, width, height);
        });
      } else {
        // Handle when permission is denied
      }
    } on PlatformException {
      kDebugMode
          ? debugPrint("Error: An error occurred while starting recording.")
          : null;
    }
  }

  Future<void> stopRecord() async {
    try {
      var stopResponse = await screenRecorder?.stopRecord();
      if (stopResponse != null) {
        File file = File(stopResponse.file.path);
        if (!await file.exists()) {
          debugPrint("File does not exist.");
          return;
        }

        Directory? directory = await getExternalStorageDirectory();
        final String outputPath = '${directory!.path}/${_fileName}.mp4';

        // Crop command example: crop=width:height:x:y
        final String cropCommand =
            "-i ${file.path} -filter:v \"crop=${_canvasPosition!.width}:${_canvasPosition!.height}:${_canvasPosition!.x}:${_canvasPosition!.y}\" $outputPath";

        await FFmpegKit.execute(cropCommand).then((session) async {
          final returnCode = await session.getReturnCode();
          File outputFile = File(outputPath);
          bool fileExists = await outputFile.exists();
          if (fileExists) {
            debugPrint("Dosya zaten mevcut: $outputPath");
          } else {
            debugPrint("Dosya mevcut değil: $outputPath");
          }

          OpenFile.open(outputPath);
        });
      } else {
        debugPrint("Error: File not available.");
      }
    } on PlatformException catch (e) {
      kDebugMode
          ? debugPrint("Error: An error occurred while stopping recording. $e")
          : null;
    }
    setState(() {
      isRecording = false;
    });
  }

  Future<void> pauseRecord() async {
    try {
      await screenRecorder?.pauseRecord();
    } on PlatformException {
      kDebugMode
          ? debugPrint("Error: An error occurred while pausing recording.")
          : null;
    }
    setState(() {
      isPaused = true;
    });
  }

  Future<void> resumeRecord() async {
    try {
      await screenRecorder?.resumeRecord();
    } on PlatformException {
      kDebugMode
          ? debugPrint("Error: An error occurred while resuming recording.")
          : null;
    }
    setState(() {
      isPaused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'Records',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              IconButton(
                onPressed: () => startRecord(
                  width: context.size?.width.toInt() ?? 0,
                  height: context.size?.height.toInt() ?? 0,
                ),
                icon: const Icon(Icons.video_call),
                color: Colors.red,
                tooltip: 'Start Recording',
              ),
              IconButton(
                onPressed: () => pauseRecord(),
                icon: const Icon(Icons.pause),
                color: Colors.blue,
                tooltip: 'Pause',
              ),
              IconButton(
                onPressed: () => resumeRecord(),
                icon: const Icon(Icons.play_arrow),
                color: Colors.blue,
                tooltip: 'Resume',
              ),
              isRecording
                  ? IconButton(
                      onPressed: () => stopRecord(),
                      icon: const Icon(Icons.stop),
                      color: Colors.red,
                      tooltip: 'Stop',
                    )
                  : const SizedBox()
            ],
          )
        ],
      ),
    );
  }
}

class CanvasPosition {
  double x;
  double y;
  double width;
  double height;

  CanvasPosition(this.x, this.y, this.width, this.height);
}
