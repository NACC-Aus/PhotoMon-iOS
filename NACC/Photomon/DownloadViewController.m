
#import "DownloadViewController.h"


@implementation DownloadViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Guide photo";
    

    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(touchCancel)];
    
    isSelectAll = NO;
    

    [self filterNoPhotoSite];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


- (void) onNotifyAppWillChangeOrientation:(NSNotification*) notify
{
    int itf = [notify.object intValue];
    if (itf == UIInterfaceOrientationPortrait || itf == UIInterfaceOrientationPortraitUpsideDown)
    {
        
    }
    else
    {
    }
}

- (void)dealloc
{
    NLog(@"RELEASE %@",NSStringFromClass([self class]));
}

#pragma mark action
-(void) touchCancel {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.mapController dismissViewControllerAnimated:YES completion:nil];
}

-(void) touchDone {
    NSMutableArray  *arrSiteId = [NSMutableArray new];
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    // set guides that need to be downloaded here
    for (int i =0 ; i < _arrList.count; i++) {
        NSDictionary    *dict = [_arrList objectAtIndex:i];
//        if ([[dict objectForKey:@"marked"] boolValue]) {
//            // already download
//            continue;
//        }
//        UITableViewCell *cell = [tblView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
//        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
//            DLog(@"txt = %d",i);
//            Site *site = [dict objectForKey:@"site"];
//            [arrSiteId addObject:site.ID];
//        }
        
        if ([[dict objectForKey:@"marked"] boolValue]) {
            DLog(@"add site txt = %d",i);
            Site *site = [dict objectForKey:@"site"];
            [arrSiteId addObject:site.ID];
        }
    }
    
    {
        //remove guide photos that not include
        NSArray* arrOldSiteIds = [def objectForKey:[NSString stringWithFormat:@"ListOfGuideSites_%@_%@",[[APIController shared].currentProject objectForKey:@"uid"],[APIController shared].server]];
    
        NSArray* arrGuidePhotos = [[NSUserDefaults standardUserDefaults] objectForKey:@"GuidePhotos"] ;
        NSMutableArray* arrNewGuidePhotos = [NSMutableArray array];
        NSMutableArray* photoIds = [NSMutableArray array];
        for (id photo in arrGuidePhotos)
        {
            NSString* psiteId = [photo objectForKey:@"SiteId"];
            if (([arrOldSiteIds containsObject:psiteId] && [arrSiteId containsObject:psiteId])
                || (![arrOldSiteIds containsObject:psiteId] && ![arrSiteId containsObject:psiteId]))
            {
                [arrNewGuidePhotos addObject:photo];
                
                NSString* photoId = [photo objectForKey:@"ID"];
                [photoIds addObject:photoId];
                for (Photo* p in self.photos) {
                    if([photoId isEqualToString:p.photoID]) {
                        p.isGuide = YES;
                        [def setBool:YES forKey: [NSString stringWithFormat:@"guide:%@",[p.imgPath lastPathComponent]]];
                        
                        
                        NSString* comm = [NSString stringWithFormat:@"%@_%@",p.siteID,p.direction];
                        [[Service shared].refSiteToGuides setObject:[p.imgPath lastPathComponent] forKey:comm];
                        break;
                    }
                }
            }
        }
        
        
        for (int i=0; i<arrNewGuidePhotos.count; i++) {
            NSDictionary    *dict = [arrNewGuidePhotos objectAtIndex:i];
            for (int j = 0; j < photoIds.count; j++) {
                NSString* photoId = [photoIds objectAtIndex:j];
                if ([photoId isEqualToString:[dict objectForKey:@"ID"]]) {
                    NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] initWithDictionary:dict copyItems:NO];
                    [mutDict setObject:[NSNumber numberWithBool:YES] forKey:@"IsGuide"];
                    NSInteger idx = [arrNewGuidePhotos indexOfObject:dict];
                    [arrNewGuidePhotos replaceObjectAtIndex:idx withObject:mutDict];
                    
                    break;
                }
            }
        }
        
        //[def setBool:YES forKey: [NSString stringWithFormat:@"guide:%@",[pt.imgPath lastPathComponent]]];
        [def setObject:arrNewGuidePhotos forKey:@"GuidePhotos"];
        [def setObject:arrSiteId forKey:[NSString stringWithFormat:@"ListOfGuideSites_%@_%@",[[APIController shared].currentProject objectForKey:@"uid"],[APIController shared].server]];

        [def synchronize];
    }
    
    [self.mapController reloadTable];
    // then go back to the previous screen
    [self.mapController dismissViewControllerAnimated:YES completion:nil];
    
    // at the end - force donwload
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mapController reloadOldDataFromServer:arrSiteId andProjectId:[[APIController shared].currentProject objectForKey:@"uid"]];
    });
}

