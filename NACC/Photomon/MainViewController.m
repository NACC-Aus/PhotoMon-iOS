
#import "AdhocSitesViewController.h"
#import "MainViewController.h"
#import "ReminderViewController.h"
#import "AlertViewWithBlock.h"
#import "TimerWithBlock.h"
#import "InfoViewController.h"
#import "AppDelegate.h"
#import "DonateViewController.h"
#import "UIImage+Resize.h"
#import "DownloadViewController.h"
#import "SettingViewController.h"
#import "ExifContainer.h"
#import "UIImage+Exif.h"
#import "NSURLConnection+Wrapper.h"

@interface PhotoCell : UITableViewCell
{
    UIProgressView *progress;
}

@property(nonatomic, strong) UIProgressView *progress;

@end

@implementation PhotoCell

@synthesize progress;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{ 
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        progress = [[UIProgressView alloc] init];
        [self.contentView addSubview: progress];
        progress.progress = 0.0f;
    }
    return self;
}

-(id)viewWithClass:(Class)class
{
    for (id it in self.subviews) {
        if ([it isKindOfClass:class])
        {
            return it;
        }
    }
    return nil;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.textLabel.width = 230;
    
    NSString* s = self.textLabel.text;
    CGSize maximumSize = CGSizeMake(self.textLabel.frame.size.width, 9999);
    CGSize sz = [s sizeWithFont:self.textLabel.font
              constrainedToSize:maximumSize
                  lineBreakMode:NSLineBreakByTruncatingTail];
    if (sz.height > 22)
        self.textLabel.numberOfLines = 2;
    else
        self.textLabel.numberOfLines = 1;
    
    float ll = 5;
    float scale = 50.0/self.imageView.image.size.width;
    self.imageView.width = 50;
    if (self.imageView.image) {
        self.imageView.height = self.imageView.image.size.height*scale;
    }
    else
        self.imageView.height = 0;
    self.imageView.centerY = self.height/2.0;
    self.imageView.left = ll;
    self.textLabel.left = self.imageView.width + 10 + ll;
    self.detailTextLabel.left = self.imageView.width + 10 + ll;
    self.detailTextLabel.width = 245;
    self.detailTextLabel.backgroundColor = self.textLabel.backgroundColor = [UIColor clearColor];
    progress.left = self.detailTextLabel.left;
    progress.top = self.detailTextLabel.top + self.detailTextLabel.height + 5;
    progress.width = 240;
    self.contentView.width = self.width;
    
    if (!progress.isHidden)
    {
        self.textLabel.top = self.textLabel.top - 8;
        self.detailTextLabel.top = self.detailTextLabel.top - 8;
        progress.top = progress.top - 8;
    }

}

@end

@interface MainViewController ()
- (void) reuploadFailedPhoto:(Photo*)p;

@end

@implementation MainViewController

@synthesize direction, uploading, thumbnail;


-(void)showDirection:(BOOL)isShow
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");
    
    isShow = !isShow;
    btS.hidden = btS4.hidden = isShow;
    btN.hidden = btN4.hidden = isShow;
    btE.hidden = btE4.hidden = isShow;
    btW.hidden = btW4.hidden = isShow;
}

-(NSString*)getDirection:(NSString*)ss
{
    if ([ss isEqualToString:@"N"]) {
        return @"North";
    }else if ([ss isEqualToString:@"S"]) {
        return @"South";
    }else if ([ss isEqualToString:@"E"]) {
        return @"East";
    }else if ([ss isEqualToString:@"W"]) {
        return @"West";
    }
    else if ([ss isEqualToString:@"P"])
    {
        return @"Photo Point";
    }
    
    return @"Unknown";
}

-(void)setSelectedDirection:(UIButton*)bt
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    NSArray *arr = @[btS, btS4, btN, btN4, btE, btE4, btW, btW4];
    for (UIButton *it in arr) {
        [it setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    if (bt == btN || bt == btN4) {
        [btN setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [btN4 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
    
    if (bt == btE || bt == btE4) {
        [btE setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [btE4 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
    
    if (bt == btS || bt == btS4) {
        [btS setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [btS4 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }

    
    if (bt == btW || bt == btW4) {
        [btW setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [btW4 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
}

-(IBAction)selectDirection:(UIButton*)sender
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    [self setSelectedDirection: sender];
    
    NSString* dir = nil;
    if ([sender isKindOfClass:[NSString class]])
    {
        dir = (NSString*)sender;
    }
    else
    {
        dir = [sender titleForState:UIControlStateNormal];
    }
    
    self.direction = [self getDirection: dir];
    AppDelegate *del = appDelegate;
    del.direction = self.direction;
    
    Site *site= [self selectSite];
    BOOL isAvailable = YES;
    
    if ([[APIController shared] checkIfDemo])
    {
        isAvailable = NO;
        if (site)
        {
            if (site.distance < [Service shared].minAdHocDistance)
            {
                isAvailable = YES;
            }
        }
    }
    
    if (!isAvailable)
    {
        sliderGuide3_5.hidden = sliderGuide4.hidden = YES;
        guide3_5.image = guide4.image = nil;
        guide3_5.hidden = guide4.hidden = YES;
        lbGuide3_5.text = lbGuide4.text = @"No Guide";
        btGuide3_5.userInteractionEnabled = btGuide4.userInteractionEnabled = NO;
        return;
    }

    //NSLog(@"\nDirection: %@\n", self.direction);
    UIImage *img = nil;
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *imgName = [NSString stringWithFormat:@"%@_%@.jpg", site.ID, del.direction];
        NSString *saveImagePath = [documentsDirectory stringByAppendingPathComponent:imgName];
        img = [appDelegate loadImageOfFile:saveImagePath]; // [UIImage imageWithContentsOfFile:saveImagePath];
    }
    
    if (!img && ![[NSUserDefaults standardUserDefaults] objectForKey:@"Demo"])
    {
        // try to search in guide
        NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
        NSArray *guidePhotos = [userDefault objectForKey:@"GuidePhotos"];
        if (guidePhotos) {
            for (NSMutableDictionary    *dict in guidePhotos) {
                DLog(@"veirfy direction : %@",[dict objectForKey:@"Direction"]);
                if ([[[dict objectForKey:@"Direction"] uppercaseString] isEqualToString:[self.direction uppercaseString]]) {
                    if (![[dict objectForKey:@"IsGuide"] boolValue] || ![[dict objectForKey:@"SiteId"] isEqualToString:site.ID]) {
                        continue;
                    }

                    NSString* imgPath = [Downloader storagePathForURL:[dict objectForKey:@"ImagePath"]];
                    img = [appDelegate loadImageOfFile:imgPath];// [UIImage imageWithContentsOfFile:imgPath];
                    break;
                }
            }
        }
    }
    
    if (img)
    {
        NLog(@"FOUND GUIDE IMAGE");
        
        sliderGuide3_5.hidden = sliderGuide4.hidden = NO;
        //NSLog(@"\nUpdate new guide photo 2......\n");
        btGuide3_5.userInteractionEnabled = btGuide4.userInteractionEnabled = YES;
        guide3_5.hidden = guide4.hidden = NO;
        lbGuide3_5.text = lbGuide4.text = @"Guide On";
        guide3_5.image = guide4.image = img;
        UIImage *img = guide3_5.image;
        if (img) {
            guideImage = img;
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
                float scale = [UIScreen mainScreen].bounds.size.width/img.size.width;
                guide3_5.width = guide4.width = img.size.width*scale;
                guide3_5.height = guide4.height = img.size.height*scale;
                guide3_5.left = guide4.left = 0;
                guide3_5.top = ([UIScreen mainScreen].bounds.size.height - 55 - guide3_5.height)/2;
                guide4.top = ([UIScreen mainScreen].bounds.size.height - 113 - guide4.height)/2;
            }else
            {
                UIView *container1 = [btCameraDeivce superview];
                UIView *container2 = [btCameraDeivce4 superview];
                
                container1.transform = CGAffineTransformIdentity;
                container2.transform = CGAffineTransformIdentity;
                guide3_5.transform = CGAffineTransformIdentity;
                guide4.transform = CGAffineTransformIdentity;
                
                float scale = [UIScreen mainScreen].bounds.size.width/img.size.width;
                guide3_5.width = guide4.width = img.size.width*scale;
                guide3_5.height = guide4.height = img.size.height*scale;
                guide3_5.left = guide4.left = 0;
                guide3_5.top = ([UIScreen mainScreen].bounds.size.height - 55 - guide3_5.height)/2;
                guide4.top = ([UIScreen mainScreen].bounds.size.height - 113 - guide4.height)/2;
                
                float width = [UIScreen mainScreen].bounds.size.height - (([UIScreen mainScreen].bounds.size.height == 480) ? 55:113);
                scale = width/320.0;
                
                if (orientation == UIInterfaceOrientationLandscapeRight)
                {
                    //3.5
                    container1.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    container1.transform = CGAffineTransformTranslate(container1.transform, 180, -100);
                    guide3_5.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI/2.0), scale, scale);
                    
                    //4.0
                    container2.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    container2.transform = CGAffineTransformTranslate(container2.transform, 180, -100);
                    guide4.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI/2.0), scale, scale);
                    
                    btCancel.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    btTakePhoto.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    btGotoPhotoAlbum.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    
                    btCancel4.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    btTakePhoto4.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    btGotoPhotoAlbum4.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    
                    
                }else
                {
                    //3.5
                    container1.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    container1.transform = CGAffineTransformTranslate(container1.transform, -180, -100);
                    guide3_5.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI/2.0), scale, scale);
                    
                    //4.0
                    container2.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    container2.transform = CGAffineTransformTranslate(container2.transform, -180, -100);
                    guide4.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI/2.0), scale, scale);
                    
                    
                    btCancel.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    btTakePhoto.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    btGotoPhotoAlbum.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    
                    btCancel4.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    btTakePhoto4.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    btGotoPhotoAlbum4.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    
                }

            }
        }
    }
    else
    {
        sliderGuide3_5.hidden = sliderGuide4.hidden = YES;
        guide3_5.image = guide4.image = nil;
        guide3_5.hidden = guide4.hidden = YES;
        lbGuide3_5.text = lbGuide4.text = @"No Guide";
        btGuide3_5.userInteractionEnabled = btGuide4.userInteractionEnabled = NO;
        guideImage = nil;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Photomon";
        
        UIBarButtonItem* btAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPhoto:)];

        self.navigationItem.rightBarButtonItem = btAdd;
        
//        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonSystemItemAction target:self action:@selector(logout:)];
        
        UIImage* img = [[UIImage imageNamed:@"images/settings_icon.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIBarButtonItem* btSetting = [[UIBarButtonItem alloc] initWithImage:img  style:UIBarButtonItemStylePlain target:self action:@selector(onTouchNavItemSetting:)];
//        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonSystemItemAction target:self action:@selector(onDidTouchItemSetting:)];
        self.navigationItem.leftBarButtonItem = btSetting;
        
        prjPick = [[ProjectPickObserver alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifProjectsDidRefresh:) name:NotifProjectsDidRefresh object:nil];
        [self refreshView];
    }
    
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    if (alertView == alertAskDirection) return;
    
    if (alertView.tag == 999) {
        UIAlertView *noCompassAlert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"By uploading pictures using this app, the user acknowledges the right of the project partners to use those pictures for reasonable purposes" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noCompassAlert show];
        noCompassAlert.tag = 777;
        
        return;
    }
    else if(alertView.tag == 777)
    {
        
        UIAlertView *noCompassAlert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Photographs containing children must not be uploaded" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noCompassAlert show];
        
    }
    else if (alertView.tag == 31124) //adhoc site name
    {
        if (buttonIndex == 0) //cancel
        {
            [self onNoteCancel:nil];
        }
        else //done
        {
            txtAdhocSite.text = [alertView textFieldAtIndex:0].text;
            [self onNoteDone:nil];
        }
        
    }
    else if (alertView.tag == 772 )
    {
        if (buttonIndex == 1)
        {
    //        for (APIController *it in self.uploading)
    //        {
    //            if (!it.mainRequest.isFinished)
    //            {
    //                [it.mainRequest clearDelegatesAndCancel];
    //            }
    //        }
            
    //        self.uploading = nil;
            
            NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
            [def removeObjectForKey:@"AccessToken"];
            [def synchronize];
                        
            //out setting
            {
                [self.navigationController dismissViewControllerAnimated:NO completion:nil];
            }
            
                [tbPhotos setContentOffset:CGPointZero animated:NO];
                RootViewController *rootViewController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];
                NavViewController *navi = [[NavViewController alloc] initWithRootViewController:rootViewController];
                navi.navigationBarHidden = YES;
                appDelegate.window.rootViewController = navi;
//            }];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
    }
}

-(void)logout:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout" message:@"Are you sure you want to logout?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.tag = 772;
    [alert show];
}


