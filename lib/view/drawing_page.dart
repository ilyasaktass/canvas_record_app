import 'dart:ui';

import 'package:canvas_record_app/main.dart';
import 'package:canvas_record_app/record/record_screen.dart';
import 'package:canvas_record_app/view/drawing_canvas.dart/drawing_canvas.dart';
import 'package:canvas_record_app/view/drawing_canvas.dart/models/drawing_mode.dart';
import 'package:canvas_record_app/view/drawing_canvas.dart/models/sketch.dart';
import 'package:canvas_record_app/view/drawing_canvas.dart/widgets/drawing_side_bar.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_hooks/flutter_hooks.dart';

class DrawingPage extends HookWidget {
  const DrawingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedColor = useState(Colors.black);
    final strokeSize = useState<double>(10);
    final eraserSize = useState<double>(30);
    final drawingMode = useState(DrawingMode.pencil);
    final filled = useState<bool>(false);
    final polygonSides = useState<int>(3);
    final backgroundImage = useState<Image?>(null);
    
    final canvasGlobalKey = GlobalKey();
    ;
    ValueNotifier<Sketch?> currentSketch = useState(null);
    ValueNotifier<List<Sketch>> allSketches = useState([]);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      initialValue: 1,
    );
    final canvasWidth = MediaQuery.of(context).size.width;
    final canvasHeight = MediaQuery.of(context).size.height -
        (kBottomNavigationBarHeight +
            kToolbarHeight +
            MediaQuery.of(context).padding.top +
            50);
    return Scaffold(
      appBar: AppBar(
        title: Text('Screen Recording App'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Business',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'School',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.indigo,
              width: double.maxFinite,
              child: DrawingCanvas(
                width: canvasWidth,
                height: canvasHeight,
                drawingMode: drawingMode,
                selectedColor: selectedColor,
                strokeSize: strokeSize,
                eraserSize: eraserSize,
                sideBarController: animationController,
                currentSketch: currentSketch,
                allSketches: allSketches,
                canvasGlobalKey: canvasGlobalKey,
                filled: filled,
                polygonSides: polygonSides,
                backgroundImage: backgroundImage,
              ),
            ),
          ),
           RecordScreen(canvasGlobalKey: canvasGlobalKey)
          // CanvasSideBar(
          //       drawingMode: drawingMode,
          //       selectedColor: selectedColor,
          //       strokeSize: strokeSize,
          //       eraserSize: eraserSize,
          //       currentSketch: currentSketch,
          //       allSketches: allSketches,
          //       canvasGlobalKey: canvasGlobalKey,
          //       filled: filled,
          //       polygonSides: polygonSides,
          //       backgroundImage: backgroundImage,
          //     ),
        ],
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  final AnimationController animationController;

  const _CustomAppBar({Key? key, required this.animationController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      width: double.maxFinite,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                if (animationController.value == 0) {
                  animationController.forward();
                } else {
                  animationController.reverse();
                }
              },
              icon: const Icon(Icons.menu),
            ),
            const Text(
              'Let\'s Draw',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
