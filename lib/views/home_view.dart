import 'dart:io';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:popover/popover.dart';
import 'package:share_plus/share_plus.dart';
import 'package:text_to_image_ai/colors.dart';
import 'package:http/http.dart' as http;
import 'package:text_to_image_ai/views/welcome_view.dart';
import 'package:url_launcher/url_launcher.dart';

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

    final url = Uri.parse(
        'https://api.stability.ai/v2beta/stable-image/generate/ultra');

    // Payload for the API request
    final payload = {
      'prompt': prompt,
      'output_format': 'webp',
    };

    // Set up headers
    final headers = {
      'Authorization': 'Bearer ${dotenv.env["API_KEY"]}',
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
      if (kDebugMode) {
        print('Failed to generate image: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveImageToGallery() async {
    // Request storage permission
    final status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        if (imageBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Something went wrong. try again later.")));
          return;
        }

        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/generated_image.webp';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes!);
        //  await ImageGallerySaver.saveFile(filePath);
        await ImageGallerySaverPlus.saveFile(filePath);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Saved to Gallery")));
      } on SocketException catch (e) {
        if (kDebugMode) {
          print("Error saving image: $e");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error saving image: ${e.toString()}")));
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error saving image: $e");
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error saving image")));
        }
      }
    } else {
      if (kDebugMode) {
        print("Storage permission denied");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission denied")));
      }
    }
  }

  Future<void> shareImage() async {
    if (imageBytes == null) return;

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/shared_image.webp';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes!);
    await Share.shareXFiles([XFile(filePath)]);
  }

  // Function to send a message to the SMS app
  Future<void> sendStopMessage() async {
    const phoneNumber = '21213';
    const message = 'STOP chtai';

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message}, // pre-fill message
    );

    // Check if the URL can be launched (i.e., if SMS is available)
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri); // Opens SMS app with pre-filled message
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch SMS')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: MyColors.primaryColor,
        foregroundColor: MyColors.whiteColor,
        centerTitle: true,
        title: const Text(
          "Text to Image Generator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                  onPressed: () async {
                    await showPopover(
                        context: context,
                        bodyBuilder: (context) => Column(
                              children: [
                                TextButton(
                                    onPressed: () async {
                                      await sendStopMessage();
                                      await Future.delayed(
                                          const Duration(seconds: 6));
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (_) {
                                        return WelcomePage();
                                      }));
                                    },
                                    child: const Text(
                                      "Unsubscribed",
                                      style: TextStyle(color: Colors.red),
                                    ))
                              ],
                            ),
                        width: 120,
                        height: 50,
                        backgroundColor: MyColors.blackColor,
                        direction: PopoverDirection.bottom);
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.black,
                  ));
            },
          )
        ],
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
                              onPressed: saveImageToGallery,
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
