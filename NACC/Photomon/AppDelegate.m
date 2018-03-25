
#import "AppDelegate.h"
#import "RootViewController.h"

#import "ReminderViewController.h"
#import "AlertViewWithBlock.h"
#import "TimerWithBlock.h"

#import "ExifContainer.h"
#import "UIImage+Exif.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize locationManager, direction;
@synthesize bgTask;
@synthesize getSource;
@synthesize mainViewController = _mainViewController;

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    //os version
    self.osVersion = [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] firstObject] intValue];
    
    //init network manager
    self.mgrNetwork = [[NetworkManager alloc] init];
    __weak AppDelegate* weakSelf = self;
    
    self.mgrNetwork.onNetworkChange = ^(id type){
        if ([type hasPrefix:@"Wifi"]) weakSelf.currentNetworkType = NetworkTypeWifi;
        else if ([type hasPrefix:@"Cellular"]) weakSelf.currentNetworkType = NetworkTypeCellular;
        else weakSelf.currentNetworkType = NetworkTypeOffline;
        
        NLog(@"Network type changed");
        [[NSNotificationCenter defaultCenter] postNotificationName:NotifAppDidChangeNetworkType object:nil];
    };
    
    //location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;; // 100 m
    
    if (self.osVersion >= 8)
    {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    
    {
        [NSTimer timerWithInterval:1.0 andBlock:^(NSTimer* tmr){
            [self.locationManager stopUpdatingLocation];        
            [self.locationManager startUpdatingLocation];
        }];
    }
    
    //local
    [self enableLocalNotificationWithOnDone:nil];
    
    //direction init
    self.direction = @"Unknown";

    [self migrateDataWithOnDone:^(id b) {
        
        //for storing image in memory
        self.mapPathImage = [[NSMutableDictionary alloc] init];
        self.mapAccessTokenToMainController = [[NSMutableDictionary alloc] init];
        
        [[APIController shared] setupInit];
        [[Service shared] setupInit];
        
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        
        [def setBool:NO forKey:@"DID_NOTIFY"];
        [def synchronize];
        
        // Override point for customization after application launch.
        //    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        NSString *accessToken = [def objectForKey:@"AccessToken"];
        if (accessToken)
        {
            NavViewController *navi = (NavViewController*) [appDelegate loadMainControllerForAccessToken:accessToken];
            _mainViewController = [navi.viewControllers objectAtIndex:0];
            self.window.rootViewController = navi;            
        }
        else
        {
            RootViewController *rootViewController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];
            NavViewController *navi = [[NavViewController alloc] initWithRootViewController:rootViewController];
            navi.navigationBarHidden = YES;
            
            self.window.rootViewController = navi;
        }
        
    } onError:^(id err) {
        
        [[[UIAlertView alloc] initWithTitle:nil message:@"Migration failed, please contact developer for support" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        
    }];

    return YES;
}

-(BOOL)isMultitasking
{
    UIDevice* device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)])
        backgroundSupported = device.multitaskingSupported;
    return backgroundSupported;
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");
    
    self.newestUserLocation = [locations lastObject];
    
////TEST
//    NSString* s = [NSString stringWithFormat:@"%.8f,%.8f",self.newestUserLocation.coordinate.longitude,self.newestUserLocation.coordinate.latitude];
//    [self setForemostText:s];
////END TEST
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifAppDidUpdateNewLocation object:nil];
}

-(void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifyUploadInBackground object:nil];
    
    isInApp = NO;
}

- (void)scheduleAlarmForDate:(NSDate*)theDate
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    if ([def boolForKey:@"DID_NOTIFY"]) {
        return;
    }
