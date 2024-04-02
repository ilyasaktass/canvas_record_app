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
  const RecordScreen({
    Key? key,
    required this.canvasGlobalKey,
    required this.recordPageWidth,
    required this.pageWidth,
    required this.pageHeight,
    required this.orientation,
  }) : super(key: key);

  final GlobalKey canvasGlobalKey;
  final double recordPageWidth;
  final double pageWidth;
  final double pageHeight;
  final Orientation? orientation;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  EdScreenRecorder? _screenRecorder;
  late String _fileName;

  @override
  void initState() {
    super.initState();
    _screenRecorder = EdScreenRecorder();
    _fileName = '';
  }

  // This method starts the screen recording
  Future<void> startRecord({required int width, required int height}) async {
    try {
      final fileName = 'video_${DateTime.now().millisecond}';
      String dirPath = (await getTemporaryDirectory()).path;
      if (await Permission.storage.request().isGranted) {
        await _screenRecorder?.startRecordScreen(
          fileName: fileName,
          audioEnable: true,
          width: width.toInt(),
          height: height.toInt(),
          dirPathToSave: dirPath,
        );
        setState(() {
          _fileName = fileName;
        });
      }
    } on PlatformException {
      kDebugMode
          ? debugPrint("Error: An error occurred while starting the recording.")
          : null;
    }
  }

  // This method stops the screen recording and crops the video
  Future<void> stopRecord() async {
    RenderRepaintBoundary sized = widget.canvasGlobalKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    try {
      var stopResponse = await _screenRecorder?.stopRecord();
      if (stopResponse != null) {
        File file = File(stopResponse.file.path);
        if (!await file.exists()) {
          debugPrint("File does not exist.");
          return;
        }

        // Directory? directory = await getExternalStorageDirectory();
        // final String outputPath = '${directory!.path}/$_fileName.mp4';

        // double cropX = sized.localToGlobal(Offset.zero).dx;
        // double cropY = sized.localToGlobal(Offset.zero).dy;
        // double cropWidth = sized.size.width;
        // double cropHeight = sized.size.height;
        // cropVideo(file.path, outputPath, cropWidth.toInt(), cropHeight.toInt(), cropX.toInt(),cropY.toInt());
        OpenFile.open(file.path);
      } else {
        debugPrint("Error: File does not exist.");
      }
    } on PlatformException catch (e) {
      kDebugMode
          ? debugPrint(
              "Error: An error occurred while stopping the recording. $e")
          : null;
    }
  }

  // This method pauses the screen recording
  Future<void> pauseRecord() async {
    try {
      await _screenRecorder?.pauseRecord();
    } on PlatformException {
      kDebugMode
          ? debugPrint("Error: An error occurred while pausing the recording.")
          : null;
    }
  }

  // This method resumes the screen recording
  Future<void> resumeRecord() async {
    try {
      await _screenRecorder?.resumeRecord();
    } on PlatformException {
      kDebugMode
          ? debugPrint("Error: An error occurred while resuming the recording.")
          : null;
    }
  }

  // This method crops the video
  void cropVideo(String inputPath, String outputPath, int cropWidth,
      int cropHeight, int videoCropX, int videoCropY) async {
    final String cropCommand =
        " -i $inputPath -vf \"crop=$cropWidth:$cropHeight:$videoCropX:$videoCropY\" -c:v h264 -b:v 2M -c:a copy $outputPath";

    await FFmpegKit.execute(cropCommand).then((session) async {
      final returnCode = await session.getReturnCode();
      debugPrint(await session.getOutput());
      if (returnCode!.isValueSuccess()) {
        OpenFile.open(outputPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: widget.orientation == Orientation.portrait ? double.maxFinite : widget.recordPageWidth,
        child: ColoredBox(
            color: Colors.white,
            child: widget.orientation == Orientation.landscape
                ? Column(
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
                      IconButton(
                        onPressed: () => stopRecord(),
                        icon: const Icon(Icons.stop),
                        color: Colors.red,
                        tooltip: 'Stop',
                      )
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: () => startRecord(
                            width: context.size?.width.toInt() ?? 0,
                            height: context.size?.height.toInt() ?? 0,
                          ),
                          icon: const Icon(Icons.video_call),
                          color: Colors.red,
                          tooltip: 'Start Recording',
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          onPressed: () => pauseRecord(),
                          icon: const Icon(Icons.pause),
                          color: Colors.blue,
                          tooltip: 'Pause',
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          onPressed: () => resumeRecord(),
                          icon: const Icon(Icons.play_arrow),
                          color: Colors.blue,
                          tooltip: 'Resume',
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          onPressed: () => stopRecord(),
                          icon: const Icon(Icons.stop),
                          color: Colors.red,
                          tooltip: 'Stop',
                        ),
                      )
                    ],
                  )));
  }
}