- (UIImage*) fixOrientationOfImage:(UIImage *)img
{
    @autoreleasepool {
        // No-op if the orientation is already correct
        if (img.imageOrientation == UIImageOrientationUp)
        {
            return img;
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        CGAffineTransform transform = CGAffineTransformIdentity;
        
        switch (img.imageOrientation) {
            case UIImageOrientationDown:
            case UIImageOrientationDownMirrored:
                transform = CGAffineTransformTranslate(transform, img.size.width, img.size.height);
                transform = CGAffineTransformRotate(transform, M_PI);
                break;
                
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
                transform = CGAffineTransformTranslate(transform, img.size.width, 0);
                transform = CGAffineTransformRotate(transform, M_PI_2);
                break;
                
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                transform = CGAffineTransformTranslate(transform, 0, img.size.height);
                transform = CGAffineTransformRotate(transform, -M_PI_2);
                break;
            case UIImageOrientationUp:
            case UIImageOrientationUpMirrored:
                break;
        }
        
        switch (img.imageOrientation) {
            case UIImageOrientationUpMirrored:
            case UIImageOrientationDownMirrored:
                transform = CGAffineTransformTranslate(transform, img.size.width, 0);
                transform = CGAffineTransformScale(transform, -1, 1);
                break;
                
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRightMirrored:
                transform = CGAffineTransformTranslate(transform, img.size.height, 0);
                transform = CGAffineTransformScale(transform, -1, 1);
                break;
            case UIImageOrientationUp:
            case UIImageOrientationDown:
            case UIImageOrientationLeft:
            case UIImageOrientationRight:
                break;
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        CGContextRef ctx = CGBitmapContextCreate(NULL, img.size.width, img.size.height,
                                                 CGImageGetBitsPerComponent(img.CGImage), 0,
                                                 CGImageGetColorSpace(img.CGImage),
                                                 CGImageGetBitmapInfo(img.CGImage));
        CGContextConcatCTM(ctx, transform);
        switch (img.imageOrientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                // Grr...
                CGContextDrawImage(ctx, CGRectMake(0,0,img.size.height,img.size.width), img.CGImage);
                break;
                
            default:
                CGContextDrawImage(ctx, CGRectMake(0,0,img.size.width,img.size.height), img.CGImage);
                break;
        }
        
        // And now we just create a new UIImage from the drawing context
        CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
        UIImage *imgNew = [UIImage imageWithCGImage:cgimg];
        
        CGContextRelease(ctx);
        CGImageRelease(cgimg);
        return imgNew;
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    if (!selectInfo) selectInfo = [[NSMutableDictionary alloc] init];

    //[self alertForDirectionWithOnDone:^(id back){
    
    UIView *container1 = [btGuide3_5 superview];
    UIView *container2 = [btGuide4 superview];
    container1.transform = CGAffineTransformIdentity;
    container2.transform = CGAffineTransformIdentity;
    guide3_5.transform = CGAffineTransformIdentity;
    guide4.transform = CGAffineTransformIdentity;
    
    btCancel.transform = CGAffineTransformIdentity;
    btTakePhoto.transform = CGAffineTransformIdentity;
    btGotoPhotoAlbum.transform = CGAffineTransformIdentity;
    
    btCancel4.transform = CGAffineTransformIdentity;
    btTakePhoto4.transform = CGAffineTransformIdentity;
    btGotoPhotoAlbum4.transform = CGAffineTransformIdentity;
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    DLog(@"Dismiss 4");
    [self dismissViewControllerAnimated:NO completion:^{
    }];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    __block NSString  *tmpImgPath = [documentsDirectory stringByAppendingFormat:@"/test.jpg"];
    
    @autoreleasepool {
        UIImage* imgOrg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        
//        if (imgOrg.size.width < imgOrg.size.height)
//        {
//            int width = 1280;
//            imgOrg = [imgOrg resizedImageEx:CGSizeMake(width, (width/imgOrg.size.width)*imgOrg.size.height) interpolationQuality:kCGInterpolationHigh];
//        }
//        else
//        {
//            int height = 1280;
//            imgOrg = [imgOrg resizedImageEx:CGSizeMake( (height/imgOrg.size.height)*imgOrg.size.width,height) interpolationQuality:kCGInterpolationHigh];
//        }
        
        NSData  *aData = UIImageJPEGRepresentation(imgOrg, 0.8);
        [aData writeToFile:tmpImgPath atomically:YES];
    }
    
    // clear reference
//            /info = nil;
    
    [self selectSiteAndOnDone:^(id photo){
        dispatch_async(dispatch_get_main_queue(), ^{
            ReviewViewController *controll = [[ReviewViewController alloc] initWithNibName:@"ReviewViewController" bundle:nil andSourcePhoto:source andImage:photo andBlock:^(Photo* photo){
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //NSLog(@"\nStart save to server......\n");
                    [self useImage:photo.img andDidMakeGuide: photo.isGuide andDirection:photo.direction andNote:photo.note];
                    
                    DLog(@"Dismiss 5");
                    [self.navigationController dismissViewControllerAnimated:YES completion:^{
                        //NSLog(@"\nDid finished submit photo to server...\n");
                    }];
                });
            }];
            controll.controllerMain = self;
            controll.guideImage = guideImage;
            NavViewController *navi = [[NavViewController alloc] initWithRootViewController: controll];
            
            NLog(@"Present controller 4");

            [self.navigationController presentViewController:navi animated:NO completion:^{
                
            }];
        });
    }];

//}];
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *) aPicker
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    UIView *container1 = [customCameraOverlayView3_5 viewWithTag:777];
    UIView *container2 = [customCameraOverlayView4 viewWithTag:777];
    container1.transform = CGAffineTransformIdentity;
    container2.transform = CGAffineTransformIdentity;
    guide3_5.transform = CGAffineTransformIdentity;
    guide4.transform = CGAffineTransformIdentity;
    
    btCancel.transform = CGAffineTransformIdentity;
    btTakePhoto.transform = CGAffineTransformIdentity;
    btGotoPhotoAlbum.transform = CGAffineTransformIdentity;
    
    btCancel4.transform = CGAffineTransformIdentity;
    btTakePhoto4.transform = CGAffineTransformIdentity;
    btGotoPhotoAlbum4.transform = CGAffineTransformIdentity;
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

    DLog(@"Dismiss 6");
	[self dismissViewControllerAnimated:NO completion:^{
    }];
    
    if (aPicker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
    {
        [self gotoTakePhoto];
    }
}


-(void)takeVideo:(id)sender
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    UIImagePickerController *pickerLibrary = [[UIImagePickerController alloc] init];
    pickerLibrary.sourceType = UIImagePickerControllerSourceTypeCamera;
    pickerLibrary.delegate = self;
    pickerLibrary.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    
    NLog(@"Present controller 5");

    [self presentViewController:pickerLibrary animated:NO completion:^() {
        
    }];
}

