import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_selector/media_selector.dart';

class MediaSelectorCommon extends StatefulWidget {
  final bool isSelectVideo;
  final int max;
  final List<String>? savedImageUrlList;
  final String? savedVideoUrl;
  final void Function(String)? videoPath;
  final void Function(List<Media>)? changeMediaSelectorDataCallback;
  final void Function(List<String>)? changeSavedImageUrlCallback;

  const MediaSelectorCommon({
    Key? key,
    this.isSelectVideo = true, //是否选择视频
    this.videoPath, //视频路径回调
    this.savedVideoUrl, //已选视频
    this.changeMediaSelectorDataCallback,
    this.max = 5,
    this.savedImageUrlList,
    this.changeSavedImageUrlCallback,
  }) : super(key: key);

  @override
  MediaSelectorCommonState createState() => MediaSelectorCommonState();
}

class MediaSelectorCommonState extends State<MediaSelectorCommon> {
  String? path;
  Uint8List? bytes;
  List<String>? _savedImageUrlList = [];
  String _videoUrl = "";

  @override
  void initState() {
    if (widget.savedImageUrlList != null && widget.savedImageUrlList!.isNotEmpty) {
      _savedImageUrlList = widget.savedImageUrlList;
    }
    if (widget.savedVideoUrl != null && widget.savedVideoUrl!.isNotEmpty) {
      _videoUrl = widget.savedVideoUrl!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: (_savedImageUrlList?.length ?? 0) < widget.max ? (_savedImageUrlList?.length ?? 0) + (widget.isSelectVideo ? 2 : 1) : widget.max + (widget.isSelectVideo ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && widget.isSelectVideo) {
          return SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.bottomLeft,
                  child: _videoUrl.isEmpty
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFBDBDBD)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            width: 70,
                            height: 70,
                            child: Column(
                              children: <Widget>[
                                const SizedBox(height: 14),
                                Image.asset('images/media_video.png', width: 25, height: 16),
                                const SizedBox(height: 8),
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
                                // ImageNetwork(
                                //   OtherUtils.getVideoCoverByOss(_videoUrl),
                                //   size: 70,
                                //   circular: 4,
                                // ),
                                Container(
                                  alignment: Alignment.center,
                                  color: Colors.black.withOpacity(0.38),
                                  child: Image.asset('images/media_play.png', width: 22, height: 22),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            // MediaSelector.previewVideo(path);
                            // routePush(PreviewVideoPage(_videoUrl));
                          },
                        ),
                ),
                Visibility(
                  visible: _videoUrl.isNotEmpty,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Image.asset('images/media_delete.png', width: 20, height: 20),
                      onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode());
                        _videoUrl = "";
                        if (widget.videoPath != null) {
                          widget.videoPath!("");
                        }
                        setState(() {
                          // path = null;
                          // bytes = null;
                        });
                      },
                    ),
                  ),
                ),
                // Visibility(
                //   visible: bytes != null,
                //   child: Align(
                //       alignment: Alignment.topRight,
                //       child: GestureDetector(
                //         behavior: HitTestBehavior.opaque,
                //         child: ImageAsset('media_delete', width: 20, height: 20),
                //         onTap: () {
                //           FocusScope.of(context).requestFocus(FocusNode());
                //           setState(() {
                //             path = null;
                //             bytes = null;
                //           });
                //         },
                //       )),
                // ),
              ],
            ),
          );
        }
        if ((_savedImageUrlList?.length ?? 0) < widget.max && index == (_savedImageUrlList?.length ?? 0) + (widget.isSelectVideo ? 1 : 0)) {
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
                          const SizedBox(height: 12),
                          Image.asset('images/media_picture.png', width: 30, height: 30),
                          const SizedBox(height: 8),
                          Text(
                            (_savedImageUrlList?.length ?? 0) == 0 ? '选择图片' : '${_savedImageUrlList?.length} / ${widget.max}',
                            style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
                          ),
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
                child: ClipRRect(
                  child: Image.network(
                    _savedImageUrlList![index - (widget.isSelectVideo ? 1 : 0)],
                    fit: BoxFit.cover,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  child: Image.asset('images/media_delete.png', width: 20, height: 20),
                  onTap: () {
                    _savedImageUrlList?.removeAt(index - (widget.isSelectVideo ? 1 : 0));
                    if (widget.changeSavedImageUrlCallback != null) {
                      widget.changeSavedImageUrlCallback!(_savedImageUrlList!);
                    }
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 选择视频
  void selectVideo() async {
    var list = await MediaSelector.select(type: PictureMimeType.ofVideo, compress: false);
    path = list[0].path;

    // if (Platform.isAndroid) {
    //   ///设置视频大小不超过15秒
    //   final player = AudioPlayer();
    //   var duration = await player.setUrl(path);
    //   int s = duration.inSeconds;
    //   if (s > 15) {
    //     showToast("请选择小于15秒的视频！");
    //     return;
    //   }
    // }

    // LoadingHelper.showDialogLoading(context);
    // OssModel ossModel = OssModel();
    // try {
    //   String videoUrl = await ossModel.upload(path, mode: MediaMode.video);
    //   LoadingHelper.dismiss();
    //   if (OtherUtils.isStringNotEmpty(videoUrl)) {
    //     _videoUrl = videoUrl;
    //   }
    //   if (widget.videoPath != null) {
    //     widget.videoPath(videoUrl);
    //   }
    //   setState(() {});
    // } catch (e) {
    //   LoadingHelper.dismiss();
    //   showToast("视频上传失败，请重试");
    // }

    // bytes = await VideoThumbnail.thumbnailData(
    //   video: path,
    //   imageFormat: ImageFormat.PNG,
    //   maxWidth: 210,
    //   quality: 50,
    // );
    // setState(() {});
    // if (widget.videoPath != null) {
    //   widget.videoPath(path);
    // }
  }

  // selectPictures() {
  //   List<String> selectList = [];
  //   _list.forEach((media) {
  //     selectList.add(media.compressPath);
  //   });
  //   MediaSelector.select(type: PictureMimeType.ofImage, max: widget.max, compress: true, selectList: selectList).then((value) async {
  //     _list.clear();
  //     setState(() {
  //       _list.addAll(value);
  //       //回调
  //       if (widget.changeMediaSelectorDataCallback != null) {
  //         widget.changeMediaSelectorDataCallback(_list);
  //       }
  //     });
  //   });
  // }

  // 选择图片
  void selectPictures() {
    // List<String> selectList = [];
    // _localMediaList.forEach((media) {
    //   selectList.add(media.compressPath);
    // });
    // MediaSelector.select(type: PictureMimeType.ofImage, max: widget.max - _localMediaList.length, compress: true).then((value) async {
    // MediaSelector.select(type: PictureMimeType.ofImage, max: widget.max - (_savedImageUrlList?.length??0), compress: true).then((value) async {
    //   LoadingHelper.showDialogLoading(context);

    //   try {
    //     OssModel ossModel = OssModel();
    //     for (Media media in value) {
    //       // 压缩后的图
    //       // String path = media.compressPath;
    //       // 原图
    //       String? path = media.compressPath;
    //       String url = await ossModel.upload(path);
    //       _savedImageUrlList.add(url);
    //     }
    //     LoadingHelper.dismiss();
    //     if (widget.changeSavedImageUrlCallback != null) {
    //       widget.changeSavedImageUrlCallback(_savedImageUrlList);
    //     }
    //     setState(() {});
    //   } catch (e) {
    //     showToast("图片上传失败");
    //     LoadingHelper.dismiss();
    //   }

    //   // _localMediaList.addAll(value);
    //   //回调
    //   // if (widget.changeMediaSelectorDataCallback != null) {
    //   //   widget.changeMediaSelectorDataCallback(_localMediaList);
    //   // }
    // });
  }
}
