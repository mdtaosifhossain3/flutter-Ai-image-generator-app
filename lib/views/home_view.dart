import 'dart:io';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gal/gal.dart';
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

    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Field Can't be empty")));
      setState(() {
        isLoading = false;
      });
    }

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

  Future<void> saveImageToGallery(context) async {
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
        await Gal.putImage(filePath);
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
  Future<void> sendStopMessage(context) async {
    const phoneNumber = '21213';
    const message = 'STOP phai';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff232526),
        elevation: 8,
        centerTitle: true,
        toolbarHeight: 70,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [MyColors.primaryColor, MyColors.whiteColor],
          ).createShader(bounds),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const Icon(Icons.image, size: 32, color: Colors.white),

              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "DreamSnap",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Colors.white,
                  letterSpacing: 2,
                  fontFamily: "Montserrat",
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: MyColors.primaryColor.withValues(alpha: 0.5),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                            final navigator = Navigator.of(context);
                            await sendStopMessage(context);
                            await Future.delayed(const Duration(seconds: 6));
                            navigator.push(MaterialPageRoute(builder: (_) {
                              return WelcomePage();
                            }));
                          },
                          child: const Text(
                            "Unsubscribe",
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      ],
                    ),
                    width: 120,
                    height: 50,
                    backgroundColor: MyColors.blackColor,
                    direction: PopoverDirection.bottom,
                  );
                },
                icon: Icon(
                  Icons.more_vert,
                  color: MyColors.whiteColor,
                ),
              );
            },
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff232526), Color(0xff414345)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),
                // Glassmorphism Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _textEditingController,
                        cursorColor: MyColors.primaryColor,
                        style: TextStyle(
                          color: MyColors.whiteColor,
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          hintText: "Describe your dream image...",
                          hintStyle: TextStyle(
                            color:
                                MyColors.filledtextcolor.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.edit, color: MyColors.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: MyColors.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () {
                            generateImage(_textEditingController.text);
                          },
                          icon: const Icon(Icons.auto_awesome, size: 26),
                          label: const Text(
                            "Generate Image",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Image or Loader
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: isLoading
                      ? Column(
                          key: const ValueKey('loading'),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * .15,
                            ),
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 4,
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              "Generating your masterpiece...",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : imageBytes != null
                          ? FadedScaleAnimation(
                              key: const ValueKey('image'),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                height:
                                    MediaQuery.of(context).size.height * .45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 2,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.memory(
                                  imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                // Action Buttons
                AnimatedOpacity(
                  opacity: imageBytes != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: imageBytes != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GlassIconButton(
                              icon: Icons.download_rounded,
                              color: MyColors.primaryColor,
                              onTap: () => saveImageToGallery(context),
                              tooltip: "Save to Gallery",
                            ),
                            const SizedBox(width: 24),
                            _GlassIconButton(
                              icon: Icons.share_rounded,
                              color: Colors.white,
                              onTap: shareImage,
                              tooltip: "Share",
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Add this widget at the end of the file for glassy icon buttons:
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _GlassIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }
}