-(void) setSourceProperty {
    
//    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    if(source)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];

        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        NSArray *arr = [def objectForKey:@"SavedPhotos"];
        if (arr) {
            int j = 0;
            for (int i = 0; i < arr.count; i++)
            {
                NSString *it = [arr objectAtIndex:i];
                NSString* fullPath = [documentsDirectory stringByAppendingPathComponent:it];
                
                id obj = [[Service shared] getDataOfRecordPath:it];
                if (![[obj objectForKey:@"server"] isEqualToString:[APIController shared].server] ||
                    ![[obj objectForKey:@"user"] isEqualToString:[APIController shared].user]
                    ) continue;
                
                Photo *p = [source objectAtIndex:j];
                p.isFinished = [def boolForKey:it];
                p.imgPath = fullPath;
                p.isGuide = [def boolForKey:[NSString stringWithFormat:@"guide:%@",it]];
                
                NSString* com = [NSString stringWithFormat:@"%@_%@",p.siteID,p.direction];
                if (p.isGuide)
                {
                    [[Service shared].refSiteToGuides setObject:it forKey:com];
                }
                else
                {
                    [[Service shared].refSiteToGuides removeObjectForKey:com];
                }
                j++;
            }
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [super viewWillAppear:animated];
    
    [self refreshView];
    
    // Do any additional setup after loading the view from its nib.
    
    [self.view endEditing:YES];
    
    [prjPick setIsDisabledPicker:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [prjPick setIsDisabledPicker:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [prjPick configNavViewController:self.navigationController];
    
    imgPathPhotos = [[NSMutableDictionary alloc] init];
    scheduledReuploads = [[NSMutableArray alloc] init];
    
    self.lstPhotoBeingDownloaded = [[NSMutableArray alloc] init];
    self.lstPhotoNeedDownload = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyAppDidActive:) name:NotifyAppDidActive object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStartCapture:) name:AVCaptureSessionDidStartRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didOrientation:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyAppWillChangeOrientation:) name:NotifyAppWillChangeOrientation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifAppDidUpdateNewLocation:) name:NotifAppDidUpdateNewLocation object:nil];

    if (![[APIController shared] checkIfDemo])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyUploadProgress:) name:NotifyUploadProgress object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyUploadInBackground:) name:NotifyUploadInBackground object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifAppDidRefreshGuidePhotos:) name:NotifAppDidRefreshGuidePhotos object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyAdhocSitesGetChanged:) name:NotifyAdhocSitesGetChanged object:nil];
    }

    //schedule reupdate note which upload failed
    [NSTimer startSession:@"MainView"];
    
    [NSTimer timerWithInterval:10.0 andBlock:^(NSTimer* tmr){
        for (Photo* p in source)
        {
            NSString* it = [p.imgPath lastPathComponent];
            id obj = [[Service shared] getDataOfRecordPath:it];
            if ([obj objectForKey:@"noteUpdateFailed"])
            {
                NLog(@"Reupdate failed note");
                
                if ([obj objectForKey:@"photoID"])
                {
                    NSString* s = [obj objectForKey:@"note"];
                    NSString* pid = [obj objectForKey:@"photoID"];
                    
                    //update note to server
                    [[APIController shared] updateNote:s ofPhotoID:pid andOnDone:^(id back){
                        //well , note updated , remove failed-key if any , prevent unneccessay re-update
                        id obj2 = [[Service shared] getDataOfRecordPath:it];
                        if ([obj2 objectForKey:@"noteUpdateFailed"])
                        {
                            [obj2 removeObjectForKey:@"noteUpdateFailed"];
                            [[Service shared] updateRecordPath:it andData:obj];
                        }
                        
                    } andOnError:^(id err){
                        
                        //opp, something went wrong, should note a sign to schedule reupdate later
                        id obj2 = [[Service shared] getDataOfRecordPath:it];
                        [obj2 setObject:@"1" forKey:@"noteUpdateFailed"];
                        [[Service shared] updateRecordPath:it andData:obj];
                    }];
                }
            }
        }
    }];
    
    //BACKGROUND QUEUE but bug
    RUN_ON_MAIN_QUEUE(^{
        [self uploadNoteForGuidePhotos];
        
        NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
        if ([userDefault objectForKey:@"Demo"]) {
            btnGuidePhoto.customView = nil;
            btnGuidePhoto.target = nil;
            return;
        }
        
        if ([userDefault objectForKey:@"GuideRestore"]) {
            //reload
            
            //temporary disable restore
            //            double delayInSeconds = 2.0;
            //            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            //            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //                [self performSelectorInBackground:@selector(reloadOldDataFromServer:) withObject:[NSArray array]];
            //            });
            // preload first
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self performSelectorInBackground:@selector(loadGuidePhotosFromUserPref) withObject:nil];
            });
        }
        else {
            //check for reload every day
            BOOL allowSync = YES;
            if ([userDefault objectForKey:@"timestamp"]) {
                // download now
                NSDate  *lastDate = [userDefault objectForKey:@"timestamp"];
                
                if (labs([lastDate timeIntervalSinceNow]) >= 86400) {
                    // a day
                    allowSync = YES;
                }
                else
                    allowSync = NO;
            }
                      // preload first
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self performSelectorInBackground:@selector(loadGuidePhotosFromUserPref) withObject:nil];
            });
            //            }
        }
    });
    
    // filter
    //    double delayInSeconds = 2.0;
    //    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    //    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    //        [self performSelectorInBackground:@selector(filterNoPhotoSite) withObject:nil];
    //    });
    
    
    [btFlash setBackgroundImage:[[UIImage imageNamed:@"images/photo-button.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:0]  forState:UIControlStateNormal];
    [btCameraDeivce setBackgroundImage:[[UIImage imageNamed:@"images/photo-button.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:0]  forState:UIControlStateNormal];
    [btFlash4 setBackgroundImage:[[UIImage imageNamed:@"images/photo-button.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:0]  forState:UIControlStateNormal];
    [btCameraDeivce4 setBackgroundImage:[[UIImage imageNamed:@"images/photo-button.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:0]  forState:UIControlStateNormal];
    
    [btGuide3_5 setBackgroundImage:[[UIImage imageNamed:@"images/photo-button.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:10]  forState:UIControlStateNormal];
    [btGuide4 setBackgroundImage:[[UIImage imageNamed:@"images/photo-button.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:10]  forState:UIControlStateNormal];
    
    guide3_5.backgroundColor = [UIColor blackColor];
    guide4.backgroundColor = [UIColor blackColor];
    
    if (![self hasFlash])
    {
        btFlash.hidden = btFlash4.hidden = NO;
        flashMode3_5.hidden = flashMode4.hidden = NO;
    }
    
    //Start the compass updates.
    //    if (CLLocationManager.headingAvailable )
    {
        //        [locationManager startUpdatingHeading];
        
        UIAlertView *noCompassAlert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"By uploading pictures using this app, the user acknowledges the right of the project partners to use those pictures for reasonable purposes" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noCompassAlert show];
        noCompassAlert.tag = 777;
    }
    
    //    else
    //    {
    //        NSLog(@"No Heading Available: ");
    //        UIAlertView *noCompassAlert = [[UIAlertView alloc] initWithTitle:@"No Compass!" message:@"This device does not have the ability to measure magnetic fields." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //        [noCompassAlert show];
    //        noCompassAlert.tag = 999;
    //    }

    //demo sign
    {
        UIView* rootView = barBottom;
        
        UIView* vw = [rootView viewWithTag:886];
        UILabel* lb = (UILabel*) [rootView viewWithTag:887];
        if (!lb)
        {
            vw = [[UIView alloc] initWithFrame:CGRectMake(134, 7+0 , 50, 30)];
            vw.backgroundColor = [UIColor blackColor];
            vw.alpha = 0.5;
            vw.tag  = 886;
            vw.layer.cornerRadius = 10.0;
            [rootView addSubview:vw];
            
            lb = [[UILabel alloc] initWithFrame:CGRectMake(134+5, 7+5+0, 40, 20)];
            lb.textColor = [UIColor whiteColor];
            lb.font = [UIFont boldSystemFontOfSize:10];
            lb.textAlignment = NSTextAlignmentCenter;
            lb.backgroundColor = [UIColor clearColor];
            lb.tag = 887;
            [rootView addSubview:lb];
        }
        
        if ([[APIController shared] checkIfDemo])
        {
            vw.hidden = NO;
            lb.hidden = NO;
            lb.text = @"DEMO";
            
        }
        else
        {
            vw.hidden = YES;
            lb.hidden = YES;
        }
    }

    refPhotos = [[NSMutableDictionary alloc] init];
    
    NSLog(@"Using server %@",[APIController shared].server);
    self.thumbnail = [UIImage imageNamed:@"thumnail.png"];

    // defaul thum
    cellThumb = [UIImage imageNamed:@"preload.png"];

    lstObjsForTbPhotos = [[NSMutableArray alloc] init];
    tbPhotos.delegate = self;
    tbPhotos.dataSource =  self;

    [self reloadAll];
}

- (void) reloadAll
{
    // get source
    [self reloadSourceData];

    

    self.direction = [self getDirection: @"N"];
    AppDelegate *del = appDelegate;
    del.direction = self.direction;
    [self setSelectedDirection: btN];
    
    orientation = UIInterfaceOrientationPortrait;
    
    self.uploading = [NSMutableArray array];
    
    for (Photo *p in source)
    {
        if (p.isUploading) continue;
        if (!p.isFinished)
        {
            CGFloat compression = 0.5f;
            
            //            NSData *data = UIImageJPEGRepresentation([UIImage imageWithContentsOfFile:p.imgPath], compression);
            
            ExifContainer *container = [[ExifContainer alloc] init];
            [container addCreationDate:[NSDate date]];
            [container addLocation:appDelegate.locationManager.location];
            
            NSData *data = UIImageJPEGRepresentation([appDelegate loadImageOfFile:p.imgPath], compression);
            UIImage* imgWithExif = [UIImage imageWithData:data];
            data = [imgWithExif addExif:container];
            
            APIController *api = [APIController shared];
            api.photo = p;
            //ASIHTTPRequest *request =
            
            p.isUploading = YES;
            id d = [[Service shared] getDataOfRecordPath:[p.imgPath lastPathComponent]];
            NSString* sDate = [d objectForKey:@"created_at"];
            NSString* note = [d objectForKey:@"note"];
            
            NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:p,@"Photo", nil];
            [api uploadPhoto:data withInfo:info andCreatedAt:sDate andNote:note andDirection:p.direction andSiteID: p.sID andUpdateBlock:^(id back){
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    float progress = [[back objectAtIndex:0] floatValue];
                    
                    if (progress>= 1.0f)
                    {
                        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
                        [def setBool:YES forKey:api.photo.imgPath];
                        
                        api.photo.isFinished = YES;
                        [tbPhotos reloadData];
                    }
                    
                    if (progress < 0)
                    {
                        [NSTimer timerWithTimeout:10.0 andBlock:^(NSTimer* tmr){
                            [self reuploadFailedPhoto:p];
                        }];
                    }
                });
            } andBackground:NO];
            
            //            [self.uploading addObject:api];
        }
    }
    
    if ([UIScreen mainScreen].bounds.size.height == 480)
    {
        vwNotes.frame = CGRectMake(0, -300, 320, 244 - 88);
    }
    else
    {
        vwNotes.frame = CGRectMake(0, -300, 320, 244);
    }
    
    if ([APIController shared].currentProject)
    {
        self.title = [[APIController shared].currentProject objectForKey:@"name"];
    }
    
    [[APIController shared] downloadAllSites:^(NSMutableArray *sites) {
        NSLog(@"Site: %@", sites);
        
        if (sites)
        {
            self->allSites = sites;
        }
        
        if (![[APIController shared] checkIfDemo])
        {
            NSString* aKey = [NSString stringWithFormat:@"ListOfGuideSites_%@_%@",[[APIController shared].currentProject objectForKey:@"uid"],[APIController shared].server];
            
            NSArray* actualLstSites = [[NSUserDefaults standardUserDefaults] objectForKey:aKey];
            
            if (!actualLstSites)
            {
                NSMutableArray* lstSites = [NSMutableArray array];
                NSArray* arr = [[NSUserDefaults standardUserDefaults] objectForKey:@"GuidePhotos"];
                for (id obj in arr)
                {
                    if ([self checkSiteExistWithId:[obj objectForKey:@"SiteId"]])
                    {
                        if (![lstSites containsObject:[obj objectForKey:@"SiteId"]])
                        {
                            [lstSites addObject:[obj objectForKey:@"SiteId"]];
                        }
                    }
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:lstSites forKey:aKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [self loadGuidePhotosFromUserPref];
        }
        
        [self refreshView];
    }];

}

-(void) reloadSourceData {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSMutableArray *getSource = [NSMutableArray array];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSArray *arr = [def objectForKey:@"SavedPhotos"];
    if (arr) {
        for (NSString *it in arr) {
            
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
            p.imgPath = fullPath;
            p.note = [obj objectForKey:@"note"];
            if([obj objectForKey:@"photoID"])
            {
                p.photoID = [obj objectForKey:@"photoID"];
            }
            
            [refPhotos setObject:p forKey:p.date];
            
            @autoreleasepool {
                UIImage* imgOri = [appDelegate loadImageOfFile:fullPath];// [UIImage imageWithContentsOfFile:fullPath];
                if (imgOri.size.width < imgOri.size.height)
                    p.imgThumbnail = [imgOri imageByScalingAndCroppingForSize:CGSizeMake(240, 240)];
                else
                    p.imgThumbnail = [imgOri imageByScalingAndCroppingForSize:CGSizeMake(240, 240)];
            }
            
            p.isGuide = [def boolForKey:[NSString stringWithFormat:@"guide:%@",it]];
            
            NSString* comm = [NSString stringWithFormat:@"%@_%@",p.siteID,p.direction];
            if (p.isGuide)
            {
                [[Service shared].refSiteToGuides setObject:it forKey:comm];
            }
            else
            {
                [[Service shared].refSiteToGuides removeObjectForKey:comm];
            }
            
            [getSource addObject:p];
        }
    }
    
    // defaul thum
    
    //cellThumb = [UIImage imageNamed:@"preload.png"];
    self->source = getSource;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void) dealloc
{
    NLog(@"RELEASE %@",NSStringFromClass([self class]));

    [NSTimer endSession:@"MainView"];
}

-(float)getAngleWithOrientation:(CLHeading *)newHeading
{
//    UIInterfaceOrientationPortrait           = UIDeviceOrientationPortrait,
//    UIInterfaceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown,
//    UIInterfaceOrientationLandscapeLeft      = UIDeviceOrientationLandscapeRight,
//    UIInterfaceOrientationLandscapeRight     = UIDeviceOrientationLandscapeLeft
    
//    return  newHeading.magneticHeading;
    if (orientation == UIInterfaceOrientationLandscapeLeft)
    {
        //NSLog(@"UIInterfaceOrientationLandscapeLeft");
//        lbGuide3_5.text = lbGuide4.text = [NSString stringWithFormat:@"1: %f", newHeading.trueHeading];
        return  newHeading.trueHeading + 270.0;
//        [self.compassImageViewIphone setTransform:CGAffineTransformMakeRotation((((newHeading.magneticHeading - 90) *3.14/180)*-1) )];
        
    }else if (orientation == UIInterfaceOrientationLandscapeRight)
    {
        //NSLog(@"UIInterfaceOrientationLandscapeRight");
//        lbGuide3_5.text = lbGuide4.text = [NSString stringWithFormat:@"2: %f", newHeading.trueHeading];        
        return  newHeading.trueHeading + 90;
//        [self.compassImageViewIphone setTransform:CGAffineTransformMakeRotation((((newHeading.magneticHeading + 90) *3.14/180)*-1))];
        
    }else if (orientation == UIInterfaceOrientationPortraitUpsideDown){
        //NSLog(@"UIInterfaceOrientationPortraitUpsideDown");
//        lbGuide3_5.text = lbGuide4.text = [NSString stringWithFormat:@"3: %f", newHeading.trueHeading];        
        return  newHeading.trueHeading + 230;
//        [self.compassImageViewIphone setTransform:CGAffineTransformMakeRotation((((newHeading.magneticHeading + 180) *3.14/180)*-1) )];
        
    }else{
        //NSLog(@"Portrait");
//        lbGuide3_5.text = lbGuide4.text = [NSString stringWithFormat:@"4: %f", newHeading.trueHeading];        
        return  newHeading.trueHeading;
//        [self.compassImageViewIphone setTransform:CGAffineTransformMakeRotation((newHeading.magneticHeading *3.14/180)*-1)];
    }
}


- (IBAction) changeGuide:(id)sender
{
    //NSLog(@"\n-(IBAction) changeGuide:(id)sender\n");
    if ([lbGuide3_5.text isEqualToString:@"Guide Off"] || [lbGuide4.text isEqualToString:@"Guide Off"])
    {
        guide3_5.hidden = guide4.hidden = NO;
        lbGuide3_5.text = lbGuide4.text = @"Guide On";
    }else
    {
        guide3_5.hidden = guide4.hidden = YES;
        lbGuide3_5.text = lbGuide4.text = @"Guide Off";
    }
}

-(IBAction) wenTouchReminder:(id)sender
{
//    ReminderViewController *control = [ReminderViewController shared];
//    control.mainController = self;
//    [self.navigationController pushViewController:control animated:YES];
}

-(IBAction) wenInfo:(id)sender
{
}

-(IBAction) wenDonate:(id)sender
{
//    DonateViewController* controller = [DonateViewController shared];
//    [self.navigationController pushViewController:controller animated:YES];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://photomon.nacc.com.au/mobile/index.html"]];

}

-(IBAction) wenMore:(id)sender
{
    
}

- (void) refresh //for adhoc
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");
    
    allSites = [[Service shared] getAllSiteModels];
    
    [refPhotos removeAllObjects];
    for (Photo* p in source)
    {
        NSArray* arr = [[p.imgPath lastPathComponent] componentsSeparatedByString:@"_"];
        [refPhotos setObject:p forKey:[arr objectAtIndex:3]];
    }
    
    NSLog(@"Using server %@",[APIController shared].server);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    self.thumbnail = [UIImage imageNamed:@"thumnail.png"];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSArray *arr = [def objectForKey:@"SavedPhotos"];
    if (arr) {
        for (NSString *it in arr) {
            
            NSString* fullPath = [documentsDirectory stringByAppendingPathComponent:it];
            
            id obj = [[Service shared] getDataOfRecordPath:it];
            if (![[obj objectForKey:@"server"] isEqualToString:[APIController shared].server] ||
                ![[obj objectForKey:@"user"] isEqualToString:[APIController shared].user]
                ) continue;
            
            NSArray *com = [it componentsSeparatedByString:@"_"];
            NSString* key = [com objectAtIndex:3];
            Photo *p = [refPhotos objectForKey:key];
            p.siteID = [com objectAtIndex:1];
            
            NSString* oldPath = p.imgPath;
            NSString* oldKeyGuide = [NSString stringWithFormat:@"guide:%@",[oldPath lastPathComponent] ];
            if ([def objectForKey:oldKeyGuide])
            {
                BOOL isOldGuide = [def boolForKey:oldKeyGuide];
                
                // set back
                [def removeObjectForKey:oldKeyGuide];
                [def setObject:[NSNumber numberWithBool:isOldGuide] forKey:[NSString stringWithFormat:@"guide:%@",it]];
            }
            
            p.imgPath = fullPath;
            [refPhotos removeObjectForKey:key];
        }
    }
    
    //sync
    [def synchronize];
    
    //any remain photo in refs => delete
    for (id k in refPhotos.allKeys)
    {
        NLog(@"Source Remove");
        [source removeObject:[refPhotos objectForKey:k]];
    }
    [refPhotos removeAllObjects];
}

-(NSArray*)getAllUploadedPhoto
{
    NSMutableArray *arr = [NSMutableArray array];
    return arr;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark guideline transparency
-(IBAction) guideAlphaChanged:(UISlider*) slider {
    guide4.alpha = guide3_5.alpha = slider.value;
}

#pragma mark reload data from server 
- (void) uploadNoteForGuidePhotos {
    __block NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
    NSArray *arr = [userDefault objectForKey:@"NoteUpload"];
    if (arr && arr.count > 0) {
        for (__block NSDictionary   *dict in arr) {
            [[APIController shared] updateNote:[dict objectForKey:@"note"] ofPhotoID:[dict objectForKey:@"pID"] andOnDone:^(id back){
                // remove
                NSArray *_arr = [userDefault objectForKey:@"NoteUpload"];
                if (_arr && _arr.count > 0) {
                    NSMutableArray  *arrRec = [NSMutableArray arrayWithArray:_arr];
                    for (NSDictionary   *_dict in arrRec) {
                        if ([[dict objectForKey:@"pID"] isEqualToString:[dict objectForKey:@"pID"]]) {
                            [arrRec removeObject:_dict];
                            break;
                        }
                    }
                    //save back
                    [userDefault setObject:arrRec forKey:@"NoteUpload"];
                    [userDefault synchronize];
                }
                DLog(@"Note update successfully!");
            }andOnError:^(id err){

            }];
        }


    }


}

- (void) loadGuidePhotosFromUserPref {
    /*
     -
     -*/
    NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
//    Site    *site = [self selectSite];
//    DLog(@"current site id = %@ site name = %@",site.ID,site.Name);
 
    NSArray *guidePhotos = [userDefault objectForKey:@"GuidePhotos"];
    NSMutableArray* arrObjs = [NSMutableArray array];
    
    if (guidePhotos) {
        for (NSMutableDictionary    *dict in guidePhotos) {
            
            if (![self checkSiteExistWithId:[dict objectForKey:@"SiteId"]]) {
//                DLog(@"Found a site id not in list %@",[dict objectForKey:@"SiteId"]);
                continue;
            }
            
//            if (![site.ID isEqualToString:[dict objectForKey:@"SiteId"]]) {
//                DLog(@"site nt match :%@ - %@",[dict objectForKey:@"SiteId"],[dict objectForKey:@"SiteName"]);
//                continue;
//            }
//            DLog(@"have a site:%@ - %@",[dict objectForKey:@"SiteId"],[dict objectForKey:@"SiteName"]);
            Photo *p = [[APIController shared] getPhotoInstanceForID:[dict objectForKey:@"ID"]];
            
            p.date = [dict objectForKey:@"CreatedAt"];
            p.direction = [dict objectForKey:@"Direction"];
            
            NSString* imgPath = [Downloader storagePathForURL:[dict objectForKey:@"ImagePath"]];
            p.imgPath = imgPath;
            p.img = [appDelegate loadImageOfFile:p.imgPath];// [UIImage imageWithContentsOfFile:p.imgPath];
            
            NSString* relativeThumbPath = [dict objectForKey:@"ThumbPath"];
            
            NSString* fullThumbPath = [Downloader storagePathForURL:relativeThumbPath];
            
            p.imgThumbnail = [appDelegate loadImageOfFile:fullThumbPath]; //  [UIImage imageWithContentsOfFile:fullThumbPath];
            p.thumbPath = fullThumbPath;
            
            p.sID = [dict objectForKey:@"SiteId"];
            p.siteID = [dict objectForKey:@"SiteName"];
            p.photoID = [dict objectForKey:@"ID"];
            p.isFinished = YES;
            
            p.isGuide = [[dict objectForKey:@"IsGuide"] boolValue];
            
            p.note = [dict objectForKey:@"Note"];
            
            [arrObjs addObject:p];
        }
    }
    
    // deleete
    [userDefault removeObjectForKey:@"GuideRestore"];
    [userDefault synchronize];
    
    RUN_ON_MAIN_QUEUE(^{
        // add to source
        if (source) {
            for (id obj in arrObjs)
            {
                if (![source containsObject:obj])
                {
                    [source addObject:obj];
                }
            }
        }
        [self refreshView];
    });
    /*
     -
     -*/
}

-(void) filterNoPhotoSite {
    __block NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString    *urlStr = [NSString stringWithFormat:@"%@/photos.json?access_token=%@&project_id=%@",[APIController shared].server,[userDefault objectForKey:@"AccessToken"],[[APIController shared].currentProject objectForKey:@"uid"]];
    __block ASIHTTPRequest  *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [request setRequestMethod:@"GET"];
    [request setCompletionBlock:^{
        RUN_ON_BACKGROUND_QUEUE(^{
            // process data here
            NSError *error = nil;
            NSArray *arrPhotoData = [NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingAllowFragments error:&error];
            //NSLog(@"=> %@",arrPhotoData);
            if (arrPreloadSites) {
                [arrPreloadSites removeAllObjects];
            }
            else
                arrPreloadSites = [NSMutableArray new];
            
            
            //
            for (Site *site in allSites) {
                //DLog(@"cehck site %@",site);
                for (NSDictionary *dict in arrPhotoData) {
                    
                    if ([site.ID isEqualToString:[dict objectForKey:@"SiteId"]]) {
                        [arrPreloadSites addObject:site];
                        DLog(@"add site %@",site);
                        // break;
                        continue;
                    }
                }
            }

        });
    }];
    [request startAsynchronous];
}

- (void) reloadOldDataFromServer:(NSArray*) arrAllowedSiteId {
    
    NLog(@"reload data from server");
    __block NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    //create ref so, we can use older one
    NSArray* loadedGuidePhotos = [userDefault objectForKey:@"GuidePhotos"];
    NSMutableDictionary* loadedRefGuidePhotos = [[NSMutableDictionary alloc] init];
    for (id d in loadedGuidePhotos)
    {
        [loadedRefGuidePhotos setObject:d forKey:[d objectForKey:@"ID"]];
    }
    
    __block NSMutableArray  *arrPhoto = [NSMutableArray arrayWithArray:loadedGuidePhotos];
    
    // check for first restored
 
    NSString    *urlStr = [NSString stringWithFormat:@"%@/photos.json?access_token=%@&project_id=%@",[APIController shared].server,[userDefault objectForKey:@"AccessToken"],[[APIController shared].currentProject objectForKey:@"uid"]];
    __block ASIHTTPRequest  *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStr]];
    
    [request setRequestMethod:@"GET"];
    [request setCompletionBlock:^{
        RUN_ON_BACKGROUND_QUEUE(^{
            // process data here
            NSError *error = nil;
            NSArray *arrPhotoData = [NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingAllowFragments error:&error];
            NSLog(@"=> %@",arrPhotoData);
            
            for (NSDictionary *dict in arrPhotoData) {
                // check for site id
                if (![self checkSiteExistWithId:[dict objectForKey:@"SiteId"]]) {
                    DLog(@"Found a site id not in list %@",[dict objectForKey:@"SiteId"]);
                    continue;
                }
                
                // check if site is allow or not
                if (arrAllowedSiteId != nil) {
                    BOOL   isAllowed = NO;
                    for (NSString *str in arrAllowedSiteId) {
                        if ([str isEqualToString:[dict objectForKey:@"SiteId"]]) {
                            // break now
                            isAllowed = YES;
                            break;
                        }
                    }
                    
                    
                    if (!isAllowed) {
                        // not to download it!
                        continue;
                    }
                }

                
                NSMutableDictionary *photoDict = [NSMutableDictionary new];
                for (NSString *key in [dict allKeys]) {
                    [photoDict setObject:[[dict objectForKey:key] description] forKey:key];
                }
                // get photo here
//                NSURL *photoUrl = [NSURL URLWithString:[dict objectForKey:@"ImageUrl"]];
                
                NSString* relativeFilePath = [dict objectForKey:@"ImageUrl"];
                
                __block NSString *filePath = [Downloader storagePathForURL:relativeFilePath];
                
                BOOL isFileExist = NO;
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    isFileExist = YES;
                }
                
                //if (!isFileExist) {
                    //RUN_ON_MAIN_QUEUE(^{
                // force download again
                
                BOOL isShouldDownload = NO;
                NSDictionary* refOlder = [loadedRefGuidePhotos objectForKey:[dict objectForKey:@"ID"]];
                if (refOlder)
                {
                    if (![[refOlder objectForKey:@"ImageUrl"] isEqualToString:[dict objectForKey:@"ImageUrl"]])
                    {
                        isShouldDownload = YES;
                    }
                }
                else
                {
                    isShouldDownload = YES;
                }
                    //});
                    
                //}
                
                if (!isShouldDownload)
                {
                    //recheck for failed image
                    if ([self.lstPhotoNeedDownload containsObject:[filePath lastPathComponent]])
                    {
                        if (![self.lstPhotoBeingDownloaded containsObject:[filePath lastPathComponent]])
                        {
                            isShouldDownload = YES;
                        }
                    }
                }
                
                if (isShouldDownload)
                {
                    [self downloadPhoto:photoDict];
                }

                if (!refOlder) //only add if new
                {
                    UIImage *img = nil;
                    if (!isFileExist) {
                        // save
                        //[photoRequest.responseData writeToFile:filePath atomically:YES];
                        //img = [UIImage imageWithData:photoRequest.responseData];
                    }
                    else
                        img = [appDelegate loadImageOfFile:filePath];// [UIImage imageWithContentsOfFile:filePath];
                    
                    NSString* relativeThumbPath = [[dict objectForKey:@"ImageUrl"] stringByAppendingString:@"_thumb"];

                    NSString    *thumbPath = [Downloader storagePathForURL:relativeThumbPath];
                    
                    if (img)
                    {
                        // crop
                        img = [img imageByScalingAndCroppingForSize:CGSizeMake(240, 240)];
                        // rewrite dict
                        
                        // save the image
                        NSData *compressedImageData = UIImageJPEGRepresentation(img, 0.5);
                        if (compressedImageData) {
                            [compressedImageData writeToFile:thumbPath atomically:YES];
                        }
                        else {
                            UIGraphicsBeginImageContext(img.size);
                            [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
                            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            
                            compressedImageData = UIImageJPEGRepresentation(newImage, 0.5);
                            [compressedImageData writeToFile:thumbPath atomically:NO];
                        }
                    }
                    
                    [photoDict setObject:relativeFilePath forKey:@"ImagePath"];
                    [photoDict setObject:relativeThumbPath forKey:@"ThumbPath"];
                    [photoDict setObject:[NSNumber numberWithBool:YES] forKey:@"IsGuide"];
                    // check photo dict
                    for (Site *site in allSites) {
                        if ([site.ID isEqualToString:[photoDict objectForKey:@"SiteId"]]) {
                            [photoDict setObject:site.Name forKey:@"SiteName"];
                            break;
                        }
                    }
                    
                    NSString* comm = [[[photoDict objectForKey:@"SiteName"] stringByAppendingString:@"_"] stringByAppendingString:[photoDict objectForKey:@"Direction"]];
                    if ([[Service shared].refSiteToGuides objectForKey:comm])
                    {
                        [photoDict setObject:[NSNumber numberWithBool:NO] forKey:@"IsGuide"];
                    }
                  
                    //add
                    [arrPhoto addObject:photoDict];
                }
                else
                {
                    NLog(@"IGNORE");
                }
                

            }
            
            // write down
//            DLog(@"==> arrPhtos %@",arrPhoto);
            [userDefault setObject:arrPhoto forKey:@"GuidePhotos"];
            
            // megre data
//            NSMutableArray *arrPhotoMerge = [NSMutableArray new];
//            NSArray *arrGuidePhotos = [userDefault objectForKey:@"GuidePhotos"];
//            if (!arrGuidePhotos) {
//                arrGuidePhotos = [NSArray new];
//            }
//            // add
//            [arrPhotoMerge addObjectsFromArray:arrGuidePhotos];
//            
//            NSMutableArray  *arrTemp = [NSMutableArray array];
//            // megere
//            for (NSDictionary *pDict in arrPhoto) {
//                BOOL isExistPhoto = NO;
//                for (NSDictionary *oDict in arrPhotoMerge) {
//                    NSString    *s1 = [pDict objectForKey:@"ID"];
//                    NSString    *s2 = [oDict objectForKey:@"ID"];
//                    if ([s1 isEqualToString:s2]) {
//                        isExistPhoto = YES;
//                        break;
//                    }
//                }
//                if (!isExistPhoto) {
//                    [arrTemp addObject:pDict];
//                }
//            }
//            
//            //merge again
//            [arrPhotoMerge addObjectsFromArray:arrTemp];
//            
//            // sort
//            NSArray *arr = [arrPhotoMerge sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSDictionary *dict1, NSDictionary *dict2) {
//                return [[dict1 objectForKey:@"SiteName"] compare:[dict2 objectForKey:@"SiteName"] options:NSCaseInsensitiveSearch];
//            }];
//
//            [userDefault setObject:arr forKey:@"GuidePhotos"];
            [userDefault setObject:[NSDate date] forKey:@"timestamp"];
            [userDefault synchronize];
            
            // reload now
//            if (source) {
//                [source removeAllObjects];
//            }
            
            [self reloadSourceData];
//            [self setSourceProperty];
            [self loadGuidePhotosFromUserPref];
        });

    }];
    
    [request setFailedBlock:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//                        [[[UIAlertView alloc] initWithTitle:nil message:@"Can not download guide photos at the moment. Try again later" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
//        });
        [self loadGuidePhotosFromUserPref];
    }];
    [request startAsynchronous];

}

-(void) downloadPhoto:(NSDictionary*) _photoDict {
    
    __block NSMutableDictionary *photoDict = [NSMutableDictionary dictionaryWithDictionary:_photoDict];
    
    NSURL *photoUrl = [NSURL URLWithString:[photoDict objectForKey:@"ImageUrl"]];
    
    NSString* relativeFilePath = [photoDict objectForKey:@"ImageUrl"];
    
    NSString *filePath = [Downloader storagePathForURL:relativeFilePath];
    
    RUN_ON_MAIN_QUEUE(^{
        if (![self.lstPhotoBeingDownloaded containsObject:[filePath lastPathComponent]])
        {
            [self.lstPhotoBeingDownloaded addObject:[filePath lastPathComponent]];
        }
    });

    __block ASIHTTPRequest  *photoRequest = [ASIHTTPRequest requestWithURL:photoUrl];
    
    [photoRequest setCompletionBlock:^{
        
        RUN_ON_BACKGROUND_QUEUE(^{
            
            // Use when fetching text data
            //NSString *responseString = [request responseString];
            UIImage *img = nil;
            // Use when fetching binary data
            NSData *responseData = [photoRequest responseData];
            NSError* err;
            [responseData writeToFile:filePath options:NSDataWritingAtomic error:&err];
            
            img = [[UIImage imageWithData:photoRequest.responseData] imageByScalingAndCroppingForSize:CGSizeMake(240, 240)];
            
            // notify
            DLog(@"==> Complete download photo for %@ siteId=%@",photoUrl,[photoDict objectForKey:@"SiteId"]);
            
            NSString* relativeThumbPath = [[photoDict objectForKey:@"ImageUrl"] stringByAppendingString:@"_thumb"];

            NSString    *thumbPath = [Downloader storagePathForURL:relativeThumbPath];
            
            @autoreleasepool {
                // save the image
                NSData *compressedImageData = UIImageJPEGRepresentation(img, 0.5);
                if (compressedImageData) {
                    [compressedImageData writeToFile:thumbPath atomically:YES];
                }
                else {
                    UIGraphicsBeginImageContext(img.size);
                    [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
                    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    compressedImageData = UIImageJPEGRepresentation(newImage, 0.5);
                    [compressedImageData writeToFile:thumbPath atomically:NO];
                }
            }
            //        [photoDict setObject:thumbPath forKey:@"ThumbPath"];
            //
            //        [photoDict setObject:filePath forKey:@"ImagePath"];
            
            // save back to user default
            NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
            
            NSArray *guidePhotos = [userDefault objectForKey:@"GuidePhotos"];
            NSMutableArray  *arrPhotos = [NSMutableArray array];
            for (NSDictionary   *dict in guidePhotos) {
                if (![[dict objectForKey:@"ID"] isEqualToString:[photoDict objectForKey:@"ID"]]) {
                    [arrPhotos addObject:dict];
                    
                }
                else {
                    photoDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                    [photoDict setObject:relativeThumbPath forKey:@"ThumbPath"];
                    
                    [photoDict setObject:relativeFilePath forKey:@"ImagePath"];
                    [arrPhotos addObject:photoDict];
                }
            }
            [userDefault setObject:arrPhotos forKey:@"GuidePhotos"];
            [userDefault synchronize];
            
            // seek for curr list
            RUN_ON_MAIN_QUEUE(^{
                for (Photo *p in source) {
                    if ([p.photoID isEqualToString:[photoDict objectForKey:@"ID"]]) {
                        
                        NSString* relativeThumbPath = [photoDict objectForKey:@"ThumbPath"];
                        
                        NSString* fullThumbPath = [Downloader storagePathForURL:relativeThumbPath];
                        
                        p.thumbPath = fullThumbPath;
                        // break;
                        
                    }
                }

                [self refreshView];
                [self.controllerSavedPhotos refreshView];

                [self.lstPhotoBeingDownloaded removeObject:[filePath lastPathComponent]];
            });

        });
    }];
    
    [photoRequest setFailedBlock:^{
        
        RUN_ON_MAIN_QUEUE(^{
            [self.lstPhotoBeingDownloaded removeObject:[filePath lastPathComponent]];
        });
    }];
    
    [photoRequest startAsynchronous];
}

#pragma mark- UItableView delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    UIView* targetView = tableView.superview;
    UILabel* lb = (UILabel*) [targetView viewWithTag:9858];
    if (!lb)
    {
        lb = [[UILabel alloc] init];
        lb.text = @"The list is empty";
        lb.textAlignment = NSTextAlignmentCenter;
        lb.textColor = [UIColor lightGrayColor];
        lb.tag = 9858;
        [targetView addSubview:lb];
    }
    
    NSUInteger count = lstObjsForTbPhotos.count;
    if (count == 0)
    {
        tableView.alpha = 0;
        lb.frame = CGRectMake(0, (tableView.frame.size.height-20)/2, tableView.frame.size.width, 20);
        [lb setAlpha:1.0];
    }
    else
    {
        tableView.alpha = 1.0;
        [lb setAlpha:0.0];
    }
    return count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[PhotoCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if (appDelegate.osVersion >= 8)
        {
            cell.layoutMargins = UIEdgeInsetsZero;
            cell.preservesSuperviewLayoutMargins = NO;
        }
    }

    Photo *st = [lstObjsForTbPhotos objectAtIndex:indexPath.row];
    
    if ([[APIController shared] checkIfDemo])
    {
        st.isFinished = YES;
    }

    cell.textLabel.text = st.siteID;
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", st.direction, st.date];
    if (!st.imgThumbnail) {
                
        st.imgThumbnail = [appDelegate loadImageOfFile:st.thumbPath];// [UIImage imageWithContentsOfFile:st.thumbPath];
        
        if (!st.imgThumbnail) {
            // defaut here;
            cell.imageView.image = cellThumb;
            if (![self.lstPhotoNeedDownload containsObject:[st.imgPath lastPathComponent]])
            {
                [self.lstPhotoNeedDownload addObject:[st.imgPath lastPathComponent]];
            }
            
            [self redownloadImages];
        }
        else
        {
            [self.lstPhotoNeedDownload removeObject:[st.imgPath lastPathComponent]];
            cell.imageView.image = st.imgThumbnail;
        }
    }
    else
    {
        [self.lstPhotoNeedDownload removeObject:[st.imgPath lastPathComponent]];
        cell.imageView.image = st.imgThumbnail;
    }
    
    cell.progress.progress = st.progress;
    
    if (st.isFinished)
    {
        cell.progress.hidden = YES;
    }else
    {
        cell.progress.hidden = NO;
    }
    
    if (st.isGuide)
    {
        cell.contentView.backgroundColor = [UIColor colorWithRed:202/255.0 green:251/255.0 blue:192/255.0 alpha:1.0f];
    }
    else
    {
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    [cell layoutSubviews];
    
    //remove all refs to this cell
    {
        NSArray* allkeys = imgPathPhotos.allKeys;
        for (NSString* key in allkeys)
        {
            Photo* p = [imgPathPhotos objectForKey:key];
            if (p.view == cell)
            {
                [imgPathPhotos removeObjectForKey:key];
                p.view = nil;
            }
        }
    }
    
    st.view = cell;
    [imgPathPhotos setObject:st forKey:st.imgPath];
    
//    if (IS_IOS_7) {
//        CGRect  frame = cell.frame;
//        UIView  *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 92, frame.size.width, 1)];
//        lineView.backgroundColor = [UIColor lightGrayColor];
//        [cell.contentView addSubview:lineView];
//    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Photo *st = [lstObjsForTbPhotos objectAtIndex:indexPath.row];

    NSString* s = st.siteID;
    CGSize maximumSize = CGSizeMake(230, 9999);
    CGSize sz = [s sizeWithFont:[UIFont boldSystemFontOfSize:18]
              constrainedToSize:maximumSize
                  lineBreakMode:NSLineBreakByTruncatingTail];
    if (sz.height < 23) {
        return 88-5;
    }
    
    return 88+5;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //release the older
    self.controllerSavedPhotos.onAttemptToRemovePhoto = nil;
    
    //...
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ViewSavedPhotosViewController *control = [[ViewSavedPhotosViewController alloc] initWithNibName:@"ViewSavedPhotosViewController" bundle:nil andPhotos:lstObjsForTbPhotos andSelectedIndex: indexPath.row];
    control.controllerMain = self;
    self.controllerSavedPhotos = control;
    __weak ViewSavedPhotosViewController* weakControl = control;
    __weak MainViewController* weakSelf = self;
    
    control.onAttemptToRemovePhoto = ^(id p){
        [self->lstObjsForTbPhotos removeObject:p];
    };
    
    control.onDidTouchNavItemBack = ^(id b){
        [weakSelf.navigationController popViewControllerAnimated:YES];
        weakControl.onDidTouchNavItemBack = nil;
        weakControl.onAttemptToRemovePhoto = nil;
        
        [weakSelf setSourceProperty];
        [weakSelf refreshView];
    };
    
    [self.navigationController pushViewController:control animated:YES];
}

#pragma mark- Button actions
-(void)addPhoto:(id)sender
{
    if (appDelegate.newestUserLocation.coordinate.latitude == 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"Require location" message:@"We can't see your location. Please turn location services on in your Settings!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    isAddForDirection = NO;
    
    APIController *api = [APIController shared];
    [api downloadAllSites:^(NSMutableArray *sites) {
        //NSLog(@"Site: %@", sites);
        
        if (sites)
        {
            self->allSites = sites;
        }
    }];
//    [self.uploading addObject:api];
#if TARGET_IPHONE_SIMULATOR
    [self gotoAlbum];
#else
    [self gotoTakePhoto];
    [self alertForDirectionWithOnDone:^(id back){
    }];
#endif
    
}

-(IBAction) showDownloadGuides {
    
    DownloadViewController  *downloadController = [[DownloadViewController alloc] initWithNibName:@"DownloadViewController" bundle:[NSBundle mainBundle]];
    downloadController.arrList = [[NSMutableArray alloc] initWithArray:allSites];
    downloadController.mainController = self;
    downloadController.photos = lstObjsForTbPhotos;
    UINavigationController  *nav = [[NavViewController alloc] initWithRootViewController:downloadController];
    
    NLog(@"Present controller 7");

    [self.navigationController presentViewController:nav animated:YES completion:nil];
    
}

-(Site*)distanceToClosetOffice
{
    if (allSites.count < 1) return nil;
    
    CGFloat distance = -1;
    AppDelegate *del = appDelegate;
    //MKMapPoint currentPoint = MKMapPointForCoordinate(del.newestUserLocation.coordinate);
    CLLocation  *currentPoint = [[CLLocation alloc] initWithLatitude:del.newestUserLocation.coordinate.latitude longitude:del.newestUserLocation.coordinate.longitude];
    
    NSArray* arr = allSites;
    Site* branch = [arr objectAtIndex:0];
    Site* branchCurrent = branch;
//    MKMapPoint branchPoint = MKMapPointForCoordinate(CLLocationCoordinate2DMake([branch.Latitude doubleValue], [branch.Longitude doubleValue]));
    CLLocation *branchPoint = [[CLLocation alloc] initWithLatitude:[branch.Latitude doubleValue] longitude:[branch.Longitude doubleValue]];
    //distance = MKMetersBetweenMapPoints(currentPoint, branchPoint);
    distance = [currentPoint distanceFromLocation:branchPoint];
    for (branch in arr)
    {
        //NSLog(@"\n-->>Branch: %@\n", branch.Name);
//        branchPoint = MKMapPointForCoordinate(CLLocationCoordinate2DMake([branch.Latitude doubleValue], [branch.Longitude doubleValue]));
        branchPoint = [[CLLocation alloc] initWithLatitude:[branch.Latitude doubleValue] longitude:[branch.Longitude doubleValue]];
        
        CGFloat _dis = [currentPoint distanceFromLocation:branchPoint];
        //NSLog(@"\nDistance: %f <---> new %f\n",distance, MKMetersBetweenMapPoints(currentPoint, branchPoint));
        if (distance > _dis)
        {
            distance = _dis;
            branchCurrent = branch;
        }
    }
    
    //distance = MKMetersBetweenMapPoints(currentPoint, MKMapPointForCoordinate(CLLocationCoordinate2DMake([branchCurrent.Latitude doubleValue], [branchCurrent.Longitude doubleValue])));
    distance = [currentPoint distanceFromLocation:[[CLLocation alloc] initWithLatitude:[branchCurrent.Latitude doubleValue] longitude:[branchCurrent.Longitude doubleValue]]];
    branchCurrent.distance = distance;
    return branchCurrent;
}

#pragma  mark - Select photo delegate
-(BOOL) checkSiteExistWithId:(NSString*)siteId {
    
    for (Site *site in allSites) {
        if ([site.ID isEqualToString:siteId]) {
            return YES;
        }
    }
    return NO;
}

-(Site*)selectSite
{
    if (appDelegate.newestUserLocation.coordinate.latitude == 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"Require location" message:@"We can't see your location. Please turn location services on in your Settings!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return nil;
    }

    Site *site = [self distanceToClosetOffice];
    return site;
}

- (void) updateAllSites:(NSArray*)newAllSites
{
    allSites = [[NSMutableArray alloc] initWithArray:newAllSites];
}

- (void) selectSiteAndOnDone:(void(^)(id))onDone
{    
    onSelectSiteDone = [onDone copy];
    
    AppDelegate *del = appDelegate;

    if ([[APIController shared] checkIfDemo])
    {
        //find a site with has distance in area of 50M
        BOOL isAvailable = NO;
        Site* st = [self selectSite];
        if (st)
        {
            if (st.distance < [Service shared].minAdHocDistance) isAvailable = YES;
        }
        
        if (!isAvailable)
        {
            isTakingCamera = YES;
//            [UIView animateWithDuration:0.3 animations:^{
//                self->vwNotes.frame = CGRectMake(0, 0, 320, self->vwNotes.frame.size.height);
//            }];
//            txtAdhocSite.text = @"";
//            [txtAdhocSite becomeFirstResponder];
            
            UIAlertView* alertViewAskAdhocSiteName = [[UIAlertView alloc] initWithTitle:@"Ad hoc site name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
            alertViewAskAdhocSiteName.alertViewStyle = UIAlertViewStylePlainTextInput;
            alertViewAskAdhocSiteName.tag = 31124;
            [alertViewAskAdhocSiteName show];
            
            return;
        }
    }
    
    Site *it = [self selectSite];
    APIController *api = [APIController shared];
    
    if (it == nil)
    {
        [UIAlertView alertViewTitle:@"Error" andMsg:@"No site retrieved , server unavailable" onOK:^{}];
        
        [api downloadAllSites:^(NSMutableArray *sites)
         {
             if (sites)
             {
                 self->allSites = sites;
             }
         }];
        return;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString  *tmpImgPath = [documentsDirectory stringByAppendingFormat:@"/test.jpg"];
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        APIController *api = [APIController shared];
        [api downloadAllSites:^(NSMutableArray *sites) {
            //NSLog(@"Site: %@", sites);
            if (sites)
            {
                allSites = sites;
            }
            selectedSite = [self selectSite];
            NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:selectedSite, @"selectedSite", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:DID_LOAD_SITES object:self userInfo:dic];
        }];
        
        //    [self.uploading addObject:api];
                
        selectedSite = [self selectSite];
        Photo *photo = [[Photo alloc] init];
        //photo.img = [self fixOrientationOfImage:[info objectForKey:@"UIImagePickerControllerOriginalImage"]];
        photo.img = [UIImage imageWithContentsOfFile:tmpImgPath];
        NSLog(@"SIZE Size : %@",NSStringFromCGSize(photo.img.size));
        
        //    float scale = 320.0/photo.img.size.width;
        //    photo.img = [photo.img scaleToSize:CGSizeMake(photo.img.size.width*scale*2, photo.img.size.height*scale*2)];
        photo.direction = del.direction;
        
        photo.siteID = selectedSite.Name;
        photo.sID = selectedSite.ID;
        photo.imgPath = @"nopath";
        
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateStyle:NSDateFormatterShortStyle];
        [formater setTimeStyle:NSDateFormatterShortStyle];
        [formater setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
        
        photo.date = [formater stringFromDate:[NSDate date]];
        photo.isFinished = NO;
        
        if (self->onSelectSiteDone)
        {
            self->onSelectSiteDone(photo);
        }
//    });
}

#pragma mark- Overlay actions

-(IBAction) takePhoto:(id)sender
{
    NLog(@"-(IBAction) takePhoto:(id)sender");
    [picker takePicture];
}

-(IBAction) gotoPhotoAlbum:(id)sender
{
    NLog(@"Dismiss 7");

    [picker dismissViewControllerAnimated:NO completion:^{
        
    }];
    
    NLog(@"-(IBAction) gotoPhotoAlbum:(id)sender");
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary])
    {
        return;
    }
    
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.view.backgroundColor = [UIColor  blackColor];
    
    NLog(@"Present controller 8");

	[self presentViewController:picker animated:NO completion:^{
        
    }];
}

-(IBAction) cancelCamera:(id)sender
{
    NLog(@"-(IBAction) cancelCamera:(id)sender");
    DLog(@"Dismiss 8");
    [self dismissViewControllerAnimated:NO completion:^{
        self->picker = nil;
    }];
}

-(void)show:(BOOL)isShow
{
    
}

-(IBAction) changeCamera:(id)sender
{
    NLog(@"-(IBAction) changeCamera:(id)sender");
    if (picker.cameraDevice == UIImagePickerControllerCameraDeviceRear)
    {
        picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        UIView *v1 = [customCameraOverlayView3_5 viewWithTag:777];
        UIView *v2 = [customCameraOverlayView4 viewWithTag:777];
        v1.hidden = v2.hidden = YES;
    }else
    {
        picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        UIView *v1 = [customCameraOverlayView3_5 viewWithTag:777];
        UIView *v2 = [customCameraOverlayView4 viewWithTag:777];
        if ([self hasFlash])
        {
            v1.hidden = v2.hidden = NO;
        }
    }
}

-(BOOL)hasFlash
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    BOOL f = [device hasFlash];
    //NSLog(@"\nhas Flash: %d\n", f);
    return f;
}


-(IBAction) changeFlashLightMode:(id)sender
{
    NLog(@"-(IBAction) changeFlashLightMode:(id)sender");
    if (picker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff)
    {
        picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        flashMode4.text = flashMode3_5.text = @"On";
    }else if (picker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn)
    {
        picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        flashMode4.text = flashMode3_5.text = @"Auto";
    }else  if (picker.cameraFlashMode == UIImagePickerControllerCameraFlashModeAuto)
    {
        picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        flashMode4.text = flashMode3_5.text = @"Off";
    }
}

-(void) updateFlashMode
{
    NLog(@"-(IBAction) changeFlashLightMode:(id)sender");
    if (picker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff)
    {
        flashMode4.text = flashMode3_5.text = @"Off";
    }else if (picker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn)
    {
        flashMode4.text = flashMode3_5.text = @"On";
    }else  if (picker.cameraFlashMode == UIImagePickerControllerCameraFlashModeAuto)
    {
        flashMode4.text = flashMode3_5.text = @"Auto";
    }
}

#pragma mark- Photo Actions

-(void)useImage:(UIImage*)image andDidMakeGuide:(BOOL)isMakeGuide andDirection:(NSString*)aDirection andNote:(NSString*)note
{
//    AppDelegate *del = [[UIApplication sharedApplication] delegate];
    CGFloat compression = 0.5f;
    //NSLog(@"\nImage size: %@\n", NSStringFromCGSize(image.size));
    
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateStyle:NSDateFormatterShortStyle];
    [formater setTimeStyle:NSDateFormatterShortStyle];
    [formater setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* sDate = [formater stringFromDate:[NSDate date]];
    NSString *imgName = [NSString stringWithFormat:@"%@_%@_%@_%@.jpg", selectedSite.ID, selectedSite.Name, aDirection, sDate];
    NSString *saveImagePath = [documentsDirectory stringByAppendingPathComponent:imgName];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setBool:NO forKey:imgName];
    NSArray *arr = [def objectForKey:@"SavedPhotos"];
    NSMutableArray *saveArr = [NSMutableArray array];
    
    if (arr)
    {
        [saveArr addObjectsFromArray: arr];
    }
    
    [saveArr insertObject:imgName atIndex:0];
    [def setObject:saveArr forKey:@"SavedPhotos"];
    
    if (isMakeGuide)
    {
        [def setBool:YES forKey:[NSString stringWithFormat:@"guide:%@",imgName]];
        NSString* comm = [NSString stringWithFormat:@"%@_%@",selectedSite.Name,aDirection];
        [[Service shared].refSiteToGuides setObject:imgName forKey:comm];
    }
    
    [def synchronize];
    NSData *data = UIImageJPEGRepresentation(image, compression);
    [data writeToFile:saveImagePath atomically:YES];
        
    //log detail to db
    {
        NSMutableDictionary* md = [NSMutableDictionary dictionary];
        [md setObject:sDate forKey:@"created_at"];
        
        if (!note) note = @"";
        [md setObject:note forKey:@"note"];
        
        [md setObject:[APIController shared].server forKey:@"server"];
        [md setObject:[APIController shared].user forKey:@"user"];
        
        [[Service shared] addNewRecordPath:imgName andData:md];
    }
    
    //NSLog(@"\nsaveImagePath: %@\n", [def objectForKey: @"SavedPhotos"]);
    Photo *p = [[Photo alloc] init];
    p.siteID = selectedSite.Name;
    p.sID = selectedSite.ID;
    p.imgPath = saveImagePath;
    p.direction = aDirection;
    p.date = [[[imgName componentsSeparatedByString:@"_"] objectAtIndex:3] stringByReplacingOccurrencesOfString:@".jpg" withString:@""];
    p.note = note;
    
    {
        CGFloat compression = 0.5f;
//        data = UIImageJPEGRepresentation([UIImage imageWithContentsOfFile:p.imgPath], compression);
        
        ExifContainer *container = [[ExifContainer alloc] init];
        [container addCreationDate:[NSDate date]];
        [container addLocation:appDelegate.locationManager.location];
        
        data = UIImageJPEGRepresentation([appDelegate loadImageOfFile:p.imgPath], compression);
        UIImage* imgWithExif = [UIImage imageWithData:data];
        data = [imgWithExif addExif:container];
        
    }
    
    @autoreleasepool {
        UIImage* imgOri = image;
        if (imgOri.size.width < imgOri.size.height)
            p.imgThumbnail = [imgOri imageByScalingAndCroppingForSize:CGSizeMake(240, 240)];
        else
            p.imgThumbnail = [imgOri imageByScalingAndCroppingForSize:CGSizeMake(240, 240)];
    }
    //p.img = image;
    
    p.isGuide = isMakeGuide;
    p.isFinished = NO;
    [source insertObject:p atIndex:0];
    [self refreshView];
    
    APIController *api = [APIController shared];
    api.photo = p;
//    ASIHTTPRequest *request =
        
    p.isUploading = YES;
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:p,@"Photo", nil];
    [api uploadPhoto:data withInfo:info andCreatedAt:sDate andNote:note andDirection:p.direction andSiteID: p.sID andUpdateBlock:^(id back){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = [[back objectAtIndex:0] floatValue];

         if (progress>= 1.0f)
         {
             NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
             [def setBool:YES forKey:api.photo.imgPath];
             
             api.photo.isFinished = YES;
             [tbPhotos reloadData];
         }
            if (progress < 0)
            {
                [NSTimer timerWithTimeout:10.0 andBlock:^(NSTimer* tmr){
                    [self reuploadFailedPhoto:p];
                }];
            }
        });
     } andBackground:NO];
    
//    [self.uploading addObject:api];
}

-(void)gotoAlbum
{
    //NSLog(@"\nGoto Album....\n");
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary])
    {
        return;
    }
    
    if (vwNotes.frame.origin.y > -1) return;
    if ([[APIController shared] checkIfDemo])
    {
        //find a site with has distance in area of 50M
        BOOL isAvailable = NO;
        Site* st = [self selectSite];
        if (st)
        {
            if (st.distance < [Service shared].minAdHocDistance) isAvailable = YES;
        }
        
        if (!isAvailable)
        {
            isTakingCamera = NO;
    
            [UIView animateWithDuration:0.3 animations:^{
                self->vwNotes.frame = CGRectMake(0, 0, 320, self->vwNotes.frame.size.height);
            }];
            txtAdhocSite.text = @"";
            [txtAdhocSite becomeFirstResponder];
            return;
        }
    }
    
    if(!picker){
        picker = [[ExtImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.showsCameraControls = NO;
        picker.edgesForExtendedLayout = YES;

        picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    }

	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = YES;
	picker.view.backgroundColor = [UIColor  blackColor];
    
    NLog(@"Present controller 1");
	[self presentViewController:picker animated:YES completion:^{
        
    }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //NSLog(@"\nStart rotation\n");
}

-(void)gotoTakePhoto
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");
    
    NLog(@"Goto take photo.....");
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        return;
    }
    
    if (vwNotes.frame.origin.y > -1) return;
    
    sliderGuide4.value = sliderGuide3_5.value = 0.35f;
    
    picker = [[ExtImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.showsCameraControls = NO;
    //picker.wantsFullScreenLayout = YES;
    picker.edgesForExtendedLayout = YES;
    picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    
    if ([UIScreen mainScreen].bounds.size.height == 568)
    {
        picker.cameraOverlayView = customCameraOverlayView4;
        
    }else
    {
        picker.cameraOverlayView = customCameraOverlayView3_5;
    }
    
    self.direction = nil;
    sliderGuide3_5.hidden = sliderGuide4.hidden = YES;
    guide3_5.image = guide4.image = nil;
    guide3_5.hidden = guide4.hidden = YES;
    lbGuide3_5.text = lbGuide4.text = @"No Guide";
    btGuide3_5.userInteractionEnabled = btGuide4.userInteractionEnabled = NO;
    
    
    //error tolerance
    isCapturedPhoto = NO;
    [NSTimer timerWithTimeout:3.0 andBlock:^(NSTimer * tmr){
        if (self->isCapturedPhoto) return;
        
        DLog(@"Dismiss 9");

        [self dismissViewControllerAnimated:NO completion:^{
            NLog(@"Present controller 2");

            [self presentViewController:picker animated:NO completion:^{
//                picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            }];
        }];
    }];
    
    //go show
	picker.view.backgroundColor = [UIColor blackColor];
    
    NLog(@"Present controller 3");

	[self presentViewController:picker animated:YES completion:^{
        picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        [self updateFlashMode];
    }];
    
    UIView *v1 = [customCameraOverlayView3_5 viewWithTag:777];
    UIView *v2 = [customCameraOverlayView4 viewWithTag:777];
    v1.hidden = v2.hidden = YES;

    if ([self hasFlash])
    {
        v1.hidden = v2.hidden = NO;
    }
    
    guide3_5.alpha = guide4.alpha = 0.35f;
    
    //device orientation check
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}


- (void) didOrientation: (id)object
{
    UIInterfaceOrientation interfaceOrientation =  [[UIDevice currentDevice] orientation];
    orientation = interfaceOrientation;
    
    //restore transforms
    {
        UIView *container1 = [btCameraDeivce superview];
        UIView *container2 = [btCameraDeivce4 superview];
        
        container1.transform = CGAffineTransformIdentity;
        container2.transform = CGAffineTransformIdentity;
        guide3_5.transform = CGAffineTransformIdentity;
        guide4.transform = CGAffineTransformIdentity;
        
        btCancel.transform = CGAffineTransformIdentity;
        btTakePhoto.transform = CGAffineTransformIdentity;
        btGotoPhotoAlbum.transform = CGAffineTransformIdentity;
        
        btCancel4.transform = CGAffineTransformIdentity;
        btTakePhoto4.transform = CGAffineTransformIdentity;
        btGotoPhotoAlbum4.transform = CGAffineTransformIdentity;
        
        sliderGuide3_5.transform = CGAffineTransformIdentity;
        sliderGuide4.transform = CGAffineTransformIdentity;

    }
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        NSLog(@"portrait");
        
        UIImage *img = guide3_5.image;
        if ([UIScreen mainScreen].bounds.size.height == 480) {
            img = guide3_5.image;
        }else
        {
            img = guide4.image;
        }
        
        if (img) {
            float scale = [UIScreen mainScreen].bounds.size.width/img.size.width;
            guide3_5.width = guide4.width = img.size.width*scale;
            guide3_5.height = guide4.height = img.size.height*scale;
            guide3_5.left = guide4.left = 0;
            guide3_5.top = ([UIScreen mainScreen].bounds.size.height - 55 - guide3_5.height)/2;
            guide4.top = ([UIScreen mainScreen].bounds.size.height - 113 - guide4.height)/2;
        }
        
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight || interfaceOrientation == UIInterfaceOrientationLandscapeLeft ){
        
        UIView *container1 = [btCameraDeivce superview];
        UIView *container2 = [btCameraDeivce4 superview];
        
        float width = [UIScreen mainScreen].bounds.size.height - (([UIScreen mainScreen].bounds.size.height == 480) ? 55:113);
        float scale = width/320.0;
        
        if (interfaceOrientation == UIInterfaceOrientationLandscapeRight)
        {
            NSLog(@"landscape right");
            //3.5
            container1.transform = CGAffineTransformMakeRotation(M_PI/2.0);
            container1.transform = CGAffineTransformTranslate(container1.transform, 180, -100);
            guide3_5.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI/2.0), scale, scale);

            //4.0
            container2.transform = CGAffineTransformMakeRotation(M_PI/2.0);
            container2.transform = CGAffineTransformTranslate(container2.transform, 180, -100);
            guide4.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI/2.0), scale, scale);
            
            btCancel.transform = CGAffineTransformMakeRotation(M_PI/2.0);
            btTakePhoto.transform = CGAffineTransformMakeRotation(M_PI/2.0);
            btGotoPhotoAlbum.transform = CGAffineTransformMakeRotation(M_PI/2.0);
            
            btCancel4.transform = CGAffineTransformMakeRotation(M_PI/2.0);
            btTakePhoto4.transform = CGAffineTransformMakeRotation(M_PI/2.0);
            btGotoPhotoAlbum4.transform = CGAffineTransformMakeRotation(M_PI/2.0);
            
        }else
        {
            
            NSLog(@"landscape left");

            sliderGuide3_5.transform = CGAffineTransformMakeRotation(-M_PI);
            sliderGuide4.transform = CGAffineTransformMakeRotation(-M_PI);

            //3.5
            container1.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
            container1.transform = CGAffineTransformTranslate(container1.transform, -180, -100);
            guide3_5.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI/2.0), scale, scale);
            
            //4.0
            container2.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
            container2.transform = CGAffineTransformTranslate(container2.transform, -180, -100);
            guide4.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI/2.0), scale, scale);
            
            
            btCancel.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
            btTakePhoto.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
            btGotoPhotoAlbum.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
            
            btCancel4.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
            btTakePhoto4.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
            btGotoPhotoAlbum4.transform = CGAffineTransformMakeRotation(-M_PI/2.0);

        }

    }
    
}

#pragma mark ALERT DIRECTION
- (void) alertForDirectionWithOnDone:(void(^)(id))onDone
{
    // try to search in guide
    NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
    NSArray *guidePhotos = [userDefault objectForKey:@"SavedPhotos"];
    NSMutableDictionary* guideDict = [[NSMutableDictionary alloc] init];
    Site *site= [self selectSite];
    
    if (guidePhotos && site) {
        for (NSString *imgName in guidePhotos) {
             NSArray *com = [imgName componentsSeparatedByString:@"_"];
            NSString* siteId = [com objectAtIndex:0];
            NSString* photoDirection = [com objectAtIndex:2];
            if ([userDefault boolForKey:[NSString stringWithFormat:@"guide:%@",imgName]] && [site.ID isEqualToString:siteId])
            {
                [guideDict setObject:imgName forKey:[photoDirection uppercaseString]];
                continue;
            }
        }
    }

    // search from downloaded guide photos
    guidePhotos = [userDefault objectForKey:@"GuidePhotos"];
    if (guidePhotos) {
        for (NSMutableDictionary  *dict in guidePhotos) {
            if([[dict objectForKey:@"SiteId"] isEqualToString:site.ID] && [[dict objectForKey:@"IsGuide"] boolValue]){
                [guideDict setObject:dict forKey:[[dict objectForKey:@"Direction"] uppercaseString]];
            }

        }
    }
    
    UIView* contentView = [[[NSBundle mainBundle] loadNibNamed:@"DirectionAlertView" owner:self options:nil] objectAtIndex:0];
    contentView.layer.cornerRadius = 7;
    contentView.layer.masksToBounds = YES;
//    self.onAskDirectionDone = onDone;
//    alertAskDirection = [[UIAlertView alloc] initWithTitle:@"" message:@"Please select a direction" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
//    alertAskDirection.tag = 989;
//    [alertAskDirection setValue:contentView forKey:@"accessoryView"];
//    alertAskDirection.backgroundColor = [UIColor blackColor];
//    
//    [alertAskDirection show];
    
    directionAlertView = [[CustomIOSAlertView alloc] init];
    
    // Add some custom content to the alert view
    
    // North, South, East, West, Point
    for (int i = 0; i < 5; i++) {
        UIButton* btn = [contentView viewWithTag:i + 1];
        [btn addTarget:self action:@selector(chooseDirection:) forControlEvents: UIControlEventTouchUpInside];
        
        BOOL hasGuide = (i == 0 && [guideDict objectForKey:@"NORTH"])
                        | (i == 1 && [guideDict objectForKey:@"SOUTH"])
                        | (i == 2 && [guideDict objectForKey:@"EAST"])
                        | (i == 3 && [guideDict objectForKey:@"WEST"])
                        | (i == 4 && [guideDict objectForKey:@"PHOTO POINT"]);
        
        if(hasGuide)
        {
            [btn setBackgroundColor:UIColorFromRGB(0x4f7a28)];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }

    }

    [directionAlertView setContainerView:contentView];
    directionAlertView.buttonTitles = nil;
    [directionAlertView setUseMotionEffects:true];
    directionAlertView.backgroundColor = UIColorFromRGB(0xeeeeee);
    [directionAlertView show];
}

-(void)chooseDirection:(id) sender
{
    NSArray* arr = @[btN,btS,btE,btW,btP];
    NSInteger buttonIndex = ((UIButton*) sender).tag;
    [self selectDirection:[arr objectAtIndex:buttonIndex - 1]];
    if (self.onAskDirectionDone) self.onAskDirectionDone(nil);
    [directionAlertView close];
}

- (void)customIOS7dialogButtonTouchUpInside: (CustomIOSAlertView *)alertView clickedButtonAtIndex: (NSInteger)buttonIndex
{
    NSLog(@"Delegate: Button at position %d is clicked on alertView %d.", (int)buttonIndex, (int)[alertView tag]);
    [alertView close];
}

- (UIView *)createDemoView
{
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 270, 180)];
    [imageView setImage:[UIImage imageNamed:@"demo"]];
    [demoView addSubview:imageView];
    
    return demoView;
}

