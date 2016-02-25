
#import "TimerWithBlock.h"
#import "ViewSavedPhotosViewController.h"
#import "AlertViewWithBlock.h"

@interface ViewSavedPhotosViewController ()

@end

@implementation ViewSavedPhotosViewController

@synthesize photos;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andPhotos:(NSMutableArray*)photos_ andSelectedIndex:(int)index
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.photos = [NSArray arrayWithArray:photos_];
        self.title = @"Photo";
        if ([APIController shared].currentProject)
        {
            self.title = [[APIController shared].currentProject objectForKey:@"name"];
        }

        currentIndex = index;
        
        self.imgThumbnail = [UIImage imageNamed:@"thumnail.png"];
        [self preloadImgToStore:index];
    }
    return self;
}

- (void) preloadImgToStore:(int)idx
{
    if (!storeImgs)
    {
        storeImgs = [[NSMutableDictionary alloc] init];
    }

    int limit = 8;
    int a = idx - limit;
    int b = idx + limit;
    for (int i = 0 ; i < self.photos.count;i++)
    {
        NSString* path = ((Photo*)[self.photos objectAtIndex:i]).imgPath;
        if (!path) continue;
        
        if (i >= a && i <= b)
        {
            if (![storeImgs objectForKey:path])
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    UIImage* img = [appDelegate loadImageOfFile:path];// [UIImage imageWithContentsOfFile:path];
                    if (!img) {
                        img = self.imgThumbnail;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [storeImgs setObject:img forKey:path];
                    });
                });
            }
            else
            {
                UIImage* img_ = [storeImgs objectForKey:path];
                if (img_ == self.imgThumbnail)
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        UIImage* img = [appDelegate loadImageOfFile:path];// [UIImage imageWithContentsOfFile:path];
                        if (img)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [storeImgs setObject:img forKey:path];
                            });
                        }
                    });
                }
            }
        }
        else
        {
            [storeImgs removeObjectForKey:path];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    CGRect frameRect = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);
    self.view.frame = frameRect;
    scrollView2 = [[UIScrollView alloc] initWithFrame: [UIScreen mainScreen].bounds];
    [self.view addSubview: scrollView2];

    //NSLog(@"\nframe: %@\n", NSStringFromCGRect(frameRect));
	horizontalView	= [[EasyTableView alloc] initWithFrame:frameRect numberOfColumns:self.photos.count ofWidth: 320];
	horizontalView.delegate						= self;
	horizontalView.tableView.backgroundColor	= [UIColor whiteColor];
	horizontalView.tableView.allowsSelection	= YES;
	horizontalView.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    horizontalView.tableView.pagingEnabled = YES;
	horizontalView.cellBackgroundColor			= [UIColor darkGrayColor];
	horizontalView.autoresizingMask				= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:horizontalView];
    [horizontalView selectCellAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Note" style:UIBarButtonItemStyleBordered target:self action:@selector(onNote:)];
    
    toolBarNotes = [[UIToolbar alloc] init];
    toolBarNotes.barStyle = UIBarStyleBlackTranslucent;
    
    UIBarButtonItem* btCancel2 = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(onNoteCancel:)];
    UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* btDone = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onNoteDone:)];
    [toolBarNotes setItems:@[btCancel2, bt,btDone]];
    [toolBarNotes sizeToFit];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)dealloc
{
    NLog(@"RELEASE %@",NSStringFromClass([self class]));
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    //NSLog(@"\nContent size: %@\n", NSStringFromCGSize(scrollView.contentSize));
}

-(void)onTap:(UITapGestureRecognizer*)tap
{
    [self.view sendSubviewToBack:scrollView2];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];    
    [self.navigationController setNavigationBarHidden:NO];
}

- (BOOL) isGuideAvailableForSite:(NSString*)siteID andDirection:(NSString*)direction andNotPhoto:(Photo*)photo
{
    for (Photo *pt in photos)
    {
        if (pt == photo) continue;
        
        if ([pt.siteID isEqualToString:siteID] && [pt.direction isEqualToString:direction])
        {
            if (pt.isGuide) return YES;
        }
    }
    
    return NO;
}

