
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import "Photo.h"
#import "ReviewViewController.h"
#import <MapKit/MapKit.h>
#import "ViewSavedPhotosViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#import "RootViewController.h"
#import "UIImagePickerControllerNoRotation.h"
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <math.h>
#import "UIImage+Extend.h"
#import "ProjectPickObserver.h"
#import "WDatePicker.h"
#import "CustomIOSAlertView.h"

#define RadiansToDegrees(radians)(radians * 180.0/M_PI)
#define DegreesToRadians(degrees)(degrees * M_PI / 180.0)


@interface MainViewController : BaseAppViewController<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, CLLocationManagerDelegate, UIAlertViewDelegate>
{
    NSMutableArray* lstObjsForTbPhotos;
    IBOutlet UITableView *tbPhotos;
    
    IBOutlet UIView *customCameraOverlayView3_5;
    IBOutlet UIView *customCameraOverlayView4;

    IBOutlet UIImageView *guide3_5;
    IBOutlet UIImageView *guide4;
    
    IBOutlet UILabel *lbGuide3_5;
    IBOutlet UILabel *lbGuide4;
    IBOutlet UILabel *flashMode4;
    IBOutlet UILabel *flashMode3_5;
    
    IBOutlet UIButton *btFlash;
    IBOutlet UIButton *btCameraDeivce;
    IBOutlet UIButton *btFlash4;
    IBOutlet UIButton *btCameraDeivce4;
    IBOutlet UIButton *btGuide3_5;
    IBOutlet UIButton *btGuide4;
    
    IBOutlet UIButton *btGotoPhotoAlbum;
    IBOutlet UIButton *btTakePhoto;
    IBOutlet UIButton *btCancel;

    IBOutlet UIButton *btGotoPhotoAlbum4;
    IBOutlet UIButton *btTakePhoto4;
    IBOutlet UIButton *btCancel4;
    
    IBOutlet UIButton *btN;
    IBOutlet UIButton *btS;
    IBOutlet UIButton *btE;
    IBOutlet UIButton *btW;
    IBOutlet UIButton *btP;
    
    IBOutlet UIButton *btN4;
    IBOutlet UIButton *btS4;
    IBOutlet UIButton *btE4;
    IBOutlet UIButton *btW4;
    IBOutlet UIButton *btP4;

    UIImage *thumbnail, *cellThumb;

    NSMutableArray *source;
    NSMutableArray *allSites;
    ExtImagePickerController* picker;
    Site *selectedSite;
    float GeoAngle;
    NSString *direction;
    int orientation;
    
    IBOutlet UIBarButtonItem* barBtReminder;
    
    IBOutlet UIView* vwNotes;
    UIToolbar* toolBarNotes;
    IBOutlet UITextField* txtAdhocSite;
    BOOL isTakingCamera; //NO if album
    NSMutableDictionary* imgPathPhotos;
    NSMutableArray* scheduledReuploads;
    
    IBOutlet UIToolbar* barBottom;
    
    BOOL isPhotoTaken;
    
    void(^onSelectSiteDone)(id);
    BOOL isCapturedPhoto;
    
    IBOutlet UIBarButtonItem* btMore;
    
    NSMutableDictionary* refPhotos;
    
    IBOutlet  UISlider    *sliderGuide4, *sliderGuide3_5;
    
    BOOL isAddForDirection;
    NSMutableDictionary* selectInfo;
    UIAlertView* alertAskDirection;
    IBOutlet    UIBarButtonItem *btnGuidePhoto;
    NSMutableArray  *arrPreloadSites;
    
    //redownload image
    NSDate* dateLastRedownloadImage;
    NSTimer* tmrRedownloadImage;
    
    NSDate* dateLastRefreshView;
    NSTimer* tmrRefreshView;

    //project pick
    ProjectPickObserver* prjPick;
    
    UIImage* guideImage;
    
    CustomIOSAlertView *directionAlertView;
}

@property(nonatomic, strong) UIImage *thumbnail;
@property(nonatomic, strong) NSMutableArray *uploading;
@property(nonatomic, strong) NSString *direction;
@property (nonatomic,copy) void(^onAskDirectionDone)(id);

@property (nonatomic,weak) ViewSavedPhotosViewController* controllerSavedPhotos;

@property (nonatomic,strong) NSMutableArray* lstPhotoNeedDownload;
@property (nonatomic,strong) NSMutableArray* lstPhotoBeingDownloaded;

-(IBAction) takePhoto:(id)sender;
-(IBAction) gotoPhotoAlbum:(id)sender;
-(IBAction) cancelCamera:(id)sender;
-(IBAction) changeCamera:(id)sender;
-(IBAction) changeFlashLightMode:(id)sender;
-(IBAction) changeGuide:(id)sender;
-(IBAction) selectDirection:(id)sender;
-(Site*)selectSite;
- (void) updateAllSites:(NSArray*)newAllSites;
- (void) selectSiteAndOnDone:(void(^)(id))onDone;

-(IBAction) wenTouchReminder:(id)sender;
-(IBAction) wenInfo:(id)sender;
-(IBAction) wenDonate:(id)sender;
-(IBAction) wenMore:(id)sender;

-(IBAction) guideAlphaChanged:(UISlider*) slider;
- (void) refresh;

- (void) alertForDirectionWithOnDone:(void(^)(id))onDone;
- (void) reloadOldDataFromServer:(NSArray*) arrAllowedSiteId;

- (void) redownloadImages;

- (void) refreshView;

@end