- (void) redownloadImages
{
    if (!dateLastRedownloadImage)
    {
        dateLastRedownloadImage = [NSDate date];
    }
    
    if (dateLastRedownloadImage && fabs([dateLastRedownloadImage timeIntervalSinceNow]) < 10.0)
    {
        if (!tmrRedownloadImage)
        {
            tmrRedownloadImage = [NSTimer timerWithTimeout:10.0 andBlock:^(NSTimer *t) {
                self->tmrRedownloadImage = nil;
                [self redownloadImages];
            }];
        }
        return;
    }
    
    dateLastRedownloadImage = [NSDate date];
    tmrRedownloadImage = nil;
    
    //check
    BOOL isShouldRedownload = NO;
    for (NSString* s in self.lstPhotoNeedDownload)
    {
        if (![self.lstPhotoBeingDownloaded containsObject:s])
        {
            isShouldRedownload = YES;
            break;
        }
    }
    
    if (isShouldRedownload)
    {
        NSArray* sites = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"ListOfGuideSites_%@_%@",[[APIController shared].currentProject objectForKey:@"uid"],[APIController shared].server]];
        [self reloadOldDataFromServer:sites];
    }
}

- (void) refreshView
{
    if ((dateLastRefreshView && fabs([dateLastRefreshView timeIntervalSinceNow]) < 1.0)
        || (tbPhotos.isDragging || tbPhotos.isDecelerating)
        )
    {
        if (!tmrRefreshView)
        {
            tmrRefreshView = [NSTimer timerWithTimeout:1.0 andBlock:^(NSTimer *t) {
                self->tmrRefreshView = nil;
                [self refreshView];
            }];
        }
        
        return;
    }
    
    dateLastRefreshView = [NSDate date];
    tmrRefreshView = nil;

    if ([APIController shared].currentProject)
    {
        self.title = [[APIController shared].currentProject objectForKey:@"name"];
        
        if (allSites.count > 0)
        {
            NSString* prjID = [[APIController shared].currentProject objectForKey:@"uid"];
            
            //filter all sites whose project id of current
            NSMutableArray* filteredSiteIDs = [NSMutableArray array];
            for (Site* site in allSites)
            {
                if ([site.ProjectID isEqualToString:prjID])
                {
                    [filteredSiteIDs addObject:site.ID];
                }
            }
            
            //filter all photo belong to filtered sites
            NSMutableArray* filteredPhotos = [NSMutableArray array];
            NSMutableArray* filteredPhotoIDs = [NSMutableArray array];
            for (Photo* p in self->source)
            {
                if ([filteredSiteIDs containsObject:p.sID] && ![filteredPhotoIDs containsObject:p.photoID])
                {
                    [filteredPhotos addObject:p];
                    if(p.photoID)
                    {
                        [filteredPhotoIDs addObject:p.photoID];
                    }
                }
            }
            
            {
                [lstObjsForTbPhotos removeAllObjects];
                [lstObjsForTbPhotos addObjectsFromArray:filteredPhotos];
                [tbPhotos reloadData];
            }
        }
    }
}

