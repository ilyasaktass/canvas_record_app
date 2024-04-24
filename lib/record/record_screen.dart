import 'dart:async';
import 'dart:io';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

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
  bool isRecording = false;
  Timer? _timer;
  int _start = 0;

  @override
  void initState() {
    super.initState();
    _screenRecorder = EdScreenRecorder();
    _fileName = '';
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) => incrementStart());
  }

  void incrementStart() {
    setState(() {
      _start++;
    });
  }

  void stopTimer() {
    _timer?.cancel();

  }

  Future<void> startRecord({required int width, required int height}) async {
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
        setFileName(fileName);
      }
    } on PlatformException {
      printError("An error occurred while starting the recording.");
    }
  }

  void setFileName(String fileName) {
    setState(() {
      _fileName = fileName;
    });
  }

  Future<void> stopRecord() async {
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
        double cropY = kToolbarHeight;
        double cropWidth = MediaQuery.of(context).size.width - 100;
        double cropHeight = MediaQuery.of(context).size.height - cropY;
        cropVideo(file.path, outputPath, cropWidth.toInt(), cropHeight.toInt(),
            0, cropY);
      } else {
        debugPrint("Error: File does not exist.");
      }
    } on PlatformException catch (e) {
      printError("An error occurred while stopping the recording. $e");
    }
  }

  Future<void> pauseRecord() async {
    try {
      await _screenRecorder?.pauseRecord();
      stopTimer();
    } on PlatformException {
      printError("An error occurred while pausing the recording.");
    }
  }

  Future<void> resumeRecord() async {
    try {
      await _screenRecorder?.resumeRecord();
      startTimer();
    } on PlatformException {
      printError("An error occurred while resuming the recording.");
    }
  }

  void printError(String message) {
    if (kDebugMode) {
      debugPrint("Error: $message");
    }
  }

  void cropVideo(String inputPath, String outputPath, int cropWidth,
      int cropHeight, int videoCropX, double videoCropY) async {
        
    final String cropCommand =
        "-i $inputPath -vf \"crop=$cropWidth:$cropHeight:$videoCropX:$videoCropY\" -c:a copy $outputPath";

    final session = await FFmpegKit.execute(cropCommand);
    final returnCode = await session.getReturnCode();
    final output = await session.getOutput();

    if (returnCode!.isValueSuccess()) {
      debugPrint(output);
      OpenFile.open(outputPath);
    } else {
      debugPrint("Video kırpma işlemi başarısız oldu. Hata kodu: $returnCode");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!isRecording)
          IconButton(
            onPressed: () {
              startRecord(
                width: MediaQuery.of(context).size.width.toInt(),
                height: MediaQuery.of(context).size.height.toInt(),
              );
              setState(() {
                isRecording = true;
                startTimer();
              });
            },
            icon: const Icon(Icons.video_call),
            color: Colors.red,
            tooltip: 'Start Recording',
          ),
           Text(
          "${Duration(seconds: _start).inMinutes.remainder(60).toString().padLeft(2, '0')}:${(Duration(seconds: _start).inSeconds.remainder(60)).toString().padLeft(2, '0')}"),
        if (isRecording) ...[
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
            onPressed: () {
              stopRecord();
              setState(() {
                isRecording = false;
                _start = 0;
                stopTimer();
              });
            },
            icon: const Icon(Icons.stop),
            color: Colors.red,
            tooltip: 'Stop',
          ),
         
        ]
      ],
    );
  }
}
