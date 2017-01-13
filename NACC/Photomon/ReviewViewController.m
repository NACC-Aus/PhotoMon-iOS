
#import "ReviewViewController.h"
#import "MainViewController.h"

@interface ReviewViewController ()
@end

@implementation ReviewViewController
@synthesize photo, source;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andSourcePhoto:(NSArray*)source_ andImage:(Photo*)photo_ andBlock:(ReturnBlock)finished
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.source = source_;
        self.photo = photo_;
        retBlock = [finished copy];
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
        
        self.navigationItem.leftBarButtonItem = cancel;
        self.navigationItem.rightBarButtonItem = save;
        self.title = self.photo.siteID;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoadAllSites:) name:DID_LOAD_SITES object:nil];
    }
    return self;
}

-(void)didLoadAllSites:(NSNotification*)notify
{
    //NSLog(@"\n-(void)didLoadAllSites:(NSNotification*)notify.....\n");
    Site *site = [[notify userInfo] objectForKey:@"selectedSite"];
    self.photo.siteID = site.Name;
    self.photo.sID = site.ID;
    self.title = self.photo.siteID;
}

-(void)cancel:(id)sender
{
    //NSLog(@"\n-(void)cancel:(id)sender\n");
    DLog(@"Dismiss 10");

    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

-(void)save:(id)sender
{
    
    [self onNoteDone:nil];
    //NSLog(@"\n-(void)save:(id)sender\n");
    retBlock(self.photo);
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect frameRect = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);
    self.view.frame = frameRect;
    
    scrollView2 = [[UIScrollView alloc] initWithFrame: [UIScreen mainScreen].bounds];
    
    holder = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:holder];
    holder.backgroundColor = [UIColor blackColor];
    [holder addSubview: scrollView2];
    
    [self.view sendSubviewToBack:holder];
    
    // Do any additional setup after loading the view from its nib.
    imgCapturedPhoto.image = self.photo.img;
    float rate = 320.0/self.photo.img.size.width;
    imgCapturedPhoto.width = self.photo.img.size.width*rate;
    imgCapturedPhoto.height = self.photo.img.size.height*rate;
    imgCapturedPhoto.top = 0;
    imgCapturedPhoto.left = 0;
//  imgCapturedPhoto.hidden = YES;
    
    lbTimeDirection.text = [NSString stringWithFormat:@"%@\n%@", self.photo.direction, self.photo.date];
    lbTimeDirection.textColor = [UIColor whiteColor];
    imgBackgroundImage.backgroundColor = [UIColor blackColor];
    imgBackgroundImage.alpha = 0.5;
//    [btMakeGuide addTarget:self action:@selector(makeGuide:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    tap.delegate = self;
    [holder setGestureRecognizers:@[tap]];
    
    [btViewPhoto addTarget:self action:@selector(onTap2:) forControlEvents:UIControlEventTouchUpInside];
    viewOverlay.backgroundColor = [UIColor blackColor];
    viewOverlay.top = self.view.height - viewOverlay.height;
    self.view.backgroundColor = [UIColor blackColor];
    scroll2ImageView.hidden = YES;
    if (self.photo.img.size.width > self.photo.img.size.height)
    {
        imgCapturedPhoto.centerY = self.view.height /2 - viewOverlay.height/2;
    }
    
    if ([UIScreen mainScreen].bounds.size.height == 480)
    {
        vwNotes.frame = CGRectMake(0, -300, 320, 244 - 88);
    }
    else
    {
        vwNotes.frame = CGRectMake(0, -300, 320, 244);
    }
    
    toolBarNotes = [[UIToolbar alloc] init];
    toolBarNotes.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* btDone = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onNoteDone:)];
    [toolBarNotes setItems:@[bt,btDone]];
    txtViewNotes.inputAccessoryView = toolBarNotes;
    [toolBarNotes sizeToFit];
    
    txtAdhocSite.inputAccessoryView = toolBarNotes;
    guideSlider.minimumValue = 0;
    guideSlider.maximumValue = 1;
    [guideSlider setValue:0];
    
    guidePhoto.frame = imgCapturedPhoto.frame;
    guidePhoto.size = imgCapturedPhoto.size;
    guidePhoto.center = imgCapturedPhoto.center;
    
    if(self.guideImage)
    {
        guidePhoto.alpha = 0;
        guidePhoto.hidden = NO;
        guidePhoto.image = self.guideImage;
        guideSlider.hidden = NO;
    }else
    {
        guideSlider.hidden = YES;
        guidePhoto.hidden = YES;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:guidePhoto] || [touch.view isDescendantOfView:guideSlider]) {
        return NO;
    }
    
    return YES;
}

-(void)onTap:(UITapGestureRecognizer*)tap
{
    holder.hidden = YES;
    [self.view sendSubviewToBack:scrollView2];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:NO];
}

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return scroll2ImageView;
}