- (void) refreshView
{
    if ((dateLastRefreshView && fabsf([dateLastRefreshView timeIntervalSinceNow]) < 2.0)
        || (horizontalView.tableView.isDragging || horizontalView.tableView.isDecelerating)
        )
    {
        if (!tmrRefreshView)
        {
            tmrRefreshView = [NSTimer timerWithTimeout:2.0 andBlock:^(NSTimer *t) {
                self->tmrRefreshView = nil;
                [self refreshView];
            }];
        }
        return;
    }
    
    dateLastRefreshView = [NSDate date];
    tmrRefreshView = nil;
    
    [horizontalView reloadData];
//    [self easyTableView:horizontalView setDataForView:currentView forIndexPath:currentIndexPath];
}

-(void)saveToRoll:(UIButton*)sender
{
    //NSLog(@"\n-(void)saveToRoll:(UIButton*)sender\n");
    // Image to save
    // Request to save the image to camera roll
    
    UIButton *bt = (UIButton*)sender;
    UIImageView *img = (UIImageView*)[[bt superview] viewWithTag:7777];
    UILabel *indexLabel = (UILabel*) [img viewWithTag:999];
    int index = [indexLabel.text intValue];
    Photo *pt = [photos objectAtIndex:index];
//    UIImageWriteToSavedPhotosAlbum([UIImage imageWithContentsOfFile:pt.imgPath], self,
//                                   @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    UIImageWriteToSavedPhotosAlbum([appDelegate loadImageOfFile:pt.imgPath], self,
                                   @selector(image:didFinishSavingWithError:contextInfo:), nil);

}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo
{
    // Was there an error?
    if (error != NULL)
    {
        // Show error message...
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Save failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    else  // No errors
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Save successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}

-(void)deletePhoto:(UIButton*)sender
{
    //NSLog(@"\n-(void)deletePhoto:(UIButton*)sender\n");
    UIButton *bt = (UIButton*)sender;
    UIImageView *img = (UIImageView*)[[bt superview] viewWithTag:7777];
    UILabel *indexLabel = (UILabel*)[img viewWithTag:999];
    int index = [indexLabel.text intValue];
    
    Photo *pt = [self.photos objectAtIndex:index];
    if (pt.isGuide)
    {
        [UIAlertView alertViewTitle:nil andMsg:@"Guide pictures can’t be deleted. To delete this picture, please select “Remove Guide” before deleting" onOK:^{}];
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete" message:@"Are you sure you would like to delete this photo?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    
    [alert show];
    alert.tag = index;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    if (buttonIndex == 1)
    {
        //NSLog(@"");
        Photo *pt = [self.photos objectAtIndex:alertView.tag];
        
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        NSMutableArray *arr = [NSMutableArray arrayWithArray:[def objectForKey:@"SavedPhotos"]];
        if (arr)
        {
            for (NSString *it in arr)
            {
                NSString* fullPath = [documentsDirectory stringByAppendingPathComponent:it];
                
                id obj = [[Service shared] getDataOfRecordPath:it];
                if (![[obj objectForKey:@"server"] isEqualToString:[APIController shared].server] ||
                    ![[obj objectForKey:@"user"] isEqualToString:[APIController shared].user]
                    ) continue;
                
                if ([pt.imgPath isEqualToString:fullPath])
                {
                    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
                    [arr removeObject:it];
                    break;
                }
            }
            
            [def setObject:arr forKey:@"SavedPhotos"];
            [def synchronize];
        }
        
        //
//        [self.photos removeObject: pt];
        if (self.onAttemptToRemovePhoto)
        {
            self.onAttemptToRemovePhoto(pt);
        }
        horizontalView.numberOfCells = self.photos.count;
        
        if (self.photos.count == 0)
        {
            if (self.onDidTouchNavItemBack)
            {
                self.onDidTouchNavItemBack(nil);
            }
            return;
        }
        
        [horizontalView reloadData];
        
//        [horizontalView removeFromSuperview];
//        
//        CGRect frameRect = CGRectMake(0, (IS_IOS_7)?32:0, 320, [UIScreen mainScreen].bounds.size.height - 64);
//        self.view.frame = frameRect;        
//        //NSLog(@"\nframe: %@\n", NSStringFromCGRect(frameRect));
//        horizontalView	= [[EasyTableView alloc] initWithFrame:frameRect numberOfColumns:self.photos.count ofWidth: 320];
//        horizontalView.delegate						= self;
//        horizontalView.tableView.backgroundColor	= [UIColor whiteColor];
//        horizontalView.tableView.allowsSelection	= YES;
//        horizontalView.tableView.separatorColor		= [UIColor darkGrayColor];
//        horizontalView.tableView.pagingEnabled = YES;
//        horizontalView.cellBackgroundColor			= [UIColor darkGrayColor];
//        horizontalView.autoresizingMask				= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
//        [self.view addSubview:horizontalView];
//        [horizontalView selectCellAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO];
    }
}

-(void)removeGuide:(Photo*)photo
{
    for (Photo *pt in photos)
    {
        if ([pt.sID isEqualToString:photo.sID] && [pt.direction isEqualToString: photo.direction])
        {
            pt.isGuide = NO;
            NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
//            [def setBool:NO forKey: [NSString stringWithFormat:@"guide:%@",[pt.imgPath lastPathComponent]]];
            [def removeObjectForKey:[NSString stringWithFormat:@"guide:%@",[pt.imgPath lastPathComponent]]];
            [def synchronize];

            NSString* comm = [NSString stringWithFormat:@"%@_%@",pt.siteID,pt.direction];
            [[Service shared].refSiteToGuides removeObjectForKey:comm];
//            [[Service shared].refSiteToGuides setObject:pt.imgPath forKey:pt.siteID];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *imgName = [NSString stringWithFormat:@"%@_%@.jpg", pt.sID, pt.direction];
                NSString *saveImagePath = [documentsDirectory stringByAppendingPathComponent:imgName];
                [[NSFileManager defaultManager] removeItemAtPath:saveImagePath error:nil];
                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GuidePicture"];
//                    [[NSUserDefaults standardUserDefaults] synchronize];
//                });

            });
        }
    }

}

