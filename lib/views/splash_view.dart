import 'dart:async';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:text_to_image_ai/colors.dart';
import 'package:text_to_image_ai/views/home_view.dart';
import 'package:text_to_image_ai/views/welcome_view.dart';

import 'otp_verify_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
        return WelcomePage();
      }));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: Center(
        child: FadeAnimation(
          child: Image.asset(
            "assets/images/logo.png", // Replace with your image asset path
            height: 150.0,
          ),
        ),
      ),
    );
  }
}
