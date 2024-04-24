import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoaderScreen extends StatelessWidget {
  const LoaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Opacity(
          opacity: 0.5,  // Opacity level
          child: ModalBarrier(dismissible: false, color: Colors.grey),  // This creates a barrier over the screen
        ),
        Center(
          child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.red, size: 15),
        ),
      ],
    );
  }
}