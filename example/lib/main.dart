import 'dart:io';

import 'package:epub_reader/ebook_viewer.dart';
import 'package:epub_reader/epub_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

void main() {
  runApp(const EpubViewer());
}

class EpubViewer extends StatefulWidget {
  const EpubViewer({super.key});
  @override
  _EpubViewer2State createState() => _EpubViewer2State();
}

class _EpubViewer2State extends State<EpubViewer> with WidgetsBindingObserver {
  bool loading = false;

  late EpubReaderController controller;
  bool isSearch = false;
  late SearchDataEntity searchDataEntity;
  bool isScreenMirroring = false;
  @override
  void initState() {
    super.initState();

    controller = EpubReaderController();
    searchDataEntity = SearchDataEntity(null, 0, 0);

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final mediaQueryData =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window);

    // Check for changes in screen dimensions
    if (mediaQueryData.size.shortestSide != mediaQueryData.size.longestSide) {
      setState(() {
        isScreenMirroring = true;
      });
    } else {
      setState(() {
        isScreenMirroring = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.grey,
          appBar: AppBar(
            title: Text(''),
            actions: [
              Text(
                  "chapter : ${controller.currentChapter} ,page ${controller.currentPage}"),
              IconButton(
                  onPressed: () async {
                    controller.nextPage();
                  },
                  icon: Icon(Icons.skip_next)),
              IconButton(
                  onPressed: () async {
                    controller.previosPage();
                  },
                  icon: Icon(Icons.skip_previous)),
              IconButton(
                  onPressed: () async {
                    try {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();

                      if (result != null) {
                        File file = File(result.files.single.path!);

                        // FlutterEpubReader.playEpub(file);
                        controller.run(file: file);
                      }
                    } catch (e) {}
                  },
                  icon: Icon(Icons.file_copy))
            ],
          ),
          drawer: controller.pages == null
              ? null
              : Drawer(
                  child: SafeArea(
                    child: ListView(
                      children: [
                        const Text("book content"),
                        const Divider(),
                        ...controller.pages!
                            .asMap()
                            .map((chapter, e) => MapEntry(
                                  chapter,
                                  Column(children: [
                                    InkWell(
                                      onTap: () => controller.jumpTpPage(
                                          chapter: chapter, page: 0),
                                      child: Text(
                                        e.chapter.Title ?? "no title",
                                        style: const TextStyle(
                                            fontSize: 20, color: Colors.blue),
                                      ),
                                    ),
                                    ...(e.subChapters ?? [])
                                        .asMap()
                                        .map((page, value) => MapEntry(
                                            page,
                                            InkWell(
                                              onTap: () {
                                                controller.jumpTpPage(
                                                    chapter: chapter,
                                                    page: page);
                                              },
                                              child: Card(
                                                child: Text(
                                                  value.chapter.Title ??
                                                      "no title",
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            )))
                                        .values
                                        .toList()
                                  ]),
                                ))
                            .values
                      ],
                    ),
                  ),
                ),
          body: EbookViewer(
            controller: controller,
            background: Colors.grey,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 20,
                    spreadRadius: -10,
                    color: Colors.grey),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              child: isSearch
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            textInputAction: TextInputAction.search,
                            onSubmitted: (a) async {
                              if (searchDataEntity.text != a) {
                                await controller.clearSearch(
                                    searchDataEntity.resultNumber.toInt());
                              }
                              final resultNumber =
                                  await controller.searchAndNavigate(a);
                              setState(() {
                                searchDataEntity.resultNumber =
                                    resultNumber.toInt();
                                searchDataEntity.text = a;
                                searchDataEntity.currentSelectResult = 1;
                              });
                            },
                            decoration: InputDecoration(
                                suffix:
                                    Text("${searchDataEntity.resultNumber}"),
                                border: InputBorder.none),
                          ),
                        ),
                        IconButton(
                          onPressed: searchDataEntity.currentSelectResult <
                                  searchDataEntity.resultNumber - 1
                              ? () {
                                  setState(() {
                                    searchDataEntity.currentSelectResult++;
                                  });
                                  controller.searchAndNavigateNext(
                                      searchDataEntity.currentSelectResult,
                                      searchDataEntity.resultNumber.toInt());
                                }
                              : null,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: searchDataEntity.currentSelectResult <
                                    searchDataEntity.resultNumber - 1
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: searchDataEntity.currentSelectResult > 1
                              ? () {
                                  setState(() {
                                    searchDataEntity.currentSelectResult--;
                                  });
                                  controller.searchAndNavigateNext(
                                      searchDataEntity.currentSelectResult,
                                      searchDataEntity.resultNumber.toInt());
                                }
                              : null,
                          icon: Icon(
                            Icons.keyboard_arrow_up,
                            color: searchDataEntity.currentSelectResult > 1
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            isSearch = false;
                          }),
                          icon: Icon(Icons.cancel_outlined),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            controller.increezeFontSize();
                          },
                          child: const Chip(
                            label: Icon(Icons.zoom_in),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            controller.decreezeFontSize();
                          },
                          child: const Chip(
                            label: Icon(Icons.zoom_out),
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () => setState(() {
                            isSearch = true;
                          }),
                          icon: Icon(Icons.search),
                        ),
                        // const SizedBox(width: 8),
                        // InkWell(
                        //   onTap: () async {
                        //     if (page > 0) {
                        //       page--;
                        //       pageController.jumpToPage(page);
                        //     }
                        //   },
                        //   child: const Chip(
                        //     label: Icon(LucideIcons.arrowLeft),
                        //   ),
                        // ),
                        // Expanded(
                        //     child: Text(
                        //   "${page + 1}/${epubPages?.length ?? 0}",
                        //   textAlign: TextAlign.center,
                        //   style: TextStyle(fontSize: 20),
                        // )),
                        // IconButton(
                        //   padding: EdgeInsets.zero,
                        //   onPressed: () async {
                        //     fontSizeIncriment = fontSizeIncriment + 0.1;
                        //     _webViewController!.injectCSSCode(
                        //         source: fontSize(
                        //             cssString: epubPages!.first.css,
                        //             size: fontSizeIncriment));
                        //   },
                        //   icon: const Icon(LucideIcons.zoomIn),
                        // ),
                        // const SizedBox(width: 8),
                        // IconButton(
                        //   padding: EdgeInsets.zero,
                        //   onPressed: () async {
                        //     fontSizeIncriment = fontSizeIncriment - 0.1;
                        //     _webViewController!.injectCSSCode(
                        //         source: fontSize(
                        //             cssString: epubPages!.first.css,
                        //             size: fontSizeIncriment));
                        //   },
                        //   icon: const Icon(LucideIcons.zoomOut),
                        // ),
                      ],
                    ),
            ),
          ),
        ));
  }
}

class SearchDataEntity {
  String? text;
  num resultNumber;
  int currentSelectResult;
  SearchDataEntity(this.text, this.resultNumber, this.currentSelectResult);
}
