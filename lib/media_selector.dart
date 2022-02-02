import 'dart:async';

import 'package:flutter/services.dart';

class Media {
  String? thumbPath;
  String? path;
  String? cropPath;
  String? compressPath;
  int? width;
  int? height;
  MediaMode? mediaMode;
}

enum PictureMimeType { ofAll, ofImage, ofVideo }

enum MediaMode { image, video }

class MediaSelector {
  static const MethodChannel channel = MethodChannel('media_selector');

  static const List<String> list = [];

  static void color(String color) {
    channel.invokeMethod('color', {'color': color});
  }

  static Future<List<Media>> select(
      {PictureMimeType type = PictureMimeType.ofAll,
      int max = 1,
      int spanCount = 4,
      isCamera = true,
      bool enableCrop = false,
      bool compress = true,
      int ratioX = 1,
      int ratioY = 1,
      List<String> selectList = list}) async {
    int mimeType = 0;
    if (type == PictureMimeType.ofAll) {
      mimeType = 0;
    } else if (type == PictureMimeType.ofImage) {
      mimeType = 1;
    } else if (type == PictureMimeType.ofVideo) {
      mimeType = 2;
    }
    Map<String, dynamic> params = {
      'type': mimeType,
      'max': max,
      'spanCount': spanCount,
      'isCamera': isCamera,
      'enableCrop': enableCrop,
      'compress': compress,
      'ratioX': ratioX,
      'ratioY': ratioY,
      'selectList': selectList,
    };

    List<dynamic> paths = await channel.invokeMethod('select', params);
    List<Media> medias = [];
    for (var data in paths) {
      Media media = Media();
      media.path = data['path'];
      media.cropPath = data['cropPath'];
      media.compressPath = data['compressPath'];
      media.width = data['width'];
      media.height = data['height'];
      medias.add(media);
    }
    return medias;
  }

  static void previewPicture(List<String> selectList, int position) {
    channel.invokeMethod('preview_picture', {'selectList': selectList, 'position': position});
  }

  static void previewVideo(String? path) {
    channel.invokeMethod('preview_video', {'path': path});
  }

  static void clearCache(String path) {
    channel.invokeMethod('clear_cache');
  }
}