//    if ([def boolForKey:@"DID_NOTIFY"]) {
    [def setBool:YES forKey:@"DID_NOTIFY"];
    [def synchronize];

    UIApplication* app = [UIApplication sharedApplication];
    NSArray*    oldNotifications = [app scheduledLocalNotifications];
    
    // Clear out the old notification before scheduling a new one.
    if ([oldNotifications count] > 0)
        [app cancelAllLocalNotifications];
    
    // Create a new notification.
    UILocalNotification* alarm = [[UILocalNotification alloc] init];
    if (alarm)
    {
        alarm.fireDate = theDate;
        alarm.timeZone = [NSTimeZone defaultTimeZone];
        alarm.repeatInterval = 0;
        alarm.soundName = @"alarmsound.caf";
        alarm.alertBody = @"Please open NACC to finish uploading images";
        
        [app scheduleLocalNotification:alarm];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you.
        // stopped or ending the task outright.

        for (Photo *it in getSource) {
            
            if (!it.isFinished)
            {
                [self scheduleAlarmForDate: nil];
                break;
            }
        }

        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the long-running task and return immediately.
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NLog(@"Async 1");

        // Do the work associated with the task, preferably in chunks.
        if ([application backgroundTimeRemaining] > 1.0)
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            
            getSource = [[NSMutableArray alloc] init];
            NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
            NSArray *arr = [def objectForKey:@"SavedPhotos"];
            if (arr) {
                for (NSString *it in arr) { //it is relative path
                    
                    NSString* fullPath = [documentsDirectory stringByAppendingPathComponent:it];
                    
                    id obj = [[Service shared] getDataOfRecordPath:it];
                    if (![[obj objectForKey:@"server"] isEqualToString:[APIController shared].server] ||
                        ![[obj objectForKey:@"user"] isEqualToString:[APIController shared].user]
                        ) continue;

                    NSArray *com = [it componentsSeparatedByString:@"_"];
                    NSArray *list = [[com objectAtIndex:0] componentsSeparatedByString:@"/"];

                    Photo *p = [[Photo alloc] init];
                    
                    p.siteID = [com objectAtIndex:1];
                    p.sID = [list objectAtIndex:list.count - 1];
                    p.direction = [com objectAtIndex:2];
                    p.date = [[com objectAtIndex:3] stringByReplacingOccurrencesOfString:@".jpg" withString:@""];
                    p.isFinished = [def boolForKey:it];
                    if([obj objectForKey:@"photoID"])
                    {
                        p.photoID = [obj objectForKey:@"photoID"];
                    }
                    
                    p.img =  [appDelegate loadImageOfFile:fullPath]; //[UIImage imageWithContentsOfFile:fullPath];
                    
                    p.imgPath = fullPath;
                    p.note = [obj objectForKey:@"note"];
                    
                    [getSource addObject:p];
                }
            }
            
            //start upload
            for (Photo *p in getSource)
            {
                if (p.isUploading) continue;
                if (!p.isFinished)
                {
                    __block APIController *api = [APIController shared];
                    api.photo = p;
                    //NSLog(@"\n=================================================START UPLOAD IN BACKGROUND=================================================: %@\n", api.photo.imgPath);                                
                    CGFloat compression = 0.5f;
                    //NSLog(@"\nImage size: %@\n", NSStringFromCGSize(p.img.size));
                    
                    ExifContainer *container = [[ExifContainer alloc] init];
                    [container addCreationDate:[NSDate date]];
                    [container addLocation:appDelegate.locationManager.location];
                    
                    NSData *data = UIImageJPEGRepresentation(p.img, compression);
                    
                    UIImage* imgWithExif = [UIImage imageWithData:data];
                    data = [imgWithExif addExif:container];
                    
                    p.isUploading = YES;
                    
                    id d = [[Service shared] getDataOfRecordPath:[p.imgPath lastPathComponent]];
                    NSString* sDate = [d objectForKey:@"created_at"];
                    NSString* note = [d objectForKey:@"note"];
                    
                    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:p,@"Photo", nil];
                    
                    NSString *accessToken = [def objectForKey:@"AccessToken"];
                    if (!accessToken) continue;
                    NSString* imgPath = p.imgPath;
                    NSString* idImg = [p.imgPath lastPathComponent];
                    
                    [api uploadPhoto:data withInfo:info andCreatedAt:sDate andNote:note andDirection:p.direction andSiteID:p.sID andUpdateBlock:^(id back)
                     {
                         float progress = [[back objectAtIndex:0] floatValue];

                         //NSLog(@"\nprogress: %0.2f\n", progress);
                         dispatch_async(dispatch_get_main_queue(), ^{
                             if (progress >= 1.0f)
                             {
                                 NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
                                 api.photo.isFinished = YES;
                                 [def setBool:YES forKey:[api.photo.imgPath lastPathComponent]];
                                 [def synchronize];
                                 //NSLog(@"\n=================================================FINISHED=================================================: %@\n", api.photo.imgPath);
                                 
                                 id response = [back objectAtIndex:1];
                                 id obj2 = [[Service shared] getDataOfRecordPath:idImg];
                                 [obj2 setObject:[response objectForKey:@"ID"] forKey:@"photoID"];
                                 [[Service shared] updateRecordPath:idImg andData:obj2];
                             }
                         });
                     } andBackground:YES];
                }
            }
            
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [[ReminderViewController shared] updateReminder];
    isInApp = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifyAppDidActive object:nil];
    
    //force start update
    [self.locationManager startUpdatingLocation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NACC" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"NACC.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void) setForemostText:(NSString*)str
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");
    
    UIView* rootView = self.window;
    
    UILabel* lb = (UILabel*) [rootView viewWithTag:1777];
    if (!lb)
    {
        lb = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 320, 20)];
        lb.textColor = [UIColor blackColor];
        lb.font = [UIFont systemFontOfSize:8];
        lb.textAlignment = NSTextAlignmentLeft;
        lb.backgroundColor = [UIColor yellowColor];
        lb.tag = 1777;
        [rootView addSubview:lb];
    }

    if (str)
    {
        lb.hidden = NO;
        lb.text = str;
        [NSTimer timerWithTimeout:0.3 andBlock:^(NSTimer* tmr){
            [rootView bringSubviewToFront:lb];
        }];
    }
    else
    {
        lb.hidden = YES;
    }
    
}

