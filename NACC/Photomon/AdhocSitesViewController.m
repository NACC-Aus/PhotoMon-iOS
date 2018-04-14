
#import "AdhocSitesViewController.h"
#import "AlertViewWithBlock.h"
#import "CacheManager.h"
//**************************************************
@implementation AdhocSiteTextField
@end

//**************************************************
@interface AdhocSitesViewController ()

@end

@implementation AdhocSitesViewController

#pragma mark INIT
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    {
        toolBarEdit = [[UIToolbar alloc] init];
        toolBarEdit.barStyle = UIBarStyleBlackTranslucent;
        UIBarButtonItem* btCancel2 = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(onEditCancel:)];
        UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem* btDone2 = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onEditDone:)];
        [toolBarEdit setItems:@[btCancel2, bt,btDone2]];
        [toolBarEdit sizeToFit];
    }
    
    [self setTitle:@"Sites"];
    
    btEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditModeBegin:)];
    btDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onEditModeEnd:)];
    btAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onModeAdd:)];
    
    
    if ([[APIController shared] checkIfDemo])
    {
        datasource = [Service shared].adHocSites;
        self.navigationItem.rightBarButtonItem = btEdit;
    }
    else
    {
        datasource = self.allSites;
        self.navigationItem.rightBarButtonItem = btAdd;
        [self sortData];
    }
    
    
}

