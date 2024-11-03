import 'dart:io';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:text_to_image_ai/colors.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Uint8List? imageBytes;
  bool isLoading = false;

  final TextEditingController _textEditingController = TextEditingController();

  Future<void> generateImage(String prompt) async {
    FocusScope.of(context).unfocus();
    const apiKey = 'sk-UTOwzsOuxYSGqjJiioIST1r1CvfsLMLrQ0WVbctA1YUD7B4b';
    final url = Uri.parse(
        'https://api.stability.ai/v2beta/stable-image/generate/ultra');

    // Payload for the API request
    final payload = {
      'prompt': prompt,
      'output_format': 'webp',
    };

    // Set up headers
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Accept': 'image/*',
    };

    // Start loading
    setState(() {
      isLoading = true;
    });

    try {
      // Send POST request with multipart form data
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(headers)
        ..fields.addAll(payload);

      final response = await request.send();

      if (response.statusCode == 200) {
        // Read image bytes from the response stream
        final bytes = await response.stream.toBytes();
        setState(() {
          imageBytes = bytes;
        });
      } else {
        // Handle error if the response is not successful
        final responseData = await response.stream.bytesToString();
        throw Exception('Error ${response.statusCode}: $responseData');
      }
    } catch (e) {
      print('Failed to generate image: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> downloadImage() async {
    if (imageBytes == null) return;

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/generated_image.webp';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Image saved $filePath")),
    );
  }

  Future<void> shareImage() async {
    if (imageBytes == null) return;

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/shared_image.webp';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes!);

    Share.shareFiles([filePath], text: 'Check out this generated image!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.primaryColor,
        foregroundColor: MyColors.whiteColor,
        centerTitle: true,
        title: const Text(
          "Text to Image Generator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  TextFormField(
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      hintText: "Enter your prompt..",
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: MyColors.primaryColor)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: MyColors.primaryColor, width: 2)),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 13, horizontal: 15),
                          backgroundColor: MyColors.blackColor,
                          foregroundColor: MyColors.whiteColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        generateImage(_textEditingController.text);
                      },
                      child: const Text(
                        "Generate Image",
                        style: TextStyle(fontSize: 18),
                      ))
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              // ignore: unnecessary_null_comparison
              isLoading
                  ? const CircularProgressIndicator()
                  : imageBytes != null
                      ? FadedScaleAnimation(
                          child: SizedBox(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * .5,

                            child: Image.memory(
                              imageBytes!,
                            ), // Display the image from memory
                          ),
                        )
                      : const SizedBox.shrink(),
              const SizedBox(
                height: 10,
              ),
              imageBytes != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: MyColors.blackColor,
                              borderRadius: BorderRadius.circular(8)),
                          child: IconButton(
                              onPressed: downloadImage,
                              icon: Icon(
                                Icons.download,
                                color: MyColors.primaryColor,
                                size: 30,
                              )),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: MyColors.blackColor,
                              borderRadius: BorderRadius.circular(8)),
                          child: IconButton(
                              onPressed: shareImage,
                              icon: Icon(
                                Icons.share,
                                color: MyColors.whiteColor,
                                size: 30,
                              )),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