- (UIImage*) loadImageOfFile:(NSString*)path
{
    UIImage* img = [self.mapPathImage objectForKey:path];
    if (!img)
    {
        img = [UIImage imageWithContentsOfFile:path];
        if (img)
        {
            RUN_ON_MAIN_QUEUE(^{
                [self.mapPathImage setObject:img forKey:path];            
            });
        }
    }
    return img;
}

- (UINavigationController*) loadMainControllerForAccessToken:(NSString*)token
{
    UINavigationController* nav = [self.mapAccessTokenToMainController objectForKey:token];
    if (!nav)
    {
        MainViewController *mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
        NavViewController *navi = [[NavViewController alloc] initWithRootViewController:mainViewController];
        nav = navi;
        
        [self.mapAccessTokenToMainController setObject:nav forKey:token];
    }
    
     [[APIController shared] loadProjects: NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[APIController shared] loadProjects: YES];
    });

    return nav;
}

- (void) migrateDataWithOnDone:(void(^)(id))onDone onError:(void(^)(id))onError
{
//    NSDictionary* allPrefs = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    
    //detect sign to migrate
    NSString* storageVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"storage-version"];
    if ([storageVersion isKindOfClass:[NSString class]] && [storageVersion isEqualToString:@"2.0"])
    {
        if (onDone) onDone(nil);
        return;
    }
    
    NSError* err;
    
    //move all files under tmp to Documents/Downloadeds
    {
        NSString* folderTmp = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
        NSString* folderDownloaded = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Downloadeds"];
    
        if (![[NSFileManager defaultManager] fileExistsAtPath:folderDownloaded])
        {
            [[NSFileManager defaultManager] moveItemAtPath:folderTmp toPath:folderDownloaded error:&err];
            [[NSFileManager defaultManager] createDirectoryAtPath:folderTmp withIntermediateDirectories:YES attributes:nil error:&err];
        }
    }
    
    //fix nsuserdefaults
    {
        NSDictionary* allPrefs = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
        NSArray* allKeys = [allPrefs allKeys];
        
        //savedphotos
        NSArray* savedPhotos = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedPhotos"];
        NSMutableArray* newSavedPhotos = [NSMutableArray array];
        for (NSString* s in savedPhotos)
        {
            [newSavedPhotos addObject:[s lastPathComponent]];
        }
        [[NSUserDefaults standardUserDefaults] setObject:newSavedPhotos forKey:@"SavedPhotos"];
        
        //guide marks, download marks
        for (NSString* key in allKeys)
        {
            if ([key hasPrefix:@"guide:"])
            {
                NSString* newKey = [NSString stringWithFormat:@"guide:%@",[[key substringFromIndex:6] lastPathComponent]];
                
                id obj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
                
                [[NSUserDefaults standardUserDefaults] setObject:obj forKey:newKey];
            }
            else
            {
                if ([key hasPrefix:@"/var/"])
                {
                    NSString* newKey = [key lastPathComponent];
                    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:obj forKey:newKey];
                }
            }
        }
        
        //guide picture
        {
            NSString* value = [[NSUserDefaults standardUserDefaults] objectForKey:@"GuidePicture"];
            [[NSUserDefaults standardUserDefaults] setObject:[value lastPathComponent] forKey:@"GuidePicture"];
        }
        
        //guide photos
        {
            NSArray* guidePhotos = [[NSUserDefaults standardUserDefaults] objectForKey:@"GuidePhotos"];
            NSMutableArray* newGuidePhotos = [NSMutableArray array];
            for (id d in guidePhotos)
            {
                NSMutableDictionary* md = [NSMutableDictionary dictionaryWithDictionary:d];
                [md setObject:[d objectForKey:@"ImageUrl"] forKey:@"ImagePath"];
                [md setObject:[[d objectForKey:@"ImageUrl"] stringByAppendingString:@"_thumb"] forKey:@"ThumbPath"];
                
                [newGuidePhotos addObject:md];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:newGuidePhotos forKey:@"GuidePhotos"];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:@"2.0" forKey:@"storage-version"];

        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    //fix db
    {
        NSString* path = [@"~/Documents/db" stringByExpandingTildeInPath];
        
        NSData* data = [NSData dataWithContentsOfFile:path];
        if (data)
        {
            NSMutableDictionary* oldDB = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments|NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&err];
            NSMutableDictionary* newDB = [NSMutableDictionary dictionary];
            for (NSString* key in [oldDB allKeys])
            {
                [newDB setObject:[oldDB objectForKey:key]  forKey:[key lastPathComponent]];
            }
            
            data = [NSJSONSerialization dataWithJSONObject:newDB options:NSJSONWritingPrettyPrinted error:&err];
            [data writeToFile:path atomically:YES];
        }
    }
    
    //done
    if (onDone) onDone(nil);
}

- (void) enableLocalNotificationWithOnDone:(void(^)(id))onDone
{
    if (self.osVersion >= 8.0)
    {

        UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        if (grantedSettings.types == UIUserNotificationTypeNone)
        {
            NLog(@"No permiossion granted");
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
        }
    }
    else
    {
        
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if (![notification.alertBody hasPrefix:@"Reminder"]) return;
    
    if (!isInApp) return;
    
    DLog(@"Dismiss 1");
    [[ReminderViewController shared].currentReminderAlert dismissWithClickedButtonIndex:0 animated:NO];
    
    [ReminderViewController shared].currentReminderAlert = [UIAlertView alertViewTitle:@"Notification" andMsg:notification.alertBody onOK:^{
    }];
    
    [[ReminderViewController shared] updateReminder];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application  supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskAll;
}

- (void)application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration
{
    NSLog(@"WILL CHANGE ORIENTATION TO %ld",newStatusBarOrientation);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifyAppWillChangeOrientation object:[NSNumber numberWithInt:newStatusBarOrientation]];
}

@end
