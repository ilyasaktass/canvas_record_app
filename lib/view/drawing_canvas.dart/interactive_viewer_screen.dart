import 'package:flutter/material.dart';

class InteractiveViewerScreen extends StatefulWidget {
  const InteractiveViewerScreen({super.key, required this.child, required this.controller});
  final Widget child;
  final TransformationController controller;
  @override
  _InteractiveViewerScreenState createState() => _InteractiveViewerScreenState();
}

class _InteractiveViewerScreenState extends State<InteractiveViewerScreen> {

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: widget.controller,
      maxScale: 2,
      minScale: 0.5,
       onInteractionEnd: (details) {
        // Save the current state of the transformationController
        widget.controller.value = widget.controller.value;
      },
      child: widget.child,
    );
  }
}