import 'package:flutter/material.dart';
import 'package:text_to_image_ai/colors.dart';
import 'package:text_to_image_ai/widgets/button_widget.dart';

import '../services/send_otp_service.dart';

class WelcomePage extends StatelessWidget {
  WelcomePage({super.key});
  final controller = TextEditingController();
  final service = SendOTPService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,backgroundColor: Colors.transparent,surfaceTintColor: Colors.transparent,),
      backgroundColor: MyColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * .9,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //-----------------------Logo-----------------------
                Column(
                  children: [
                    Image.asset(
                      "assets/images/logo.png", // Replace with your image asset path
                      height: 100.0,
                    ),
                    const SizedBox(height: 10.0),
                    //-----------------------welcome text-----------------------
                    Text(
                      'Your AI Image Generator',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: MyColors.whiteColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                SizedBox(
                  height: MediaQuery.of(context).size.height * .2,
                ),

                Column(
                  children: [
                    //-----------------------Register-----------------------
                    SizedBox(
                      height: 53,
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.only(left: 15),
                            fillColor: MyColors.whiteColor,
                            filled: true,
                            hintText: "Enter Robi/Airtel Number...",

                            hintStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: MyColors.blackColor.withOpacity(0.5)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide:
                                    BorderSide(color: MyColors.whiteColor)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide:
                                    BorderSide(color: MyColors.whiteColor))),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    InkWell(
                      onTap: () async {
                        await service.sendOTP(context, controller);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                            color: MyColors.blackColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: ButtonWidget(
                          label: "Submit",
                          bgcolor: MyColors.blackColor,
                        ),
                      ),
                    ),
                  ],
                )

                //-----------------------Sign Up-----------------------
              ],
            ),
          ),
        ),
      ),
    );
  }
}
