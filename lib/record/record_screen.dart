import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:video_player/video_player.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    Key? key,
    required this.canvasGlobalKey,
  }) : super(key: key);

  final GlobalKey canvasGlobalKey;

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
    //  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual);
    final RenderBox sized =
        widget.canvasGlobalKey.currentContext!.findRenderObject() as RenderBox;
    try {
      var stopResponse = await _screenRecorder?.stopRecord();
      if (stopResponse != null) {
        File file = File(stopResponse.file.path);
        if (!await file.exists()) {
          debugPrint("File does not exist.");
          return;
        }

        Directory? directory = await getExternalStorageDirectory();
        final String outputPath = '${directory!.path}/$_fileName.mp4';

        double cropX = sized.localToGlobal(Offset.zero).dx -
            MediaQuery.of(context).padding.left;
        double cropY = sized.localToGlobal(Offset.zero).dy -
            MediaQuery.of(context).padding.top;
        double cropWidth = MediaQuery.of(context).size.width;
        double cropHeight = MediaQuery.of(context).size.height;
        final videoSize = await getVideoResolution(file.path);
        print("width: ${cropWidth} height: ${cropHeight}");
         cropVideo(file.path, outputPath, cropWidth.toInt(), cropHeight.toInt(),0, 0,cropWidth.toInt(), cropHeight.toInt());
       // OpenFile.open(file.path);
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

void cropVideo(String inputPath, String outputPath, int cropWidth,
      int cropHeight, int videoCropX, int videoCropY, int originalWidth, int originalHeight) async {
    final String cropCommand =
        "-i $inputPath -vf \"crop=$cropWidth:$cropHeight:$videoCropX:$videoCropY,scale=$originalWidth:$originalHeight\" -c:v h264 -b:v 2M -c:a copy $outputPath";

    await FFmpegKit.execute(cropCommand).then((session) async {
      final returnCode = await session.getReturnCode();
      debugPrint(await session.getOutput());
      if (returnCode!.isValueSuccess()) {
        OpenFile.open(outputPath);
      }
    });
}

  Future<Size> getVideoResolution(String videoPath) async {
    final controller = VideoPlayerController.file(File(videoPath));

    await controller.initialize();

    final size = controller.value.size;

    controller.dispose();

    return size;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
       direction: Axis.horizontal,
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
    );
  }
}
