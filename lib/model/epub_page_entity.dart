import 'dart:io';

import 'package:epubx/epubx.dart';

class EpubPageEntity {
  EpubChapter chapter;
  List<EpubPageEntity>? subChapters;

  String css;
  int? pageCount;
  String js;
  List<EbookImage> ebookImages;
  EpubPageEntity(
      {required this.chapter,
      this.subChapters,
      required this.css,
      required this.js,
      this.pageCount,
      required this.ebookImages});
}

class EbookImage {
  String realName;
  String fileName;
  String path;
  String base64;
  File? file;
  EbookImage(
      {required this.realName,
      required this.fileName,
      required this.base64,
      required this.file,
      required this.path});
}

enum EbookSatus { init, error, success, finish, loading }