-(void) touchSelectAll {
    if (!isSelectAll) {
        isSelectAll = YES;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Unselect All" style:UIBarButtonItemStylePlain target:self action:@selector(touchSelectAll)];
    }
    else {
        isSelectAll = NO;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Select All" style:UIBarButtonItemStylePlain target:self action:@selector(touchSelectAll)];
    }
    
    for (int i=0; i<_arrList.count; i++) {
        NSDictionary    *dict = [_arrList objectAtIndex:i];
        if ([[dict objectForKey:@"marked"] boolValue]) {
            continue;
        }
        UITableViewCell *cell = [tblView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if (isSelectAll) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark logic
-(void) filterNoPhotoSite {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    __block NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString    *urlStr = [NSString stringWithFormat:@"%@/photos.json?access_token=%@&project_id=%@",[APIController shared].server,[userDefault objectForKey:@"AccessToken"],[[APIController shared].currentProject objectForKey:@"uid"]];
    __block ASIHTTPRequest  *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStr]];
    
    [request setRequestMethod:@"GET"];
    [request setCompletionBlock:^{
        RUN_ON_BACKGROUND_QUEUE(^{
            // process data here
            NSError *error = nil;
            NSArray *arrPhotoData = [NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingAllowFragments error:&error];
            
            NSLog(@"=> %@",arrPhotoData);
            if (arrPreloadSites) {
                [arrPreloadSites removeAllObjects];
            }
            else
                arrPreloadSites = [NSMutableArray new];
            
            
            //
            if ([arrPhotoData count] > 0)
            {
                for (Site *site in _arrList)
                {
                    DLog(@"cehck site %@",site);
                    for (NSDictionary *dict in arrPhotoData)
                    {
                        
                        if ([site.ID isEqualToString:[dict objectForKey:@"SiteId"]]) {
                            [arrPreloadSites addObject:site];
                            DLog(@"add site %@",site);
                            // break;
                            break;
                        }
                    }
                }
            }
            else
            {
                [arrPreloadSites addObjectsFromArray:_arrList];
            }
            

            RUN_ON_MAIN_QUEUE(^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                // add ui
                UIBarButtonItem *btnDone = [[UIBarButtonItem alloc] initWithTitle:@"Download" style:UIBarButtonItemStyleDone target:self action:@selector(touchDone)];
                self.navigationItem.rightBarButtonItem = btnDone;
                [self initDataTable];
            });
        });
    }];
    [request startAsynchronous];
}

-(void) initDataTable {
    DLog(@"init data table");
    // sort list
    NSArray *tmp = [arrPreloadSites sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(Site *obj1, Site *obj2) {
        return [obj1.Name compare:obj2.Name options:NSCaseInsensitiveSearch];
    }];
    
    [arrPreloadSites removeAllObjects];
    // add
    for (Site *site in tmp) {
        NSMutableDictionary    *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:site,@"site",[NSNumber numberWithBool:NO],@"marked", nil];
        [arrPreloadSites addObject:dict];
    }
    _arrList = [[NSMutableArray alloc] initWithArray:arrPreloadSites];
    [self verifyDownloadedSites];
    tblView.delegate = self;
    tblView.dataSource = self;
    [tblView reloadData];
}


