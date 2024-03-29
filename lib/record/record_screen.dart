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

  Future<void> startRecord({required int width, required int height}) async {
    try {
      RenderRepaintBoundary boundary = widget.canvasGlobalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      double height = boundary.size.height;
      double width = boundary.size.width;
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
      } else {
        // İzin reddedildiğinde işlemler buraya yazılabilir.
      }
    } on PlatformException {
      // Kayıt başlatılırken hata oluşursa burası çalışır.
      kDebugMode
          ? debugPrint("Hata: Kayıt başlatılırken bir hata oluştu.")
          : null;
    }
  }

  Future<void> stopRecord() async {
    RenderRepaintBoundary sized = widget.canvasGlobalKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    try {
      var stopResponse = await _screenRecorder?.stopRecord();
      if (stopResponse != null) {
        File file = File(stopResponse.file.path);
        if (!await file.exists()) {
          debugPrint("Dosya mevcut değil.");
          return;
        }

        Directory? directory = await getExternalStorageDirectory();
        final String outputPath = '${directory!.path}/$_fileName.mp4';

        // Ekranın üst ve altından 40 piksel bırakarak kırpma işlemi için gerekli değerleri hesaplayın
        double cropX =
            sized.localToGlobal(Offset.zero).dx; // X koordinatı başlangıcı
        double cropY =
            sized.localToGlobal(Offset.zero).dy; // Y koordinatı başlangıcı
        double cropWidth = sized.size.width;
        double cropHeight = sized.size.height;

        double pageheight = MediaQuery.of(context).size.height;
        double pageWidth = MediaQuery.of(context).size.width;
        double statusBar = MediaQuery.of(context).padding.top;
         OpenFile.open(file.path);
        print(
            'CanvasWidth:$cropWidth; CanvasHeight:$cropHeight; cropX:$cropX; cropY:$cropY;toolBarHeight:$kToolbarHeight;navigationBarHeight:$kBottomNavigationBarHeight;pageheight:$pageheight');
        // final String cropCommand =
        //     "-i ${file.path} -filter:v \"crop=$cropWidth:$cropHeight:$cropX:$cropY\" -c:v libx264 -preset slow -crf 18 $outputPath";
        final String cropCommand =
            " -i ${file.path} -vf \"crop=$cropWidth:$cropHeight:$cropX:$cropY\" -c:v h264 -b:v 2M -c:a copy $outputPath";

        //ffmpeg -i girdi_video.mp4 -vf "crop=genişlik:yükseklik:x_konumu:y_konumu" -c:v libx264 -crf 18 -preset slow -c:a copy çıktı_video.mp4

        await FFmpegKit.execute(cropCommand).then((session) async {
          final returnCode = await session.getReturnCode();
          debugPrint(await session.getOutput());
          if (returnCode!.isValueSuccess()) {
            OpenFile.open(file.path);
          }
        });
      } else {
        debugPrint("Hata: Dosya mevcut değil.");
      }
    } on PlatformException catch (e) {
      kDebugMode
          ? debugPrint("Hata: Kayıt durdurulurken bir hata oluştu. $e")
          : null;
    }
  }

  Future<void> pauseRecord() async {
    try {
      await _screenRecorder?.pauseRecord();
    } on PlatformException {
      kDebugMode
          ? debugPrint("Hata: Kayıt duraklatılırken bir hata oluştu.")
          : null;
    }
  }

  Future<void> resumeRecord() async {
    try {
      await _screenRecorder?.resumeRecord();
    } on PlatformException {
      kDebugMode
          ? debugPrint("Hata: Kayıt devam ettirilirken bir hata oluştu.")
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 50,
        child: ColoredBox(
          color: Colors.pink,
          child: Row(
             
                children: [
          IconButton(
            onPressed: () => startRecord(
              width: context.size?.width.toInt() ?? 0,
              height: context.size?.height.toInt() ?? 0,
            ),
            icon: const Icon(Icons.video_call),
            color: Colors.red,
            tooltip: 'Kaydı Başlat',
          ),
          IconButton(
            onPressed: () => pauseRecord(),
            icon: const Icon(Icons.pause),
            color: Colors.blue,
            tooltip: 'Duraklat',
          ),
          IconButton(
            onPressed: () => resumeRecord(),
            icon: const Icon(Icons.play_arrow),
            color: Colors.blue,
            tooltip: 'Devam Ettir',
          ),
          IconButton(
            onPressed: () => stopRecord(),
            icon: const Icon(Icons.stop),
            color: Colors.red,
            tooltip: 'Durdur',
          )
                ],
              ),
        ));
  }
}
