import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WebViewExample(),
    );
  }
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  final TextEditingController _textController = TextEditingController(
      text:
          "https://dev01.dguardcloud.com.br/live/l_6GdB7ie.stream/playlist.m3u8");
  late WebViewController _controller;
  bool paused = false;
  bool muted = false;
  bool pictureModeIsEnabled = false;
  final platform = const MethodChannel('com.seventh/pip');
  @override
  void initState() {
    super.initState();

    var controller = WebViewController();

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    } else if (controller.platform is WebKitWebViewController) {
      final params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
      controller = WebViewController.fromPlatformCreationParams(params);
    }
    _controller = controller;
    _loadHtmlFromAssets();
  }

  @override
  Widget build(BuildContext context) {
    final player = AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(
        controller: _controller,
      ),
    );
    return FutureBuilder(
      future: platform.invokeMethod("isPIP"),
      builder: (context, data) {
        final isPIP = data.data ?? false;
        return isPIP
            ? player
            : Scaffold(
                appBar: AppBar(
                  title: const Text('Web Player'),
                ),
                backgroundColor: Colors.white,
                body: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                                label: Text("Video Url:")),
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        IconButton(
                          onPressed: () {
                            _changeUrl(_textController.text);
                          },
                          icon: const Icon(Icons.refresh),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    player,
                    const SizedBox(
                      height: 16,
                    ),
                    const Text("Botões no app flutter:"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            __togglePlay();
                          },
                          icon: Icon(
                            paused ? Icons.play_circle : Icons.pause_circle,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _toggleMute();
                          },
                          icon:
                              Icon(muted ? Icons.volume_off : Icons.volume_up),
                        ),
                        IconButton(
                          onPressed: () {
                            _enterPictureInPicture();
                          },
                          icon: const Icon(Icons.picture_in_picture),
                        ),
                      ],
                    )
                  ],
                ),
              );
      },
    );
  }

  void __togglePlay() async {
    if (paused) {
      await _controller
          .runJavaScript('document.querySelector("video").play();');
    } else {
      await _controller
          .runJavaScript('document.querySelector("video").pause();');
    }

    setState(() {
      paused = !paused;
    });
  }

  void _toggleMute() async {
    await _controller
        .runJavaScript('document.querySelector("video").muted = ${!muted};');
    setState(() {
      muted = !muted;
    });
  }

  void _changeUrl(String newUrl) async {
    await _controller.runJavaScript("""
    window.postMessage({type: "loadHlsPlayer", videoUrl: "$newUrl"}, "*");

    """);
  }

  void _enterPictureInPicture() async {
    if (Platform.isAndroid) {
      try {
        await platform
            .invokeMethod('enterPictureInPictureMode')
            .then((value) => setState(() {
                  pictureModeIsEnabled = true;
                }));
      } on PlatformException catch (e) {
        print("Failed to enter PiP mode: ${e.message}");
      }
    } else {
      await _controller.runJavaScript("""
      if (document.pictureInPictureEnabled) {
          var video = document.getElementById('video');
          if (video !== document.pictureInPictureElement) {
              video.requestPictureInPicture();
          } else {
              document.exitPictureInPicture();
          }
      } else {
          alert('Picture-in-Picture is not enabled.');
      }
    """);
    }
  }

  Future<void> _loadHtmlFromAssets() async {
    _controller.loadFlutterAsset('assets/player/player.html');
    _controller.setOnConsoleMessage((message) {
      log(message.message);
    });
  }
}
