//
//  MapViewController.h
//  Photomon
//
//  Created by ductran on 3/5/19.
//  Copyright © 2019 Appiphany. All rights reserved.
//

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
NS_ASSUME_NONNULL_BEGIN

@interface MapViewController : BaseAppViewController<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, MKMapViewDelegate>
{
    NSMutableArray* lstObjsForTbPhotos;
    
    NSMutableArray *source;
    NSMutableArray *allSites;
    Site *selectedSite;
    float GeoAngle;
    NSString *direction;
    int orientation;
    
    UIToolbar* toolBarNotes;
    NSMutableDictionary* imgPathPhotos;
    NSMutableArray* scheduledReuploads;
    
    IBOutlet UIToolbar* barBottom;
    
    BOOL isPhotoTaken;
    
    void(^onSelectSiteDone)(id);
    BOOL isCapturedPhoto;
    
    IBOutlet UIBarButtonItem* btMore;
    
    NSMutableDictionary* refPhotos;
    
    BOOL isAddForDirection;
    NSMutableDictionary* selectInfo;
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

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property(nonatomic, strong) UIImage *thumbnail;
@property(nonatomic, strong) NSMutableArray *uploading;
@property(nonatomic, strong) NSString *direction;
@property (nonatomic,copy) void(^onAskDirectionDone)(id);

@property (nonatomic,weak) ViewSavedPhotosViewController* controllerSavedPhotos;

@property (nonatomic,strong) NSMutableArray* lstPhotoNeedDownload;
@property (nonatomic,strong) NSMutableArray* lstPhotoBeingDownloaded;

-(Site*)selectSite;
- (void) updateAllSites:(NSArray*)newAllSites;
- (void) selectSiteAndOnDone:(void(^)(id))onDone;

-(IBAction) wenTouchReminder:(id)sender;
-(IBAction) wenInfo:(id)sender;
-(IBAction) wenDonate:(id)sender;
-(IBAction) wenMore:(id)sender;

- (void) refresh;

- (void) alertForDirectionWithOnDone:(void(^)(id))onDone;
- (void) reloadOldDataFromServer:(NSArray*) arrAllowedSiteId;

- (void) redownloadImages;

- (void) refreshView;
-(void) reloadTable;
@end

NS_ASSUME_NONNULL_END