-(void)makeGuideGuide:(UIButton*)sender //use it instead of makeGuide
{
    UIButton *bt = (UIButton*)sender;
    UIImageView *img = (UIImageView*)[[bt superview] viewWithTag:7777];
    UILabel *indexLabel = (UILabel*)[img viewWithTag:999];
    int index = [indexLabel.text intValue];
    //NSLog(@"\nindex: %d\n", index);
    Photo *pt = [photos objectAtIndex:index];
    if (!pt.isGuide)
    {
        [self removeGuide:pt];
        pt.isGuide = YES;
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        [def setBool:YES forKey: [NSString stringWithFormat:@"guide:%@",[pt.imgPath lastPathComponent]]];
        [def synchronize];
        
        NSString* comm = [NSString stringWithFormat:@"%@_%@",pt.siteID,pt.direction];
        [[Service shared].refSiteToGuides setObject:[pt.imgPath lastPathComponent] forKey:comm];

        //NSLog(@"\n===>>>pt.direction: %@\n", pt.direction);
        
        // look for photo guide
        NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
        NSMutableArray *guidePhotos = [NSMutableArray arrayWithArray:[userDefault objectForKey:@"GuidePhotos"]];
        if (guidePhotos) {
            for (int i=0; i<guidePhotos.count; i++) {
                NSDictionary    *dict = [guidePhotos objectAtIndex:i];
                if ([pt.photoID isEqualToString:[dict objectForKey:@"ID"]]) {
                    NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] initWithDictionary:dict copyItems:NO];
                    [mutDict setObject:[NSNumber numberWithBool:YES] forKey:@"IsGuide"];
                    
//                    // remove old
//                    [guidePhotos removeObjectAtIndex:i];
//                    
//                    //add new
//                    [guidePhotos addObject:mutDict];

                    int idx = [guidePhotos indexOfObject:dict];
                    [guidePhotos replaceObjectAtIndex:idx withObject:mutDict];

                    break;
                }
            }
        }
        
        [userDefault setObject:guidePhotos forKey:@"GuidePhotos"];
        [userDefault synchronize];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
