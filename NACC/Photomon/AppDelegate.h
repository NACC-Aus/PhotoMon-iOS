
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MainViewController.h"

#define NotifyAppDidActive                              @"NotifyAppDidActive"
#define NotifyUploadInBackground                        @"NotifyUploadInBackground"
#define NotifyAppWillChangeOrientation                  @"NotifyAppWillChangeOrientation"
#define NotifAppDidUpdateNewLocation                    @"NotifAppDidUpdateNewLocation"
#define NotifAppDidChangeNetworkType                    @"NotifAppDidChangeNetworkType"

@class CLLocation;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, UIAccelerometerDelegate>
{
    UIBackgroundTaskIdentifier bgTask;
    NSMutableArray *getSource;
    
    BOOL isInApp;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, readwrite) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, strong) NSMutableArray *getSource;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSString *direction;
@property   (nonatomic,strong) MainViewController  *mainViewController;

@property (nonatomic,strong) NetworkManager* mgrNetwork;
@property (nonatomic) int currentNetworkType;

@property (nonatomic) int osVersion;

@property (nonatomic,strong) CLLocation* newestUserLocation;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void) setForemostText:(NSString*)str;

@property (nonatomic,strong) NSMutableDictionary* mapPathImage;
- (UIImage*) loadImageOfFile:(NSString*)path;

@property (nonatomic,strong) NSMutableDictionary* mapAccessTokenToMainController;
- (UINavigationController*) loadMainControllerForAccessToken:(NSString*)token;

- (void) migrateDataWithOnDone:(void(^)(id))onDone onError:(void(^)(id))onError;

//local notification
- (void) enableLocalNotificationWithOnDone:(void(^)(id))onDone;

@end
