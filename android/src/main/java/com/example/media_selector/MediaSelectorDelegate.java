package com.example.media_selector;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.util.Log;

import com.luck.picture.lib.PictureSelectionModel;
import com.luck.picture.lib.PictureSelector;
import com.luck.picture.lib.config.PictureConfig;
import com.luck.picture.lib.config.PictureMimeType;
import com.luck.picture.lib.entity.LocalMedia;
import com.luck.picture.lib.style.PictureParameterStyle;
import com.luck.picture.lib.tools.PictureFileUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;


public class MediaSelectorDelegate implements PluginRegistry.ActivityResultListener {
    private Activity activity;
    private MethodChannel.Result result;
    private boolean enableCrop, compress;
    private int type;
    private String color;

    MediaSelectorDelegate(Activity activity) {
        this.activity = activity;
    }

    public void color(MethodCall call) {
        color = call.argument("color");
    }

    public void select(MethodCall call, MethodChannel.Result result) {
        this.result = result;
        type = call.argument("type");
        int max = call.argument("max");
        int spanCount = call.argument("spanCount");
        boolean isCamera = call.argument("isCamera");
        enableCrop = call.argument("enableCrop");
        compress = call.argument("compress");
        int ratioX = call.argument("ratioX");
        int ratioY = call.argument("ratioY");
        List<String> selectList = call.argument("selectList");
        List<LocalMedia> list = new ArrayList<>();
        for (int i = 0; i < selectList.size(); i++) {
            LocalMedia localMedia = new LocalMedia();
            localMedia.setPath(selectList.get(i));
            list.add(localMedia);
        }
        PictureSelectionModel model = PictureSelector.create(activity)
                .openGallery(type)//全部.PictureMimeType.ofAll()、图片.ofImage()、视频.ofVideo()、音频.ofAudio()
                .loadImageEngine(GlideEngine.createGlideEngine())// 外部传入图片加载引擎，必传项
                .maxSelectNum(max)// 最大图片选择数量 int
                .minSelectNum(1)// 最小选择数量 int
                .imageSpanCount(spanCount)// 每行显示个数 int
                .selectionMode(max == 1 ? PictureConfig.SINGLE : PictureConfig.MULTIPLE)// 多选 or 单选 PictureConfig.MULTIPLE or PictureConfig.SINGLE
                .previewImage(true)// 是否可预览图片 true or false
                .isCamera(isCamera)// 是否显示拍照按钮 true or false
                .imageFormat(PictureMimeType.PNG)// 拍照保存图片格式后缀,默认jpeg
                .enableCrop(enableCrop)// 是否裁剪 true or false
                .compress(compress)// 是否压缩 true or false
                .selectionMedia(list);// 是否传入已选图片 List<LocalMedia> list
        if (color != null) {
            model.setPictureStyle(getStyle());// 动态自定义相册主题
        }
        if (enableCrop) {
            model.withAspectRatio(ratioX, ratioY);// int 裁剪比例 如16:9 3:2 3:4 1:1 可自定义
        }
        model.forResult(PictureConfig.CHOOSE_REQUEST);//结果回调onActivityResult code
    }

    private PictureParameterStyle getStyle() {
        // 相册主题
        PictureParameterStyle style = new PictureParameterStyle();
        // 相册状态栏背景色
        style.pictureStatusBarColor = Color.parseColor(color);
        // 相册列表标题栏背景色
        style.pictureTitleBarBackgroundColor = Color.parseColor(color);
        // 相册列表底部背景色
        style.pictureBottomBgColor = Color.parseColor("#FAFAFA");
        // 已选数量圆点背景样式
        GradientDrawable drawable = (GradientDrawable) activity.getResources().getDrawable(R.drawable.picture_num);
        drawable.setColor(Color.parseColor(color));
        style.pictureCheckNumBgStyle = R.drawable.picture_num;
        // 相册列表底下预览文字色值(预览按钮可点击时的色值)
        style.picturePreviewTextColor = Color.parseColor("#333333");
        // 相册列表已完成色值(已完成 可点击色值)
        style.pictureCompleteTextColor = Color.parseColor(color);
        // 预览界面底部背景色
        style.picturePreviewBottomBgColor = Color.parseColor("#FAFAFA");
        return style;
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode == Activity.RESULT_OK && requestCode == PictureConfig.CHOOSE_REQUEST && data != null && result != null) {
            List<LocalMedia> selectList = PictureSelector.obtainMultipleResult(data);
            final List<Map<String, Object>> list = new ArrayList<>();
            for (int i = 0; i < selectList.size(); i++) {
                LocalMedia media = selectList.get(i);
                Map<String, Object> map = new HashMap<>();
                if (type == PictureMimeType.ofImage()) {
                    map.put("path", selectList.get(i).getPath());
                } else {
                    map.put("path", media.getRealPath() == null ? selectList.get(i).getPath() : selectList.get(i).getRealPath());
                }
                map.put("cropPath", selectList.get(i).getCutPath());
                map.put("compressPath", selectList.get(i).getCompressPath());
                map.put("width", selectList.get(i).getWidth());
                map.put("height", selectList.get(i).getHeight());
                list.add(map);
            }
            result.success(list);
            return true;
        }
        return false;
    }

    public void previewPicture(List<String> selectList, int position) {
        List<LocalMedia> list = new ArrayList<>();
        for (int i = 0; i < selectList.size(); i++) {
            LocalMedia localMedia = new LocalMedia();
            localMedia.setPath(selectList.get(i));
            list.add(localMedia);
        }
        PictureSelectionModel model;
        if (color != null) {
            model = PictureSelector.create(activity).themeStyle(R.style.picture_default_style);
        } else {
            model = PictureSelector.create(activity).setPictureStyle(getStyle());
        }
        model.isNotPreviewDownload(true).loadImageEngine(GlideEngine.createGlideEngine()).openExternalPreview(position, list);
    }

    public void previewVideo(String path) {
        PictureSelectionModel model;
        if (color != null) {
            model = PictureSelector.create(activity).themeStyle(R.style.picture_default_style);
        } else {
            model = PictureSelector.create(activity).setPictureStyle(getStyle());
        }
        model.externalPictureVideo(path);
    }

    public void clearCache() {
        PictureFileUtils.deleteAllCacheDirFile(activity);
    }

}