//            NSData *data = UIImageJPEGRepresentation(img.image, 1.0);
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *imgName = [NSString stringWithFormat:@"%@_%@.jpg", pt.sID, pt.direction];
            NSString *saveImagePath = [documentsDirectory stringByAppendingPathComponent:imgName];
//            [data writeToFile:saveImagePath atomically:NO];
            
            [[NSFileManager defaultManager] removeItemAtPath:saveImagePath error:NULL];
            [[NSFileManager defaultManager] copyItemAtPath:pt.imgPath toPath:saveImagePath error:NULL];
            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[NSUserDefaults standardUserDefaults] setObject:imgName forKey:@"GuidePicture"]; //FOR DEMO USE
//                [[NSUserDefaults standardUserDefaults] synchronize];
//            });
        });
        [sender setTitle:@"Remove Guide" forState:UIControlStateNormal];
        
    }
    else
    {
        [UIAlertView alertViewWithTitle:nil andMsg:@"Would you like to unselect this guide picture?" onOK:^{
            
            [sender setTitle:@"Make Guide" forState:UIControlStateNormal];
            pt.isGuide = NO;
            NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
//            [def setBool:NO forKey: [NSString stringWithFormat:@"guide:%@",[pt.imgPath lastPathComponent]]];
            [def removeObjectForKey:[NSString stringWithFormat:@"guide:%@",[pt.imgPath lastPathComponent]]];
            [def synchronize];
            
//            [[Service shared].refSiteToGuides setObject:pt.imgPath forKey:pt.siteID];
            NSString* comm = [NSString stringWithFormat:@"%@_%@",pt.siteID,pt.direction];
            [[Service shared].refSiteToGuides removeObjectForKey:comm];

            // look for photo guide
            NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
            NSMutableArray *guidePhotos = [NSMutableArray arrayWithArray:[userDefault objectForKey:@"GuidePhotos"]];
            if (guidePhotos) {
                for (NSDictionary    *dict in guidePhotos) {
                    if ([pt.photoID isEqualToString:[dict objectForKey:@"ID"]]) {
                        NSMutableDictionary *mutDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                        [mutDict setObject:[NSNumber numberWithBool:NO] forKey:@"IsGuide"];
                        
//                        // remove old
//                        [guidePhotos removeObject:dict];
//                        //add new
//                        [guidePhotos addObject:mutDict];
                        
                        int idx = [guidePhotos indexOfObject:dict];
                        [guidePhotos replaceObjectAtIndex:idx withObject:mutDict];
                        
                        break;
                    }
                }
            }
            [userDefault setObject:guidePhotos forKey:@"GuidePhotos"];
            [userDefault synchronize];
            
            //NSLog(@"\n===>>>pt.direction: %@\n", pt.direction);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *imgName = [NSString stringWithFormat:@"%@_%@.jpg", pt.sID, pt.direction];
                NSString *saveImagePath = [documentsDirectory stringByAppendingPathComponent:imgName];
                [[NSFileManager defaultManager] removeItemAtPath:saveImagePath error:nil];
                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GuidePicture"];
//                    [[NSUserDefaults standardUserDefaults] synchronize];
//                });
            });
            
        } onCancel:^{
            [sender setTitle:@"Remove Guide" forState:UIControlStateNormal];
        }];
    }
}

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return scroll2ImageView;
}