-(void)onTap2:(UITapGestureRecognizer*)tap
{
    holder.hidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:YES];
    
    [self.view bringSubviewToFront: holder];
    [scrollView2 setBackgroundColor:[UIColor blackColor]];
    [scrollView2 setCanCancelContentTouches:NO];
    scrollView2.clipsToBounds = YES; // default is NO, we want to restrict drawing within our scrollview
    scrollView2.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    scroll2ImageView = [[UIImageView alloc] initWithImage:imgCapturedPhoto.image];
    [scrollView2 removeAllSubviews];
    [scrollView2 addSubview:scroll2ImageView];
    [scrollView2 setContentSize:CGSizeMake(scroll2ImageView.frame.size.width, scroll2ImageView.frame.size.height)];
    scrollView2.minimumZoomScale = 320.0/imgCapturedPhoto.image.size.width;
    scrollView2.maximumZoomScale = 3;
    scrollView2.delegate = self;
    [scrollView2 setScrollEnabled:YES];
    scrollView2.frame = [UIScreen mainScreen].bounds;
    [scrollView2 setZoomScale:320.0/imgCapturedPhoto.image.size.width];
    scrollView2.width = 320;
    scrollView2.height = (320.0/imgCapturedPhoto.image.size.width)*imgCapturedPhoto.image.size.height;
    scrollView2.centerY = [UIScreen mainScreen].bounds.size.height/2.0;
}

-(void)removeGuide:(Photo*)aPhoto
{    
    for (Photo *pt in source)
    {
        if ([pt.sID isEqualToString:aPhoto.sID] && [pt.direction isEqualToString: aPhoto.direction])
        {
            pt.isGuide = NO;
            NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
            [def removeObjectForKey:[NSString stringWithFormat:@"guide:%@",[pt.imgPath lastPathComponent]]];
//            [def setBool:NO forKey: [NSString stringWithFormat:@"guide:%@",[pt.imgPath lastPathComponent]]];
            [def synchronize];

            NSString* comm = [NSString stringWithFormat:@"%@_%@",pt.siteID,pt.direction];
            if (pt.isGuide)
            {
                [[Service shared].refSiteToGuides setObject:[pt.imgPath lastPathComponent] forKey:comm];
            }
            else
            {
                [[Service shared].refSiteToGuides removeObjectForKey:comm];
            }
            
            [[Service shared] deleteRecordPath:[pt.imgPath lastPathComponent]];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NLog(@"Async 3");

                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *imgName = [NSString stringWithFormat:@"%@_%@.jpg", pt.sID, pt.direction];
                NSString *saveImagePath = [documentsDirectory stringByAppendingPathComponent:imgName];
                
                [[NSFileManager defaultManager] removeItemAtPath:saveImagePath error:nil];
            });
        }
    }
}

-(void)makeGuide:(UIButton*)sender
{
    CGFloat compression = 0.5f;
    //NSLog(@"\nImage size: %@\n", NSStringFromCGSize(imgCapturedPhoto.image.size));
	NSData *data = UIImageJPEGRepresentation(imgCapturedPhoto.image, compression);
    //NSLog(@"\nself.photo.direction: %@\n", self.photo.direction);

    Photo *pt = self.photo;
    if (!pt.isGuide)
    {
        [self removeGuide:pt];
        pt.isGuide = YES;
      
        
        [sender setTitle:@"Remove Guide" forState:UIControlStateNormal];
        
    }else
    {
        [sender setTitle:@"Make Guide" forState:UIControlStateNormal]; 
        pt.isGuide = NO;
      
    }
}

- (IBAction) wenNote:(id)sender
{
    [txtAdhocSite setHidden:YES];
    [txtViewNotes setHidden:NO];
    
    if (vwNotes.frame.origin.y < 0)
    {
        [UIView animateWithDuration:0.3 animations:^{
            self->vwNotes.frame = CGRectMake(0, 0, 320, self->vwNotes.frame.size.height);
        }];
        [txtViewNotes becomeFirstResponder];
    }
}

- (IBAction)guideAlphaChanged:(id)sender {
    guidePhoto.alpha = guideSlider.value;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark SELECTORS
- (void) onNoteDone:(id)sender
{
    if (appDelegate.newestUserLocation.coordinate.latitude == 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"Require location" message:@"We can't see your location. Please turn location services on in your Settings!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    if (!txtViewNotes.hidden)
    {
        [UIView animateWithDuration:0.3 animations:^{
            self->vwNotes.frame = CGRectMake(0, -300, 320, self->vwNotes.frame.size.height);
        }];
        [txtViewNotes endEditing:YES];
        self.photo.note = txtViewNotes.text;
    }
    else if (!txtAdhocSite.hidden)
    {
        NSString* name = [txtAdhocSite.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (name.length < 1)
        {
            [[[UIAlertView alloc] initWithTitle:@"Require" message:@"Please provide Adhoc site name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];            
        }
        else
        {
            if (![[Service shared] checkIfSiteNameAvailable:name])
            {
                [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"The name '%@' not available, please select other",name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                return;
            }

            [UIView animateWithDuration:0.3 animations:^{
                self->vwNotes.frame = CGRectMake(0, -300, 320, self->vwNotes.frame.size.height);
            }];
            [txtAdhocSite endEditing:YES];
            
            AppDelegate *del = appDelegate;
            
            //find a site with has distance in area of 50M
            BOOL isAvailable = NO;
            Site* st = [self.controllerMain selectSite];
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
                
                [self.controllerMain updateAllSites:[[Service shared] getAllSiteModels]];
            }
            
            st = [self.controllerMain selectSite];
            
            retBlock(self.photo);
        }
    }
}

@end
