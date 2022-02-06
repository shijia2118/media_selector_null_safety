#import "MediaSelectorPlugin.h"
#import "TZImagePickerController.h"
#import "TZImagePreviewController.h"

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define WEAKSELF __weak typeof(self) weakSelf = self;
#define STRONGSELF __strong typeof(self) strongSelf = weakSelf;

@interface MediaSelectorPlugin ()

@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) TZImagePickerController *imagePickerVc;

@property (strong, nonatomic) NSMutableDictionary *selectedAssetDic;
@property (strong, nonatomic) PHAsset *selectedVideoAsset;

// 保存属性，用于预览图片时候用
@property (strong, nonatomic) NSDictionary *argsMap;


@end

@implementation MediaSelectorPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"media_selector" binaryMessenger:[registrar messenger]];
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    MediaSelectorPlugin* instance = [[MediaSelectorPlugin alloc] initWithViewController:viewController];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        self.selectedAssetDic = @{}.mutableCopy;
        self.argsMap = @{};
        self.viewController = viewController;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"color" isEqualToString:call.method]) {
        NSDictionary *argsMap = call.arguments;
        NSString *colorString = argsMap[@"color"];  // #4CAB4B
        self.color = [self colorWithHexString:colorString];
    } else if ([@"select" isEqualToString:call.method]) {
        NSDictionary *argsMap = call.arguments;
        self.argsMap = argsMap;
        [self selectImageOrVideoWithResult:result];
    } else if ([@"preview_picture" isEqualToString:call.method]) {
        // 图片预览
        NSDictionary *argsMap = call.arguments;
        NSArray *imagePathArray = @[];
        if ([argsMap[@"selectList"] isKindOfClass:[NSArray class]]) {
            imagePathArray = argsMap[@"selectList"];
        }
        NSInteger index = [argsMap[@"position"] integerValue];
        if (imagePathArray.count == 0) {
            return;
        }
        [self previewImageWithImagePathArray:imagePathArray index:index];
    } else if ([@"preview_video" isEqualToString:call.method]) {
        // 视频预览
        NSDictionary *argsMap = call.arguments;
        NSString *path = argsMap[@"path"];
        if (path.length == 0) {
            return;
        }
        [self previewVideoWithVideoPath:path];
    } else if ([@"clear_cache" isEqualToString:call.method]) {
        [self clearCache];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

// 选择图片或者视频
- (void)selectImageOrVideoWithResult:(FlutterResult)result {
    [self createImagePickerController];
    // 是否裁剪
    BOOL enableCrop = [self.argsMap[@"enableCrop"] boolValue];
    // 是否压缩
    BOOL compress = [self.argsMap[@"compress"] boolValue];
    WEAKSELF
    // 视频
    [self.imagePickerVc setDidFinishPickingVideoHandle:^(UIImage *coverImage, PHAsset *asset) {
        STRONGSELF
        NSMutableArray *pathArray = @[].mutableCopy;
        // 保存当前选中的视频asset
        strongSelf.selectedVideoAsset = asset;
        // open this code to send video / 打开这段代码发送视频
        [[TZImageManager manager] getVideoOutputPathWithAsset:asset presetName:AVAssetExportPresetLowQuality success:^(NSString *outputPath) {
            // NSData *data = [NSData dataWithContentsOfFile:outputPath];
            NSLog(@"视频导出到本地完成,沙盒路径为:%@",outputPath);
            // Export completed, send video here, send by outputPath or NSData
            // 导出完成，在这里写上传代码，通过路径或者通过NSData上传
            
            // 将视频地址包装，回调给Flutter
            NSMutableDictionary *dic = @{}.mutableCopy;
            dic[@"path"] = outputPath;
            [pathArray addObject:dic];
            result(pathArray);
        } failure:^(NSString *errorMessage, NSError *error) {
            NSLog(@"视频导出失败:%@,error:%@",errorMessage, error);
        }];
    }];
    
    // 图片
    [self.imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL flag) {
        STRONGSELF
        NSMutableArray *pathArray = @[].mutableCopy;
        [photos enumerateObjectsUsingBlock:^(UIImage * _Nonnull subImage, NSUInteger idx, BOOL * _Nonnull stop) {
            NSData *imageData = UIImageJPEGRepresentation(subImage, 0.5);
            UIImage *newImage = [UIImage imageWithData:imageData];
            // 获取图片本地路径
            NSString *path = [strongSelf getImagePath:newImage withCompress:compress withImageName:[NSString stringWithFormat:@"/%@.png", strongSelf.currentTimeStr]];
            
            NSMutableDictionary *dic = @{}.mutableCopy;
            if(compress){
                dic[@"compressPath"] = path;
            }
            if(enableCrop){
                dic[@"cropPath"] = path;
            }
            dic[@"path"] = path;
            dic[@"width"] = [NSNumber numberWithInt:newImage.size.width];
            dic[@"height"] = [NSNumber numberWithInt:newImage.size.height];
            [pathArray addObject:dic];
            PHAsset *asset = assets[idx];
            strongSelf.selectedAssetDic[path] = asset;
        }];
        result(pathArray);
    }];
    [self.viewController presentViewController:self.imagePickerVc animated:YES completion:nil];
}

