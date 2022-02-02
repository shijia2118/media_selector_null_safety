package com.example.media_selector;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.luck.picture.lib.PictureSelector;

import java.lang.ref.WeakReference;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MediaSelectorPlugin implements FlutterPlugin, MethodCallHandler,ActivityAware {
  private MediaSelectorDelegate delegate ;
  private MethodChannel channel;
  private Activity mActivity;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "media_selector");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "color":
        delegate.color(call);
        break;
      case "select":
        delegate.select(call, result);
        break;
      case "preview_picture":
        List<String> selectList = call.argument("selectList");
        Integer position = call.argument("position");
        if(selectList!=null && position != null)
        delegate.previewPicture(selectList, position);
        break;
      case "preview_video":
        String path = call.argument("path");
        delegate.previewVideo(path);
        break;
      case "clear_cache":
        delegate.clearCache();
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    mActivity = binding.getActivity();
    delegate = new MediaSelectorDelegate(mActivity);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {
    mActivity = null;
  }
}
