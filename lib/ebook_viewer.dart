import 'package:epub_reader/epub_controller.dart';
import 'package:epub_reader/model/epub_page_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EbookViewer extends StatelessWidget {
  const EbookViewer(
      {super.key,
      required this.controller,
      this.appBar,
      this.background,
      this.errorWidget,
      this.loadingWidget});
  final EpubReaderController controller;
  final Color? background;
  final AppBar? appBar;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EpubReaderController>(
      stream:
          controller.bookStream, // Replace with your custom controller's stream
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: background,
          appBar: appBar,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: snapshot.connectionState == ConnectionState.waiting
                ? _buildLoadingUi()
                : snapshot.hasError
                    ? buildErrorUi(snapshot)
                    : !snapshot.hasData
                        ? const SizedBox()
                        : SafeArea(
                            child: PageView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              controller: controller.pageController,
                              itemCount: controller.pages?.length,
                              itemBuilder: (i, c) => controller.state ==
                                      EbookSatus.loading
                                  ? _buildLoadingUi()
                                  : WebViewWidget(
                                      gestureRecognizers: {}..add(Factory<
                                              LongPressGestureRecognizer>(
                                          () => LongPressGestureRecognizer())),
                                      controller: controller.webController!),
                            ),
                          ),
          ),
        );
      },
    );
  }

  Widget buildErrorUi(AsyncSnapshot<EpubReaderController> snapshot) {
    return errorWidget ?? Center(child: Text('Error: ${snapshot.error}'));
  }

  Widget _buildLoadingUi() {
    return loadingWidget ?? const Center(child: CircularProgressIndicator());
  }
}
