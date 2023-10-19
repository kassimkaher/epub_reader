// import 'dart:async';
// import 'package:epub_reader/epub_page_entity.dart';
// import 'package:epub_reader/epub_reader.dart';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class EpubViewer extends StatefulWidget {
//   const EpubViewer({super.key});
//   @override
//   _EpubViewerState createState() => _EpubViewerState();
// }

// class _EpubViewerState extends State<EpubViewer> {
//   late EpubReaderController epubReaderController;

//   late StreamController<EpubReaderController> _counterController;

//   @override
//   void initState() {
//     super.initState();
//     epubReaderController = EpubReaderController();
//     _counterController = (() async* {
//       EpubReaderController(onUpdate: (a){
//          yield a;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<EpubReaderController>(
//         stream: _counterController,
//         builder: (
//           context,
//           AsyncSnapshot<EpubReaderController> cont,
//         ) {
//           return Scaffold(
//             body: cont.data!.state == EpubState.init
//                 ? const Center(
//                     child: CircularProgressIndicator(),
//                   )
//                 : PageView.builder(
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: cont.data!.pages?.length,
//                     itemBuilder: (i, c) =>
//                         WebViewWidget(controller: cont.data!.controller!),
//                   ),
//           );
//         });
//   }
// }