#pragma mark PRIVATE
- (void) reuploadFailedPhoto:(Photo*)p
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!p.isFinished)
        {
            NSData *data = nil;
            if (!p.imageData)
            {
                CGFloat compression = 0.5f;
                
                ExifContainer *container = [[ExifContainer alloc] init];
                [container addCreationDate:[NSDate date]];
                [container addLocation:appDelegate.locationManager.location];
                
                NSData *data = UIImageJPEGRepresentation([appDelegate loadImageOfFile:p.imgPath], compression);
                UIImage* imgWithExif = [UIImage imageWithData:data];
                data = [imgWithExif addExif:container];
                
                p.imageData = data;
            }
            else
            {
                data = p.imageData;
            }
            
            APIController *api = [APIController shared];
            api.photo = p;
            p.isUploading = YES;
            
            id d = [[Service shared] getDataOfRecordPath:[p.imgPath lastPathComponent]];
            NSString* sDate = [d objectForKey:@"created_at"];
            NSString* note = [d objectForKey:@"note"];
            
            NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:p,@"Photo", nil];            
            [api uploadPhoto:data withInfo:info andCreatedAt:sDate andNote:note andDirection:p.direction andSiteID: p.sID andUpdateBlock:^(id back){
                dispatch_async(dispatch_get_main_queue(), ^{
                    float progress = [[back objectAtIndex:0] floatValue];

//
//                     int i = [source indexOfObject: api.photo];
//                     if (progress<0)
//                     {
//                         p.isUploading = NO;
//                     }
//                     
//                     api.photo.progress = progress;
//                     NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
//                     PhotoCell *cell = (PhotoCell*)[tbPhotos cellForRowAtIndexPath: index];
//                     if (cell)
//                     {
//                         cell.progress.hidden = NO;
//                         cell.progress.progress = progress;
//                     }
//                     
                     if (progress>= 1.0f)
                     {
                         NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
                         [def setBool:YES forKey:api.photo.imgPath];
                         
                         p.imageData = nil;
                         api.photo.isFinished = YES;
                         [tbPhotos reloadData];
                     }
                    
                    if (progress < 0)
                    {
                        [NSTimer timerWithTimeout:20.0 andBlock:^(NSTimer* tmr){
                            [self reuploadFailedPhoto:p];
                        }];
                    }
                });
                
             } andBackground:NO];
        }
    });
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    if (alertView != alertAskDirection) return;
    
    NSArray* arr = @[btN,btS,btE,btW,btP];
    [self selectDirection:[arr objectAtIndex:buttonIndex]];
    if (self.onAskDirectionDone) self.onAskDirectionDone(nil);
}