-(void)viewImage:(id)sender
{
//    UIButton *bt = (UIButton*)sender;
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
//    [self.navigationController setNavigationBarHidden:YES];
//    
//    UIImageView *img = (UIImageView*)[[bt superview] viewWithTag:7777];
//    
//    [self.view bringSubviewToFront: scrollView2];
//    [scrollView2 setBackgroundColor:[UIColor blackColor]];
//    [scrollView2 setCanCancelContentTouches:NO];
//    scrollView2.clipsToBounds = YES; // default is NO, we want to restrict drawing within our scrollview
//    scrollView2.indicatorStyle = UIScrollViewIndicatorStyleBlack;
//    scroll2ImageView = [[UIImageView alloc] initWithImage:img.image];
//    [scrollView2 removeAllSubviews];
//    [scrollView2 addSubview:scroll2ImageView];
//    [scrollView2 setContentSize:CGSizeMake(scroll2ImageView.frame.size.width, scroll2ImageView.frame.size.height)];
//    scrollView2.minimumZoomScale = 320.0/img.image.size.width;
//    scrollView2.maximumZoomScale = 3;
//    scrollView2.delegate = self;
//    [scrollView2 setScrollEnabled:YES];
//    scrollView2.frame = [UIScreen mainScreen].bounds;
//    [scrollView2 setZoomScale:320.0/img.image.size.width];
////    scroll2ImageView.center = CGPointMake(scrollView2.width/2, scrollView2.height/2);
}

// Second delegate populates the views with data from a data source

#pragma mark EasyTableViewDelegate

- (void)easyTableView:(EasyTableView *)easyTableView scrolledToOffset:(CGPoint)contentOffset
{
    if (!isKeyboardShowing) return;
    
    int off = contentOffset.x;
    if (off % 320 == 0)
    {
        [currentTxtViewNote resignFirstResponder];
        
        int idx = off/320;
        UIView* vw = [easyTableView viewAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        UITextView* txtView = [[vw viewWithTag:1919].subviews objectAtIndex:1];
        [txtView becomeFirstResponder];
    }
}
- (UIView *)easyTableView:(EasyTableView *)easyTableView viewForRect:(CGRect)rect
{
	UIImageView *img = [[UIImageView alloc] initWithFrame:rect];
    img.userInteractionEnabled = YES;
	UIImageView *img1 = [[UIImageView alloc] initWithFrame:rect];
    img1.userInteractionEnabled = YES;
    [img addSubview: img1];
    img1.tag = 7777;
    
    int height = 120;
    UILabel *index = [[UILabel alloc] init];
    [img1 addSubview:index];
    index.text = @"0";
    index.tag = 999;
    UIImageView *overView = [[UIImageView alloc] initWithFrame:CGRectMake(0, rect.size.height - height, rect.size.width, height)];
    overView.backgroundColor = [UIColor blackColor];
    overView.alpha = 0.7;
    [img addSubview:overView];
    img.tag = 1;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(overView.frame.origin.x, overView.frame.origin.y +3, overView.frame.size.width - 140, overView.frame.size.height - 10)];
    label.font = [UIFont systemFontOfSize:15];
    label.backgroundColor = [UIColor clearColor];
    label.text = @"";
    [img addSubview:label];
    label.numberOfLines = 0;
    label.left = 20;
    label.baselineAdjustment = UIBaselineAdjustmentNone;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.textColor = [UIColor whiteColor];
    label.tag = 2;
    UIButton *bt = [UIButton buttonWithType:UIButtonTypeCustom];
    bt.frame = rect;
    bt.tag = 3;
    [img addSubview: bt];
    [bt addTarget:self action:@selector(viewImage:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *aButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [aButton setTitle:@"Make Guide" forState:UIControlStateNormal];
    aButton.width = 109;
    aButton.height = 30;
    [img addSubview: aButton];
    aButton.tag = 222;
    int x = 13;
    aButton.left = overView.width - aButton.width - 20 + x;
    aButton.top = overView.top + 5;
    //  [makeGuide addTarget:self action:@selector(makeGuideGuide:) forControlEvents:UIControlEventTouchUpInside];
    [aButton addTarget:self action:@selector(makeGuideGuide:) forControlEvents:UIControlEventTouchUpInside];
    
    aButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [aButton setTitle:@"Save to Roll" forState:UIControlStateNormal];
    aButton.width = 109;
    aButton.height = 30;
    [img addSubview: aButton];
    aButton.tag = 223;
    aButton.left = overView.width - aButton.width - 20 + x;
    aButton.centerY = overView.top + overView.height/2;
    //    [makeGuide addTarget:self action:@selector(makeGuideGuide:) forControlEvents:UIControlEventTouchUpInside];
    [aButton addTarget:self action:@selector(saveToRoll:) forControlEvents:UIControlEventTouchUpInside];
    
    aButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [aButton setTitle:@"Delete" forState:UIControlStateNormal];
    aButton.width = 109;
    aButton.height = 30;
    [img addSubview: aButton];
    aButton.tag = 224;
    aButton.left = overView.width - aButton.width - 20 + x;
    aButton.top = overView.top + overView.height - aButton.height - 5;
    //    [makeGuide addTarget:self action:@selector(makeGuideGuide:) forControlEvents:UIControlEventTouchUpInside];
    [aButton addTarget:self action:@selector(deletePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    //note view
    UIView* vwAll = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.frame.size.height-overView.frame.size.height)];
    vwAll.tag = 1919;
    [img addSubview:vwAll];
    
    UIView* vwBgNote = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.frame.size.height-overView.frame.size.height)];
    vwBgNote.backgroundColor = [UIColor blackColor];
    vwBgNote.alpha = 0.6;
    [vwAll addSubview:vwBgNote];
    
    UITextView* txtView = [[UITextView alloc] initWithFrame:vwBgNote.bounds];
    txtView.backgroundColor = [UIColor clearColor];
    txtView.textColor = [UIColor whiteColor];
    [txtView setEditable:YES];
    txtView.delegate = self;
    txtView.font = [UIFont systemFontOfSize:18];
    [vwAll addSubview:txtView];
    
    txtView.inputAccessoryView = toolBarNotes;
    
    //slider
//    UISlider* sliderAlpha = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, makeGuide.frame.origin.x-20, 10)];
//    [img addSubview:sliderAlpha];
//    sliderAlpha.frame = CGRectMake(10, label.frame.origin.y - sliderAlpha.frame.size.height +3, sliderAlpha.frame.size.width, sliderAlpha.frame.size.height);
//    [sliderAlpha addTarget:self action:@selector(onSliderAlphaValueChanged:) forControlEvents:UIControlEventValueChanged];
//    sliderAlpha.minimumValue = 0;
//    sliderAlpha.maximumValue = 1.0;
//    sliderAlpha.value = img1.alpha;
//    sliderAlpha.tag = 369;
    
	return img;
}

