import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyFullPicture extends StatefulWidget {
  final String webviewLINK;
  MyFullPicture({Key key, this.webviewLINK}) : super(key: key);
  @override
  _MyFullPictureState createState() => _MyFullPictureState();
}

class _MyFullPictureState extends State<MyFullPicture> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (BuildContext context) {
        print('webviewLINK');
        print(widget.webviewLINK);
        return WebView(
          initialUrl: '${widget.webviewLINK}',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
        );
      }),
    );
  }
}
