import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_selector/media_selector.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? path;
  Uint8List? uint8List;
  int max = 5;
  List<Media> list = [];
  List<String> selectList = [];

  @override
  void initState() {
    MediaSelector.color('#449897');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: list.length < max ? list.length + 2 : max + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: uint8List == null
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFDCDCDC)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                width: 70,
                                height: 70,
                                child: Column(
                                  children: <Widget>[
                                    const SizedBox(height: 8),
                                    Image.asset('images/media_video.png', width: 30, height: 30),
                                    const Text('添加视频', style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 12)),
                                  ],
                                ),
                              ),
                              onTap: selectVideo,
                            )
                          : GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: Stack(
                                  children: <Widget>[
                                    Image.memory(uint8List!, width: 70, height: 70, fit: BoxFit.cover),
                                    Container(
                                      alignment: Alignment.center,
                                      color: Colors.black.withOpacity(0.38),
                                      child: Image.asset('images/media_play.png', width: 22, height: 22),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => MediaSelector.previewVideo(path),
                            ),
                    ),
                    Visibility(
                      visible: uint8List != null,
                      child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: Image.asset('images/media_delete.png', width: 20, height: 20),
                            onTap: () {
                              setState(() {
                                path = null;
                                uint8List = null;
                              });
                            },
                          )),
                    ),
                  ],
                ),
              );
            }
            if (list.length < max && index == list.length + 1) {
              return SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDCDCDC)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          width: 70,
                          height: 70,
                          child: Column(
                            children: <Widget>[
                              const SizedBox(height: 8),
                              Image.asset('images/media_picture.png', width: 30, height: 30),
                              Text(list.isEmpty ? '选择图片' : '${list.length} / $max', style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12)),
                            ],
                          ),
                        ),
                        onTap: selectPictures,
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox(
              width: 78,
              height: 78,
              child: Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: GestureDetector(
                      child: Image.file(File(list[index - 1].path!), width: 70, height: 70, fit: BoxFit.cover),
                      onTap: () => MediaSelector.previewPicture(selectList, index - 1),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      child: Image.asset('images/media_delete.png', width: 20, height: 20),
                      onTap: () {
                        setState(() {
                          list.removeAt(index - 1);
                          selectList.removeAt(index - 1);
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  selectVideo() async {
    var list = await MediaSelector.select(type: PictureMimeType.ofVideo);
    path = list[0].path;
    uint8List = await VideoThumbnail.thumbnailData(
      video: path!,
      imageFormat: ImageFormat.PNG,
      maxWidth: 210,
      quality: 50,
    );
    setState(() {});
  }

  selectPictures() {
    MediaSelector.select(type: PictureMimeType.ofImage, max: max, compress: true, selectList: selectList).then((value) {
      if (kDebugMode) {
        print('>>>>>>compresspath>>>>$value');
      }

      list.clear();
      selectList.clear();
      setState(() {
        list.addAll(value);
        for (var media in list) {
          selectList.add(media.compressPath!);
        }
      });
    });
  }
}