#pragma mark SELECTOR

- (void) onNoteDone:(id)sender
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");
    if (appDelegate.newestUserLocation.coordinate.latitude == 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"Require location" message:@"We can't see your location. Please turn location services on in your Settings!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }

    NSString* name = [txtAdhocSite.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (name.length < 1)
    {
        [UIAlertView alertViewTitle:@"Require" andMsg:@"Please provide valid Ad hoc site name" onOK:^{
            UIAlertView* alertViewAskAdhocSiteName = [[UIAlertView alloc] initWithTitle:@"Ad hoc site name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
            alertViewAskAdhocSiteName.alertViewStyle = UIAlertViewStylePlainTextInput;
            alertViewAskAdhocSiteName.tag = 31124;
            [alertViewAskAdhocSiteName show];

        }];
    }
    else
    {
        if (![[Service shared] checkIfSiteNameAvailable:name])
        {
            [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"The name '%@' not available, please select other",name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }

//        [UIView animateWithDuration:0.3 animations:^{
//            self->vwNotes.frame = CGRectMake(0, -300, 320, self->vwNotes.frame.size.height);
//        }];
//        [txtAdhocSite endEditing:YES];
        
        AppDelegate *del = appDelegate;
        
        //find a site with has distance in area of 50M
        BOOL isAvailable = NO;
        Site* st = [self selectSite];
        if (st)
        {
            if (st.distance < [Service shared].minAdHocDistance) isAvailable = YES;
        }
        
        //no site found
        //create new adhoc site
        if (!isAvailable)
        {
            NSMutableDictionary* d = [NSMutableDictionary dictionary];
            [d setObject:[[Service shared] getNonce] forKey:@"ID"];
            [d setObject:name forKey:@"Name"];
            [d setObject:[NSNumber numberWithDouble:del.newestUserLocation.coordinate.longitude] forKey:@"Longitude"];
            [d setObject:[NSNumber numberWithDouble:del.newestUserLocation.coordinate.latitude] forKey:@"Latitude"];
            [d setObject:@"1" forKey:@"ProjectID"];
            [[Service shared] addNewAdHocSiteWithData:d];
            
            [self updateAllSites:[[Service shared] getAllSiteModels]];
        }
        
        st = [self selectSite];
        
        [self selectSiteAndOnDone:onSelectSiteDone];
    }
}

- (void) onNoteCancel:(id)sender
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

//    [UIView animateWithDuration:0.3 animations:^{
//        self->vwNotes.frame = CGRectMake(0, -300, 320, self->vwNotes.frame.size.height);
//    }];
//    [txtAdhocSite endEditing:YES];
}

- (void) onNotifyAppDidActive:(NSNotification*)notify
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    [self refreshView];
}

- (void) onNotifyUploadProgress:(NSNotification*)notify
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    Photo* photo = [[notify.object objectForKey:@"info"] objectForKey:@"Photo"];
    float progress = [[notify.object objectForKey:@"percent"] floatValue];

    photo = [imgPathPhotos objectForKey:photo.imgPath];
    if (!photo) return;
    
    PhotoCell* cell = photo.view;
    NSUInteger i = [source indexOfObject:photo];
    NLog(@"index %d progress %.2f",i,progress);

    if (progress < 0)
    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Failed" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
//        [alert show];
        photo.isUploading = NO;
        NLog(@"Schedule for reupload");
        [NSTimer timerWithTimeout:10.0 andBlock:^(NSTimer* tmr){
            [self reuploadFailedPhoto:photo];
        }];
//        [scheduledReuploads addObject:tmr];
        return;
    }
    
    if (progress >= 1.0f)
    {        
        NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
        
        [def setObject:[NSNumber numberWithBool:YES] forKey:[photo.imgPath lastPathComponent]];
        [def synchronize];
        
        photo.isFinished = YES;
        [self refreshView];
        
        id response = [notify.object objectForKey:@"response"];
        if (response && [response objectForKey:@"ID"])
        {
            photo.photoID = [response objectForKey:@"ID"];
            photo.projectID = [response objectForKey:@"ProjectId"];
            
            Photo* item = [source objectAtIndex:i];
            item.photoID = [response objectForKey:@"ID"];
            item.projectID = [response objectForKey:@"ProjectId"];
            
            id obj2 = [[Service shared] getDataOfRecordPath:[photo.imgPath lastPathComponent]];
            [obj2 setObject:[response objectForKey:@"ID"] forKey:@"photoID"];
            [[Service shared] updateRecordPath:[photo.imgPath lastPathComponent] andData:obj2];
        }
    }
    else
    {
        photo.progress = progress;
        cell.progress.hidden = NO;
        cell.progress.progress = progress;
    }
}