// 视频预览
- (void)previewVideoWithVideoPath: (NSString *)videoPath {
    TZVideoPlayerController *vc = [[TZVideoPlayerController alloc] init];
    TZAssetModel *model = [TZAssetModel modelWithAsset:self.selectedVideoAsset type:TZAssetModelMediaTypeVideo timeLength:@""];
    vc.model = model;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.viewController presentViewController:vc animated:YES completion:nil];
}

// 图片预览
- (void)previewImageWithImagePathArray:(NSArray *)imagePathArray index:(NSInteger)index {
    // 从本地获取图片并转成 UIImage 对象
    NSMutableArray *imageArray = @[].mutableCopy;
    [imagePathArray enumerateObjectsUsingBlock:^(NSString * _Nonnull imagePath, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        [imageArray addObject:image];
    }];
    
    // 这里使用新生成的一个controller，方便控制展示效果
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
    imagePickerVc.maxImagesCount = 1;
    imagePickerVc.showSelectBtn = NO;
    // 移除某些控件
    [imagePickerVc setPhotoPreviewPageDidLayoutSubviewsBlock:^(UICollectionView *collectionView, UIView *naviBar, UIButton *backButton, UIButton *selectButton, UILabel *indexLabel, UIView *toolBar, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel) {
        if (numberLabel) {
            [numberLabel removeFromSuperview];
            numberLabel = nil;
        }
        if (numberImageView) {
            [numberImageView removeFromSuperview];
            numberImageView = nil;
        }
        if (doneButton) {
            [doneButton removeFromSuperview];
            doneButton = nil;
        }
    }];
    
    // 图片预览控制器
    TZImagePreviewController *previewVc = [[TZImagePreviewController alloc] initWithPhotos:imageArray currentIndex:index tzImagePickerVc:imagePickerVc];
    [previewVc setBackButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
        
    }];
    [previewVc setDoneButtonClickBlock:^(NSArray *photos, BOOL isSelectOriginalPhoto) {
        
    }];
    previewVc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.viewController presentViewController:previewVc animated:YES completion:nil];
}

- (void)clearCache {
    // 清除图片缓存 （磁盘中的）
    NSString *tmpPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/"];
    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
}

// 获取图片本地路径
- (NSString *)getImagePath:(UIImage *)Image withCompress:(BOOL)compress withImageName:(NSString *)imageName {
    NSString * filePath = nil;
    NSData * data = nil;
    if (UIImagePNGRepresentation(Image) == nil) {
        if(compress){
            data = UIImageJPEGRepresentation(Image, 0.2);
        } else {
            data = UIImageJPEGRepresentation(Image, 0.5);
        }
    } else {
        data = UIImagePNGRepresentation(Image);
    }
    //图片保存的路径
    //这里将图片放在沙盒的documents文件夹中
    NSString *tmpPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/"];
    //文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //把刚刚图片转换的data对象拷贝至沙盒中
    [fileManager createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:nil];
    NSString * ImagePath = imageName;
    [fileManager createFileAtPath:[tmpPath stringByAppendingString:ImagePath] contents:data attributes:nil];
    //得到选择后沙盒中图片的完整路径
    filePath = [[NSString alloc]initWithFormat:@"%@%@", tmpPath, ImagePath];
    return filePath;
}

