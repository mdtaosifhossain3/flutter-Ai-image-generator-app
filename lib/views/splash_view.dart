import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:text_to_image_ai/colors.dart';
import 'package:text_to_image_ai/views/home_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
        return const HomeView();
      }));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FadeAnimation(
              child: Text(
                "Welcome to",
                style: TextStyle(
                    color: MyColors.whiteColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ScaleAnimation(
              child: Text(
                "Ai Image Generator",
                style: TextStyle(color: MyColors.whiteColor, fontSize: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
