import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ImageScreen extends StatelessWidget {
  final ValueNotifier<ui.Image?> backgroundImage;

  const ImageScreen({super.key, required this.backgroundImage});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ui.Image?>(
      valueListenable: backgroundImage,
      builder: (context, image, _) {
        if (image != null) {
          return SizedBox(
            width: 500,
            height: 300,
            child: RawImage(
              scale: 0.5,
              image: image,
              fit: BoxFit.cover,
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