- (void)easyTableView:(EasyTableView *)easyTableView setDataForView:(UIView *)view forIndexPath:(NSIndexPath *)indexPath {
    
//	__block UIImageView *img	= (UIImageView *)view;
    
    __block UILabel *text = (UILabel*)[view viewWithTag:2];
    
    __block UIImageView *image = (UIImageView*)[view viewWithTag:7777];
    __block UILabel *indexLabel = (UILabel*)[image viewWithTag:999];    
    __block Photo *pt = [self.photos objectAtIndex: indexPath.row];
    
    __block UIImage *img_ = nil;
    //UISlider* slider = (UISlider*) [view viewWithTag:369];
    
//    NSNumber* n = [arrAlphaValues objectAtIndex:indexPath.row];
//    //slider.value = [n floatValue];
//    image.alpha = [n floatValue];
    
    if (![storeImgs objectForKey:pt.imgPath])
    {
        UIImage *img = [appDelegate loadImageOfFile:pt.imgPath];// [UIImage imageWithContentsOfFile:pt.imgPath];
        if (!img) {
            img = self.imgThumbnail;
        }
        [storeImgs setObject:img forKey:pt.imgPath];
    }
    
    img_ = [storeImgs objectForKey:pt.imgPath];
    if (img_ == self.imgThumbnail)
    {
        UIImage* img = [appDelegate loadImageOfFile:pt.imgPath];// [UIImage imageWithContentsOfFile:pt.imgPath];
        if (img)
        {
            img_ = img;
            [storeImgs setObject:img_ forKey:pt.imgPath];
        }
    }
    
    float scale = view.width/img_.size.width;
    image.image = img_;
    image.width = scale*img_.size.width;
    image.height = scale*img_.size.height;
    image.centerX = view.width/2;
    image.centerY = view.height/2 - 50;
    if (img_.size.width < img_.size.height)
    {
        image.top = 0;
    }
    
    NSString* s = pt.siteID;
    CGSize maximumSize = CGSizeMake(text.frame.size.width, 9999);
    CGSize sz = [s sizeWithFont:text.font
                          constrainedToSize:maximumSize
                              lineBreakMode:NSLineBreakByTruncatingTail];
    while (sz.height > 70) {
        s = [[s substringToIndex:s.length - 10] stringByAppendingFormat:@"..."];
        maximumSize = CGSizeMake(text.frame.size.width, 9999);
        sz = [s sizeWithFont:text.font
                  constrainedToSize:maximumSize
                      lineBreakMode:NSLineBreakByTruncatingTail];
    }
    
    text.text = [NSString stringWithFormat:@"%@\n%@\n%@", s ,pt.direction, pt.date];
    
    indexLabel.text = [NSString stringWithFormat:@"%d",(int) indexPath.row];
    UIButton *bt = (UIButton*)[view viewWithTag:222];
    
    if ([self isGuideAvailableForSite:pt.siteID andDirection:pt.direction andNotPhoto:pt])
    {
        bt.hidden = YES;
    }
    else
    {
         bt.hidden = NO;   
    }
    
    if (pt.isGuide)
    {
        [bt setTitle:@"Remove Guide" forState:UIControlStateNormal];
    }
    else
    {
        [bt setTitle:@"Make Guide" forState:UIControlStateNormal];        
    }
    
    UIView* vwAll = [view viewWithTag:1919];
    [vwAll setHidden:!isShowingNote];
    
    UITextView* txtView = [vwAll.subviews objectAtIndex:1];
    txtView.text = pt.note;
    txtView.tag = indexPath.row;
    
    if (isShowingNote)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [txtView becomeFirstResponder];
        });
    }
    
    //hide button delete if is downloaded guide photo
    UIButton* btDelete = (UIButton*)[view viewWithTag:224];
    if (pt.photoID)
    {
        [btDelete setHidden:YES];
    }
    else
    {
        [btDelete setHidden:NO];
    }
    
    [self preloadImgToStore:(int)indexPath.row];
}