-(void)sortData{
    if(datasource)
    {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"Name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray* sortedArray = [datasource sortedArrayUsingDescriptors:@[sort]];
        datasource = [[NSMutableArray alloc] initWithArray:sortedArray];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self setupView];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark MAIN
- (void) setupView
{
    if (isGotSetupView) return;
    isGotSetupView = YES;
    
    [tbView reloadData];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    UIView* targetView = tbView.superview;
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

    NSUInteger count = datasource.count;
    if (count == 0)
    {
        self.navigationItem.rightBarButtonItem = nil;
        tbView.alpha = 0;
        lb.frame = CGRectMake(0, (tableView.frame.size.height-20)/2, tableView.frame.size.width, 20);
        [lb setAlpha:1.0];
    }
    else
    {
        if ([[APIController shared] checkIfDemo])
        {
            self.navigationItem.rightBarButtonItem = btEdit;
        }
        else
        {
            self.navigationItem.rightBarButtonItem = btAdd;
        }
        
        tbView.alpha = 1.0;
        [lb setAlpha:0.0];
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (appDelegate.osVersion >= 8)
        {
            cell.layoutMargins = UIEdgeInsetsZero;
            cell.preservesSuperviewLayoutMargins = NO;
        }
        
        AdhocSiteTextField* txtField = [[AdhocSiteTextField alloc] initWithFrame:CGRectMake(15, 18, 210, 30)];
        txtField.tag = 777;
        txtField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        txtField.delegate = self;
        txtField.inputAccessoryView = toolBarEdit;
        [cell.contentView addSubview:txtField];
        
    }

    [cell.textLabel setHidden:YES];
    AdhocSiteTextField* txt = (AdhocSiteTextField*)[cell viewWithTag:777];
    id d = [datasource objectAtIndex:indexPath.row];
    [cell bringSubviewToFront:txt];
    if ([[APIController shared] checkIfDemo])
    {
        NSString* name = [d objectForKey:@"Name"];
        if (name.length > 0) {
            name = [name stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                      withString:[[name substringToIndex:1] capitalizedString]];
            
        }
        
        txt.text = name;
        txt.data = d;
    }
    else
    {
        Site* site = d;
        NSString* name = site.Name;
        if (name.length > 0) {
            name = [name stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                 withString:[[name substringToIndex:1] capitalizedString]];
            
        }
        
        txt.text = name;
    }
    
    if (self.navigationItem.rightBarButtonItem == btDone)
    {
        txt.userInteractionEnabled = YES;
    }
    else
    {
        txt.userInteractionEnabled = NO;
    }
    
    return cell;
}

#pragma mark UITableViewDelegate
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSLog(@"CALL DELETE");

        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        
        AdhocSiteTextField* txt = (AdhocSiteTextField*)[cell viewWithTag:777];
        [[Service shared] updateAdhocSite:txt.data withNewName:nil];
        
        [tbView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tbView reloadData];

    }
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    currentTextField = (AdhocSiteTextField*) textField;
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    tbView.frame = CGRectMake(tbView.frame.origin.x, tbView.frame.origin.y, tbView.frame.size.width, 240);
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    tbView.frame = CGRectMake(tbView.frame.origin.x, tbView.frame.origin.y, tbView.frame.size.width, 568-64);
    return YES;
}
#pragma mark SELECTORS
- (void) onEditDone:(id)sender
{
    [currentTextField endEditing:YES];
    
    //commit the change
    [[Service shared] updateAdhocSite:currentTextField.data withNewName:currentTextField.text];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

- (void) onEditCancel:(id)sender
{
    [currentTextField endEditing:YES];
    
    //restore the original
    currentTextField.text = [currentTextField.data objectForKey:@"Name"];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

- (void) onEditModeBegin:(id)sender
{
    self.navigationItem.rightBarButtonItem = btDone;
//    [tbView reloadData];
    [tbView setEditing:YES animated:YES];
    
    for (UITableViewCell* cell in tbView.visibleCells)
    {
        AdhocSiteTextField* txt = (AdhocSiteTextField*)[cell viewWithTag:777];
        txt.userInteractionEnabled = YES;
    }
}

- (void) onEditModeEnd:(id)sender
{
    [self onEditCancel:nil];
    
    self.navigationItem.rightBarButtonItem = btEdit;
//    [tbView reloadData];
    [tbView setEditing:NO animated:YES];
    
    for (UITableViewCell* cell in tbView.visibleCells)
    {
        AdhocSiteTextField* txt = (AdhocSiteTextField*)[cell viewWithTag:777];
        txt.userInteractionEnabled = NO;
    }
}

- (void) onModeAdd:(id)sender
{
    Site* nearestSite = nil;
    AppDelegate *del = appDelegate;
    //MKMapPoint currentPoint = MKMapPointForCoordinate(del.newestUserLocation.coordinate);
    CLLocation  *currentPoint = [[CLLocation alloc] initWithLatitude:del.newestUserLocation.coordinate.latitude longitude:del.newestUserLocation.coordinate.longitude];
    
    for (Site* site in datasource)
    {
        CLLocation *branchPoint = [[CLLocation alloc] initWithLatitude:[site.Latitude doubleValue] longitude:[site.Longitude doubleValue]];
        //distance = MKMetersBetweenMapPoints(currentPoint, branchPoint);
        CGFloat distance = [currentPoint distanceFromLocation:branchPoint];
        if(distance <= 100) {
            nearestSite = site;
            break;
        }
    }
    
    if(nearestSite)
    {
        NSString* name = nearestSite.Name;
        if (name.length > 0) {
            name = [name stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                 withString:[[name substringToIndex:1] capitalizedString]];
            
        }
        
        UIAlertView* alertViewAskAdhocSiteName = [[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"'%@' exists in this location", name] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
        alertViewAskAdhocSiteName.alertViewStyle = UIAlertViewStyleDefault;
        alertViewAskAdhocSiteName.tag = 212;
        [alertViewAskAdhocSiteName show];
        return;
    }
    
    UIAlertView* alertViewAskAdhocSiteName = [[UIAlertView alloc] initWithTitle:@"New site name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
    alertViewAskAdhocSiteName.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertViewAskAdhocSiteName textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    alertViewAskAdhocSiteName.tag = 31124;
    [alertViewAskAdhocSiteName show];
}

#pragma mark SELECTOR

- (void) onNoteDone:(NSString*)text
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");
    if (appDelegate.newestUserLocation.coordinate.latitude == 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"Require location" message:@"We can't see your location. Please turn location services on in your Settings!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    
    if (text.length < 1)
    {
        [UIAlertView alertViewTitle:@"Require" andMsg:@"Please provide valid site name" onOK:^{
            UIAlertView* alertViewAskAdhocSiteName = [[UIAlertView alloc] initWithTitle:@"New site name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
            alertViewAskAdhocSiteName.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alertViewAskAdhocSiteName textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
            alertViewAskAdhocSiteName.tag = 31124;
            [alertViewAskAdhocSiteName show];
            
        }];
    }
    else
    {
        if (![[Service shared] checkIfSiteNameAvailable:text])
        {
            [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"The name '%@' not available, please select other",text] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }
        
        NSString* lat = [[NSNumber numberWithDouble:appDelegate.newestUserLocation.coordinate.latitude] stringValue];
        NSString* lng = [[NSNumber numberWithDouble:appDelegate.newestUserLocation.coordinate.longitude] stringValue];

        NSString* projectId = [[APIController shared].currentProject objectForKey:@"uid"];
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                              projectId, @"projectId",
                              text, @"name",
                              lat, @"lat",
                              lng, @"lng",
                              nil];

        NSString* cacheKey = [[NSUUID UUID] UUIDString];
        [[CacheManager share] addCache:dict forKey:cacheKey andType:TYPE_SITE];
        [[APIController shared] addNewSite:text withProjectId:projectId lat:lat lng:lng withOnDone:^(id result) {
            if(result)
            {
                [datasource addObject:result];
                [self sortData];
                [tbView reloadData];
                [[CacheManager share] removeCache:cacheKey];
            }
        } andOnError:^(id err) {
            
        }];
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 31124)
    {
        if (buttonIndex == 0) //cancel
        {
            [self onNoteCancel:nil];
        }
        else //done
        {
            NSString* text = [alertView textFieldAtIndex:0].text;
            [self onNoteDone:text];
        }
    } else if (alertView.tag == 212)
    {
        if (buttonIndex == 0) //cancel
        {
            
        }
        else //done
        {
            UIAlertView* alertViewAskAdhocSiteName = [[UIAlertView alloc] initWithTitle:@"New site name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
            alertViewAskAdhocSiteName.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alertViewAskAdhocSiteName textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
            alertViewAskAdhocSiteName.tag = 31124;
            [alertViewAskAdhocSiteName show];
        }
    }
}
@end