- (void) onNotifyUploadFailed:(NSNotification*)notify
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

}

- (void) onNotifyUploadCompleted:(NSNotification*)notify
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

}

- (void) onNotifyUploadInBackground:(NSNotification*)notify
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

//    NLog(@"STOP ALL REUPLOADS");
//    for (NSTimer* tmr in scheduledReuploads)
//    {
//        [tmr invalidate];
//    }
//    [scheduledReuploads removeAllObjects];
}

- (void) onStartCapture : (NSNotification*) notify
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->isCapturedPhoto = YES;
        NLog(@"Capturing...");
    });
}

- (void) onNotifyAdhocSitesGetChanged:(NSNotification*)notify
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    [self refresh];
    DLog(@"call refresh");
}

- (void) onNotifyAppWillChangeOrientation:(NSNotification*) notify
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");

    int itf = [notify.object intValue];
    if (itf == UIInterfaceOrientationPortrait || itf == UIInterfaceOrientationPortraitUpsideDown)
    {
    }
    else
    {
    }
}

- (void) onNotifAppDidUpdateNewLocation:(NSNotification*)notif
{
    //only work when picker controller presenting and user selectec direction
    if (self.presentedViewController && [self.presentedViewController isKindOfClass:[UIImagePickerController class]] && self.direction != nil)
    {
        NSString* c = [self.direction substringToIndex:1];
        [self selectDirection:c];
    }
}

