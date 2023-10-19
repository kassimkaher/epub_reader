// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:epub_reader/model/epub_page_entity.dart';
import 'package:epub_reader/functions/functions.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EpubReaderController {
  List<EpubPageEntity>? pages;
  int bookPagesCount = 0;
  int fontsizePlus = 0;
  int currentPage = 0;
  int currentChapter = 0;
  EbookSatus state = EbookSatus.init;
  WebViewController? webController;
  late PageController pageController;
  int fontSize = 0;

  final StreamController<EpubReaderController> _bookStreamController =
      StreamController<EpubReaderController>();

  Stream<EpubReaderController> get bookStream => _bookStreamController.stream;

  Future<bool> run(
      {required File file, int? initialChapter, int? initialpage}) async {
    final epubBook = await EpubReader.readBook(await file.readAsBytes());

    final css = getEbookCss(epubBook);
    final js = getEbookJs(epubBook);
    List<EbookImage>? ebookImages = await getEbookImages(epubBook, css);

    final ebookChapters = getEbookChapter(
        epubBook.Chapters!, css ?? "", js ?? "", ebookImages ?? []);

    if (ebookChapters == null || ebookChapters.isEmpty) {
      state = EbookSatus.error;
      _bookStreamController.addError("empty");
      return false;
    }
    state = EbookSatus.success;
    pages = ebookChapters;
    bookPagesCount = pages!.fold<int>(
      0,
      (total, page) {
        if (page.subChapters == null) {
          return total + 1;
        } else {
          return total + page.subChapters!.length;
        }
      },
    );
    await configWebview();
    configPageController();
    currentChapter = 0;
    currentPage = 0;

    if (webController != null) {
      if (pages![initialpage ?? 0].subChapters != null) {
        launchWeb(pages![initialChapter ?? 0].subChapters![initialpage ?? 0],
            webController!);
      } else {
        launchWeb(pages![initialpage ?? 0], webController!);
      }
    }

    _bookStreamController.add(this);
    return true;
  }

  launchWeb(EpubPageEntity htmlContent, WebViewController controller) async {
    state = EbookSatus.loading;
    _bookStreamController.add(this);
    log(htmlContent.chapter.HtmlContent ?? "");
    controller.loadHtmlString(htmlContent.chapter.HtmlContent ?? "",
        baseUrl: "https://eduba");
  }

  Future<bool> back() async {
    if (webController != null && (await webController!.canGoBack())) {
      webController!.goBack();

      return false;
    }
    return true;
  }

  nextPage() {
    if (state != EbookSatus.success || webController == null) {
      return;
    }
    if (pages![currentChapter].subChapters != null) {
      if (currentPage < pages![currentChapter].subChapters!.length - 1) {
        currentPage++;
        launchWeb(
            pages![currentChapter].subChapters![currentPage], webController!);
      } else {
        nextChapter();
      }
    } else {
      nextChapter();
    }
  }

  nextChapter() {
    if (state != EbookSatus.success || webController == null) {
      return;
    }
    currentPage = 0;

    if (currentChapter < pages!.length - 1) {
      currentChapter++;
      if (pages![currentChapter].subChapters == null) {
        launchWeb(pages![currentChapter], webController!);
      } else {
        launchWeb(
            pages![currentChapter].subChapters![currentPage], webController!);
      }
    }
  }

  previosPage() {
    if (state != EbookSatus.success || webController == null) {
      return;
    }
    if (pages![currentChapter].subChapters != null) {
      if (currentPage > 0) {
        currentPage--;
        launchWeb(
            pages![currentChapter].subChapters![currentPage], webController!);
      } else {
        previosChapter();
      }
    } else {
      previosChapter();
    }
  }

  previosChapter() {
    if (state != EbookSatus.success || webController == null) {
      return;
    }

    if (currentChapter > 0) {
      currentChapter--;
      if (pages![currentChapter].subChapters == null) {
        launchWeb(pages![currentChapter], webController!);
      } else {
        currentPage = pages![currentChapter].subChapters!.length - 1;
        launchWeb(
            pages![currentChapter].subChapters![currentPage], webController!);
      }
    }
  }

  jumpTpPage({required int chapter, required int page}) {
    if (state != EbookSatus.success || webController == null) {
      return;
    }
    if (chapter < pages!.length) {
      currentChapter = chapter;
      currentPage = page;

      if (pages![chapter].subChapters == null) {
        launchWeb(pages![chapter], webController!);
        _bookStreamController.add(this);
        return;
      }

      if (pages![chapter].subChapters!.length > page) {
        launchWeb(pages![chapter].subChapters![page], webController!);
        _bookStreamController.add(this);
      }
    }

    _bookStreamController.add(this);
  }

  increezeFontSize() async {
    if (webController == null) {
      // log("book not init");
      return;
    }
    //log("book ====== init");
    await webController!.runJavaScript('''
        var body = document.body;
    var currentSize = window.getComputedStyle(body, null).getPropertyValue('font-size');
    var newSize = (parseFloat(currentSize) + 2) + "px"; 
    body.style.fontSize = newSize;
      ''');
    // int oldFontsize = extractIntFromPx(pageFontSize.toString());
    // if (oldFontsize == 0) {
    //   return;
    // }
    // log(oldFontsize.toString());
    // if (fontSize == 0) {
    //   fontSize = oldFontsize < 18 ? 18 : oldFontsize;
    // }
    // fontSize++;
    // webController!.runJavaScript(
    //   'document.body.style.fontSize = "${fontSize}px";', // Change the font size value as needed
    // );
  }

  decreezeFontSize() async {
    if (webController == null) {
      log("book not init");
      return;
    }
    // final pageFontSize = await webController!.runJavaScriptReturningResult('''
    //     var fontSize = window.getComputedStyle(document.body).fontSize;
    //     fontSize;
    //   ''');
    // int oldFontsize = extractIntFromPx(pageFontSize.toString());
    // if (oldFontsize == 0) {
    //   return;
    // }

    webController!.runJavaScript(
      '''    var body = document.body;
    var currentSize = window.getComputedStyle(body, null).getPropertyValue('font-size');
    var newSize = (parseFloat(currentSize) - 2) + "px"; // You can adjust the increment (2) as desired
    body.style.fontSize = newSize;''', // Change the font size value as needed
    );
  }

  Future<void> configWebview() async {
    late final PlatformWebViewControllerCreationParams params;

    params = const PlatformWebViewControllerCreationParams();

    webController = WebViewController.fromPlatformCreationParams(params);
    await webController!
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (a) {
            //log("loading==$a");
          },
          onPageStarted: (a) {
            //log("onPageStarted==$a");
          },
          onPageFinished: (String url) {
            // log("onPageFinished");

            state = EbookSatus.success;
            _bookStreamController.add(this);
            //pageController.jumpToPage(currentpage);
            // try {
            //   webController!.runJavaScript(pages!.first.js);
            // } catch (_) {}
            try {
              disblaPageCopy(webController!);
              webController!.getScrollPosition().then(
                  (value) => webController!.scrollBy(-(value.dx).toInt(), 0));
            } catch (_) {}
          },
        ),
      );
  }

  void configPageController() {
    pageController = PageController();
  }

  Future<num> searchAndNavigate(String searchText) async {
    if (webController != null) {
      final number = await webController!.runJavaScriptReturningResult('''
  var body = document.body;
            var query = '$searchText'
            var searchText = new RegExp("(" + query + ")(?!([^<]+)?>)", "gi");

            var innerHTML = body.innerHTML;
            var matches = innerHTML.match(searchText);

            if (matches) {


                innerHTML = innerHTML.replace(searchText, '<span  style="background-color: yellow;" class ="eduba_html_class">' + query + '</span>');


                body.innerHTML = innerHTML;


                var elements = document.querySelectorAll(".eduba_html_class");


                for (var i = 0; i < elements.length; i++) {
                    elements[i].className = "eduba_html_class_" + i;
                    if (i == 0) {
                        elements[i].
                            style = "background-color: yellow;"
                    } else {
                        elements[i].
                            style = "background-color: none;"
                    }

                }

                innerHTML = document.body.innerHTML;

            }
            var result = document.querySelector('span[class ="eduba_html_class_0"]');
            if (result) {
                result.scrollIntoView();

            }
     
  elements ? elements.length : 0;
    ''');
      log("number=$number");
      return number as num;
    }
    return 0;
  }

  Future<void> searchAndNavigateNext(int index, int count) async {
    if (webController != null) {
      await webController!.runJavaScript('''


        for (var i = 0; i < $count; i++) {
            var  result = document.querySelector('span[class ="eduba_html_class_'+i+'"]');

if(i==$index){
result.
          style="background-color: yellow;"
            result.scrollIntoView();
}else{
  result.
          style="background-color: none;"
}
  }
 
    ''');
      return;
      // log(result.toString());
    }
    return;
  }

  Future<void> clearSearch(int count) async {
    log("clear=$count");
    if (webController != null) {
      await webController!.runJavaScript('''


        for (var i = 0; i < $count; i++) {
            var  result = document.querySelector('span[class ="eduba_html_class_'+i+'"]');
            if(result){
result.className="eduba_html_class_-1";
  result.style="background-color: none;"
            }

 }

    ''');

      // log(result.toString());
    }
  }
}