// Optional delegate to track the selection of a particular cell
#pragma mark -

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (currentTxtViewNote)
    {
        textView.frame = CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, currentTxtViewNote.frame.size.height);
    }
    
    currentTxtViewNote = textView;
    return YES;
}

#pragma mark SELECTORS
- (void) onNote:(id)sender
{
    isShowingNote = !isShowingNote;
    
    UIBarButtonItem* bt = self.navigationItem.rightBarButtonItem;
    if (isShowingNote)
    {
        [bt setTitle:@"Hide"];
    }
    else
    {
        [bt setTitle:@"Note"];        
    }
    
    [horizontalView reloadData];
}

- (void) onNoteDone:(id)sender
{
    UITextView* txtView = currentTxtViewNote;
    Photo *pt = [self.photos objectAtIndex: txtView.tag];
//    NSString* imgPath = pt.imgPath;
    NSString* idImg = [pt.imgPath lastPathComponent];
    
    pt.note = txtView.text;
    
    id obj = [[Service shared] getDataOfRecordPath:idImg];
    
    if (!obj) {
        // save back to user pref
        __block NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
        
        // look for photo guide
        NSMutableArray *guidePhotos = [NSMutableArray arrayWithArray:[userDefault objectForKey:@"GuidePhotos"]];
        if (guidePhotos) {
            for (int i=0; i<guidePhotos.count; i++) {
                NSDictionary    *dict = [guidePhotos objectAtIndex:i];
                if ([pt.photoID isEqualToString:[dict objectForKey:@"ID"]]) {
                    NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] initWithDictionary:dict copyItems:NO];
                    [mutDict setObject:txtView.text forKey:@"Note"];
                    
//                    // remove old
//                    [guidePhotos removeObjectAtIndex:i];
//                    
//                    //add new
//                    [guidePhotos addObject:mutDict];
                    
                    int idx = [guidePhotos indexOfObject:dict];
                    [guidePhotos replaceObjectAtIndex:idx withObject:mutDict];

                    break;
                }
            }
            
        }
        
        [userDefault setObject:guidePhotos forKey:@"GuidePhotos"];
        [userDefault synchronize];
        
        // it can be guide photo
        [[APIController shared] updateNote:txtView.text ofPhotoID:pt.sID andOnDone:^(id back){
            DLog(@"Note update successfully!");
        }andOnError:^(id err){
            
            NSArray *arr = [userDefault objectForKey:@"NoteUpload"];
            NSMutableArray  *arrRec = [NSMutableArray new];
            if (!arr) {
                [arrRec addObjectsFromArray:arr];
            }
            
            [arrRec addObject:[NSDictionary dictionaryWithObjectsAndKeys:txtView.text,@"note",pt.sID,@"pID", nil]];
            
            [userDefault setObject:arrRec forKey:@"NoteUpload"];
            [userDefault synchronize];
        }];
        
        [self->currentTxtViewNote endEditing:YES];
        // end
        return;
    }
    
    //check if obj have serverID , mean it can update note, otherwise , just change the note    
    [obj setObject:txtView.text forKey:@"note"];
    [[Service shared] updateRecordPath:idImg andData:obj];
    
    if ([obj objectForKey:@"photoID"])
    {
        NSString* pid = [obj objectForKey:@"photoID"];
        //update note to server
        [[APIController shared] updateNote:txtView.text ofPhotoID:pid andOnDone:^(id back){
            //well , note updated , remove failed-key if any , prevent unneccessay re-update
            id obj2 = [[Service shared] getDataOfRecordPath:idImg];
            if ([obj2 objectForKey:@"noteUpdateFailed"])
            {
                [obj2 removeObjectForKey:@"noteUpdateFailed"];
                [[Service shared] updateRecordPath:idImg andData:obj];
            }
            
            [self->currentTxtViewNote endEditing:YES];
            
        } andOnError:^(id err){
            
            //opp, something went wrong, should note a sign to schedule reupdate later            
            id obj2 = [[Service shared] getDataOfRecordPath:idImg];
            [obj2 setObject:@"1" forKey:@"noteUpdateFailed"];
            [[Service shared] updateRecordPath:idImg andData:obj];
            
            [self->currentTxtViewNote endEditing:YES];

        }];
    }
    else
    {
        [currentTxtViewNote endEditing:YES];
    }
}

- (void) onNoteCancel:(id)sender
{
    UITextView* txtView = currentTxtViewNote;
    Photo *pt = [self.photos objectAtIndex: txtView.tag];
    
    currentTxtViewNote.text = pt.note;
    [self.view endEditing:YES];
 
    //hide note
    [self onNote:nil];
}

- (void) onKeyboardWillShow:(NSNotification*)notify
{
    float kbHeight = [[notify.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    kbHeight -= 120;
    
    [UIView animateWithDuration:0.3 animations:^{
        UIView* v = self->currentTxtViewNote;
        v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, v.frame.size.width, v.frame.size.height - kbHeight);
    }];
    isKeyboardShowing = YES;
}

- (void) onKeyboardWillHide:(NSNotification*)notify
{
    float kbHeight = [[notify.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    kbHeight -= 120;
    
    [UIView animateWithDuration:0.3 animations:^{
        UIView* v = self->currentTxtViewNote;
        v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, v.frame.size.width, v.frame.size.height + kbHeight);        
    }];
    isKeyboardShowing = NO;
}
@end