- (NSString *)currentTimeStr{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval time=[date timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
    return timeString;
}

// 创建pickerController并配置属性
- (void)createImagePickerController {
    NSInteger type = [self.argsMap[@"type"] integerValue];
    NSInteger max = [self.argsMap[@"max"] integerValue];
    BOOL isCamera = [self.argsMap[@"isCamera"] boolValue];
    BOOL enableCrop = [self.argsMap[@"enableCrop"] boolValue];
    //    BOOL compress = [self.argsMap[@"compress"] boolValue];
    NSInteger ratioX = [self.argsMap[@"ratioX"] integerValue];
    NSInteger ratioY = [self.argsMap[@"ratioY"] integerValue];
    NSArray *selectList = [NSArray arrayWithArray:self.argsMap[@"selectList"]];
    NSMutableArray *selectedAssets = @[].mutableCopy;
    
    [selectList enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        PHAsset *asset = self.selectedAssetDic[path];
        [selectedAssets addObject:asset];
    }];
    
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
    if(self.color != nil) {
        imagePickerVc.navigationBar.barTintColor = self.color;
    }
    imagePickerVc.allowPickingVideo = type != 1;
    imagePickerVc.allowPickingImage = type != 2;
    imagePickerVc.maxImagesCount = max;
    imagePickerVc.allowPickingOriginalPhoto = false;
//    imagePickerVc.allowTakePicture = isCamera;
    imagePickerVc.allowTakeVideo = NO;
    imagePickerVc.allowTakePicture = NO;
    imagePickerVc.allowPickingGif = false;
    imagePickerVc.allowPickingMultipleVideo = max != 1;
    imagePickerVc.allowCrop = enableCrop;
    imagePickerVc.scaleAspectFillCrop = true;
    imagePickerVc.selectedAssets = selectedAssets;
    NSInteger top = (SCREEN_HEIGHT - SCREEN_WIDTH * ratioY / ratioX) / 2;
    imagePickerVc.cropRect = CGRectMake(0, top, SCREEN_WIDTH, SCREEN_WIDTH * ratioY / ratioX);
    imagePickerVc.modalPresentationStyle = UIModalPresentationFullScreen;
    self.imagePickerVc = imagePickerVc;
}

- (UIColor *)colorWithHexString:(NSString *)stringToConvert {
    if (stringToConvert.length > 0) {
        NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
        if ([cString length] < 6) return [UIColor grayColor];
        
        // strip 0X if it appears
        if ([cString hasPrefix:@"0X"]) {
            cString = [cString substringFromIndex:2];
        }
        
        if ([cString hasPrefix:@"#"]) {
            cString = [cString substringFromIndex:1];
        }
        
        if ([cString length] != 6) {
            return [UIColor grayColor];
        }
        
        // Separate into r, g, b substrings
        NSRange range;
        range.location = 0;
        range.length = 2;
        NSString *rString = [cString substringWithRange:range];
        
        range.location = 2;
        NSString *gString = [cString substringWithRange:range];
        
        range.location = 4;
        NSString *bString = [cString substringWithRange:range];
        
        // Scan values
        unsigned int r, g, b;
        [[NSScanner scannerWithString:rString] scanHexInt:&r];
        [[NSScanner scannerWithString:gString] scanHexInt:&g];
        [[NSScanner scannerWithString:bString] scanHexInt:&b];
        
        return [UIColor colorWithRed:((float) r / 255.0f)
                               green:((float) g / 255.0f)
                                blue:((float) b / 255.0f)
                               alpha:1.0f];
    } else {
        return nil;
    }
}
@end
