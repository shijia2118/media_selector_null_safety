# media_selector

一款针对Android和IOS平台下的图片选择器，支持从相册获取图片、视频、拍照，支持裁剪(单图or多图裁剪)、压缩、主题自定义配置等功能，支持动态获取权限.

## 导入
```
dependencies:
  media_selector_null_safety: ^0.0.2
```

## 使用方法
1.设置主题颜色
MediaSelector.color('#449897');
2.预览所选图片
MediaSelector.previewPicture();
3.预览视频
MediaSelector.previewVideo();
4.选择视频
await MediaSelector.select(type: PictureMimeType.ofVideo);
5.选择图片
await MediaSelector.select(type: PictureMimeType.ofImage);