- (void) verifyDownloadedSites {
    /*
     -
     -*/
    NSUserDefaults  *userDefault = [NSUserDefaults standardUserDefaults];
    
    NSArray *guidePhotos = [userDefault objectForKey:@"GuidePhotos"];
    if (guidePhotos) {
        for (NSMutableDictionary    *dict in guidePhotos) {
            [self markDownloadedSiteWithId:[dict objectForKey:@"SiteId"]];
//            if (![self checkSiteExistWithId:[dict objectForKey:@"SiteId"]]) {
//                DLog(@"Found a site id not in list %@",[dict objectForKey:@"SiteId"]);
//                continue;
//            }
//            //            if (![site.ID isEqualToString:[dict objectForKey:@"SiteId"]]) {
//            //                DLog(@"site nt match :%@ - %@",[dict objectForKey:@"SiteId"],[dict objectForKey:@"SiteName"]);
//            //                continue;
//            //            }
//            DLog(@"have a site:%@ - %@",[dict objectForKey:@"SiteId"],[dict objectForKey:@"SiteName"]);
//            Photo *p = [Photo new];
//            p.date = [dict objectForKey:@"CreatedAt"];
//            p.direction = [dict objectForKey:@"Direction"];
//            p.imgPath = [dict objectForKey:@"ImagePath"];
//            p.img = [UIImage imageWithContentsOfFile:p.imgPath];
//            p.imgThumbnail = [UIImage imageWithContentsOfFile:[dict objectForKey:@"ThumbPath"]];
//            p.thumbPath =[dict objectForKey:@"ThumbPath"];
//            p.sID = [dict objectForKey:@"ID"];
//            p.siteID = [dict objectForKey:@"SiteName"];
//            p.isFinished = YES;
//            
//            p.isGuide = [[dict objectForKey:@"IsGuide"] boolValue];
//            
//            p.note = [dict objectForKey:@"Note"];
//            // add to source
//            if (source) {
//                [source addObject:p];
//            }
        }
    }
    
}

-(void) markDownloadedSiteWithId:(NSString*)siteId {
    for (NSMutableDictionary   *dict in _arrList) {
        Site *site = [dict objectForKey:@"site"];
        if ([site.ID isEqualToString:siteId]) {
            //return YES;
            // marked as downloaded
            [dict setObject:[NSNumber numberWithBool:YES] forKey:@"marked"];
        }
    }
}

#pragma mark table view delegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary    *dict= [_arrList objectAtIndex:indexPath.row];
    Site *site = [dict objectForKey:@"site"];
    
    NSString* s = site.Name;
    CGSize maximumSize = CGSizeMake(230, 9999);
    CGSize sz = [s sizeWithFont:[UIFont boldSystemFontOfSize:18]
              constrainedToSize:maximumSize
                  lineBreakMode:NSLineBreakByTruncatingTail];
    if (sz.height < 23) {
        return 68-5;
    }
    
    return 68+5;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSMutableDictionary    *dict = [_arrList objectAtIndex:indexPath.row];
    if ([[dict objectForKey:@"marked"] boolValue]) {
        [dict setObject:[NSNumber numberWithBool:NO] forKey:@"marked"];
    }
    else
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"marked"];
    UITableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellName = @"cellName";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];
        
        if (appDelegate.osVersion >= 8)
        {
            cell.layoutMargins = UIEdgeInsetsZero;
            cell.preservesSuperviewLayoutMargins = NO;
        }
    }
    
    NSDictionary    *dict = [_arrList objectAtIndex:indexPath.row];
    Site *site = [dict objectForKey:@"site"];
    if ([[dict objectForKey:@"marked"] boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    for (UIView *aView in cell.contentView.subviews) {
        //if ([aView isKindOfClass:[UILabel class]]) {
            [aView removeFromSuperview];
        //}
    }
    
    int cellHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    NSString* name = site.Name;
    if (name.length > 0) {
        name = [name stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                             withString:[[name substringToIndex:1] capitalizedString]];
    }
    
    cell.textLabel.text = name;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    UIView  *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, cellHeight -1, 320, 1)];
    lineView.backgroundColor = UIColorFromRGB(0xd8d8d8);
    [cell.contentView addSubview:lineView] ;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
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
    
    NSUInteger count = [_arrList count];
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
@end
