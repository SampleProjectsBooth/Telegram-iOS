#import <UIKit/UIKit.h>

@class TGCameraPreviewView;
@class TGMenuSheetPallete;

@interface TGAttachmentCameraView : UIView

@property (nonatomic, copy) void (^pressed)(void);
@property (nonatomic, strong) TGMenuSheetPallete *pallete;

- (instancetype)initForSelfPortrait:(bool)selfPortrait;

@property (nonatomic, readonly) bool previewViewAttached;
- (void)detachPreviewView;
- (void)attachPreviewViewAnimated:(bool)animated;
- (void)willAttachPreviewView;

- (void)startPreview;
- (void)stopPreview;
- (void)resumePreview;
- (void)pausePreview;

- (void)setZoomedProgress:(CGFloat)progress;

- (TGCameraPreviewView *)previewView;

@end
