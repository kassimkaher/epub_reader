import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:epub_reader/model/epub_page_entity.dart';
import 'package:epubx/epubx.dart';
import 'package:path_provider/path_provider.dart';

import 'package:html/parser.dart' as htmlParser;
import 'package:webview_flutter/webview_flutter.dart';

Future<List<EbookImage>?> getEbookImages(
    EpubBook epubBook, String? cssStyle) async {
  if (epubBook.Content == null || epubBook.Content?.Images == null) {
    return null;
  }

  List<EbookImage> ebookImages = [];
  var tempDir = await getTemporaryDirectory();

  for (final element in epubBook.Content!.Images!.entries) {
    if (element.value.Content != null) {
      final fullPath = "${tempDir.path}/${element.key.split("/").last}";
      final file = File(fullPath);
      await file.create();

      await file.writeAsBytes(element.value.Content!);
      var image64 = base64Encode(element.value.Content!);
      image64 = image64.contains("data:image/png;base64")
          ? image64
          : "data:image/png;base64,$image64";

      cssStyle = replaceBackgroundImageWithBase64(
          cssString: cssStyle!,
          propertyName: 'background-image',
          condition: element.value.FileName!.split("/").last,
          newValue: image64);
      cssStyle = replaceBackgroundImageWithBase64(
          cssString: cssStyle,
          propertyName: 'background',
          condition: element.value.FileName!.split("/").last,
          newValue: image64);

      ebookImages.add(EbookImage(
        realName: element.key,
        fileName: element.key.split("/").last,
        base64: image64,
        file: file,
        path: fullPath,
      ));
    }
  }

  return ebookImages;
}

String? getEbookCss(EpubBook epubBook) {
  if (epubBook.Content == null || epubBook.Content!.Css == null) {
    return null;
  }
  String cssStyle = "";

  epubBook.Content!.Css?.entries.forEach((element) {
    cssStyle = "$cssStyle${element.value.Content ?? ""}\n";
  });
  return cssStyle;
}

List<EpubTextContentFile>? getEbookHTML(EpubBook epubBook) {
  List<EpubTextContentFile> pages = [];
  if (epubBook.Content == null || epubBook.Content!.Html == null) {
    return null;
  }

  epubBook.Content!.Html?.entries.forEach((element) {
    pages.add(element.value);
  });
  return pages;
}

String? getEbookJs(EpubBook epubBook) {
  if (epubBook.Content == null || epubBook.Content!.Js == null) {
    return null;
  }
  String js = "";

  epubBook.Content!.Js?.entries.forEach((element) {
    js = "$js${element.value.Content ?? ""}\n";
  });
  return js;
}

List<EpubPageEntity>? getEbookChapterold(
    EpubBook epubBook, String css, String js, List<EbookImage> ebookImages) {
  if (epubBook.Content == null || epubBook.Chapters == null) {
    return null;
  }
  List<EpubPageEntity> ebookChapters = [];
  for (var element in epubBook.Content!.Html!.entries!) {
    var chapter = EpubChapter();
    chapter.HtmlContent = element.value.Content;
    chapter.Title = element.key;
    var htmlData = replaceImageSrc(element.value.Content ?? "", ebookImages);

    htmlData = htmlData.replaceAll("<head>", ''' 
    <head>
    <meta name="viewport" content="width=device-width, initial-scale=1 shrink-to-fit=no"">
    <style>
    img {
    pointer-events: none;
}
    $css
    </style>
    <script>
    $js
    </script>
    ''');

    ebookChapters.add(EpubPageEntity(
        chapter: chapter, css: css, js: js, ebookImages: ebookImages));
  }
  return ebookChapters;
}

List<EpubPageEntity>? getEbookChapter(List<EpubChapter> epubBook, String css,
    String js, List<EbookImage> ebookImages) {
  List<EpubPageEntity> ebookChapters = [];
  for (var element in epubBook) {
    if (element.SubChapters!.isNotEmpty) {
      final subChapter =
          getEbookChapter(element.SubChapters!, css, js, ebookImages);

      ebookChapters.add(EpubPageEntity(
          chapter: element,
          subChapters: subChapter,
          pageCount: subChapter!.length,
          css: css,
          js: js,
          ebookImages: ebookImages));
    } else {
      var htmlData = replaceImageSrc(element.HtmlContent ?? "", ebookImages);

      htmlData = htmlData.replaceAll("<head>", ''' 
    <head>
    <meta name="viewport" content="width=device-width, initial-scale=1 shrink-to-fit=no"">
    <style>
    img {
    pointer-events: none;
}
    $css
    </style>
    <script>
    $js
    </script>
    ''');
      element.HtmlContent = '<!doctype html>$htmlData';

      ebookChapters.add(EpubPageEntity(
          chapter: element, css: css, js: js, ebookImages: ebookImages));
    }
  }
  return ebookChapters;
}

String replaceImageSrc(String htmlString, List<EbookImage> images) {
  final document = htmlParser.parse(htmlString);
  final imgElements = document.querySelectorAll('img');

  for (final imgElement in imgElements) {
    final srcAttribute = imgElement.attributes['src'];

    if (srcAttribute != null) {
      final index = images.indexWhere(
          (element) => element.fileName == srcAttribute.split("/").last);

      if (index == -1) {
        return htmlString;
      }

      imgElement.attributes['src'] = images[index].base64;
    }
  }
  // log(document.outerHtml);
  return document.outerHtml;
}

String replaceBackgroundImageWithBase64(
    {required String cssString,
    required String propertyName,
    required String condition,
    required String newValue}) {
  // Define a regular expression pattern to match the property
  final pattern = RegExp('$propertyName\\s*:\\s*([^;]+);');

  // Replace the old property value with the new value
  final updatedCssString = cssString.replaceAllMapped(pattern, (match) {
    var currentValue = match.group(1); // Extract the current property value

    if (currentValue!.contains("url")) {
      currentValue = currentValue.replaceAll("'", "");
      currentValue = currentValue.replaceAll("\"", "");
      currentValue = currentValue.replaceAll("(", "");
      currentValue = currentValue.replaceAll(")", "");
      currentValue = currentValue.replaceAll("url", "");
      currentValue = currentValue.split("/").last;
      if (currentValue == condition) {
        return '$propertyName: url(\'$newValue\');'; // Replace with the new value
      }
      return match.group(0)!;
    } else {
      return match.group(0)!;
    }
  });

  return updatedCssString;
}

int extractIntFromPx(String size) {
  final RegExp regex = RegExp(r'(\d+)px');
  final match = regex.firstMatch(size);
  if (match != null) {
    final value = match.group(1);
    return int.tryParse(value ?? '0') ?? 0;
  }
  return 0; // Default value if no match is found
}

disblaPageCopy(WebViewController controller) {
  controller.runJavaScript("""
            document.documentElement.style.userSelect = 'none';
            document.documentElement.style.webkitUserSelect = 'none';
            document.documentElement.style.MozUserSelect = 'none';
        
          """);
}