- (void) onNotifAppDidRefreshGuidePhotos:(NSNotification*) notif
{
    [self refreshView];
}

- (void) onTouchNavItemSetting:(id)sender
{
    SettingViewController* controllerSetting = [[SettingViewController alloc] init];
    __weak MainViewController* weakSelf = self;
    __weak SettingViewController* weakControllerSetting = controllerSetting;
    
//    controllerSetting.onDidMoveOut = ^(id back){
//    };
    
    controllerSetting.onDidTouchNavItemDone = ^(id back){
        [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
        
        weakControllerSetting.onDidTouchNavItemDone = nil;
        weakControllerSetting.onDidTouchSettingCmd = nil;
    };
    
    controllerSetting.onDidTouchSettingCmd = ^(id obj){
    
        NSString* cmd = [obj objectForKey:@"cmd"];
        
        if ([cmd isEqualToString:@"Info"])
        {
            InfoViewController* ctrl  = [[InfoViewController alloc] init];
            __weak InfoViewController* weakCtrl = ctrl;
            
            ctrl.onDidTouchNavItemBack = ^(id b){
                [weakControllerSetting.navigationController popViewControllerAnimated:YES];
                weakCtrl.onDidTouchNavItemBack = nil;
            };
            [ctrl setup];
            
            [weakControllerSetting.navigationController pushViewController:ctrl animated:YES];            
        }
        else if ([cmd isEqualToString:@"Donate"])
        {
            [weakSelf wenDonate:nil];
        }
        else if ([cmd isEqualToString:@"Reminder"])
        {
//            [weakSelf wenTouchReminder:nil];
            ReminderViewController *control = [ReminderViewController shared];
            
             __weak ReminderViewController* weakControl = control;
            control.onDidTouchNavItemBack = ^(id b){
                [weakControllerSetting.navigationController popViewControllerAnimated:YES];
                weakControl.onDidTouchNavItemBack = nil;
            };
            control.mainController = self;
            
            [weakControllerSetting.navigationController pushViewController:control animated:YES];

        }
        else if ([cmd isEqualToString:@"ManageAdhoc"])
        {
            AdhocSitesViewController* ctrl = [[AdhocSitesViewController alloc] init];
            ctrl.allSites = allSites;
            __weak AdhocSitesViewController* weakCtrl = ctrl;
            
            ctrl.onDidTouchNavItemBack = ^(id b){
                [weakControllerSetting.navigationController popViewControllerAnimated:YES];
                weakCtrl.onDidTouchNavItemBack = nil;
            };

            [weakControllerSetting.navigationController pushViewController:ctrl animated:YES];
        }
        else if ([cmd isEqualToString:@"Logout"])
        {
            [weakSelf logout:nil];
        }
        else if ([cmd isEqualToString:@"RefreshGuides"])
        {
            NSArray* sites = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"ListOfGuideSites_%@_%@",[[APIController shared].currentProject objectForKey:@"uid"],[APIController shared].server]];
            [self reloadOldDataFromServer:sites];
            
            weakControllerSetting.onDidTouchNavItemDone(nil);
        }
    };
    
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:controllerSetting];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void) onNotifProjectsDidRefresh:(NSNotification*)notif
{
    [lstObjsForTbPhotos removeAllObjects];
    [tbPhotos reloadData];
    [self reloadAll];
}

-(void) reloadTable
{
    [tbPhotos reloadData];
}
@end
