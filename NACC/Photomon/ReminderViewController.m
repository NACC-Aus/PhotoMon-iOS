
#import "ReminderViewController.h"

@interface ReminderViewController ()

@end

@implementation ReminderViewController

//STATIC
static ReminderViewController* shared_ = nil;
+ (ReminderViewController *) shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_ = [[ReminderViewController alloc] init];
    });
    return shared_;
}

//INIT
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        frequencies = @[@"1 year",@"6 months",@"3 months",@"Monthly",@"Fortnightly",@"Weekly"];
        frequencyIntervals = @[@"31104000",@"15552000",@"7776000",@"2592000",@"1209600",@"604800"];//604800
        
//        isEnableReminderOnTime = NO;
//        isEnableReminderOnFrequency = NO;
        isEnable = NO;
        
        remindFrequency = @"Weekly";
        freq = kFreqWeek;
        remindDate = @"16/03/2013";
        remindTime = @"8:00";
        
        formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        [formatter setDateFormat:@"EEE d/M/yyyy"];
        remindDate = [formatter stringFromDate:[NSDate date]];
        
        [formatter setDateFormat:@"h:mm a"];
        remindTime = [formatter stringFromDate:[NSDate date]];
        
        NSMutableDictionary* reminderConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReminderConfig"];
        if (reminderConfig)
        {
            //            isEnableReminderOnFrequency = [[reminderConfig objectForKey:@"isEnableReminderOnFrequency"] boolValue];
            //            isEnableReminderOnTime = [[reminderConfig objectForKey:@"isEnableReminderOnTime"] boolValue];
            isEnable = [[reminderConfig objectForKey:@"isEnable"] boolValue];
            
            remindDate = [reminderConfig objectForKey:@"remindDate"];
            remindTime = [reminderConfig objectForKey:@"remindTime"];
            
            remindFrequency = [reminderConfig objectForKey:@"remindFrequency"];
            freq = [[reminderConfig objectForKey:@"freq"] intValue];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.navigationItem setTitle:@"Reminder"];
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(onSave:)];
    self.navigationItem.rightBarButtonItem  = save;
    
    tbView.dataSource = self;
    tbView.delegate = self;
    
    NSMutableDictionary* reminderConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReminderConfig"];
    if (reminderConfig)
    {
        //            isEnableReminderOnFrequency = [[reminderConfig objectForKey:@"isEnableReminderOnFrequency"] boolValue];
        //            isEnableReminderOnTime = [[reminderConfig objectForKey:@"isEnableReminderOnTime"] boolValue];
        isEnable = [[reminderConfig objectForKey:@"isEnable"] boolValue];
        
        remindDate = [reminderConfig objectForKey:@"remindDate"];
        remindTime = [reminderConfig objectForKey:@"remindTime"];
        
        remindFrequency = [reminderConfig objectForKey:@"remindFrequency"];
        freq = [[reminderConfig objectForKey:@"freq"] intValue];
    }
    [tbView reloadData];

    isViewLoaded = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    NSMutableDictionary* reminderConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReminderConfig"];
    if (reminderConfig)
    {
        //            isEnableReminderOnFrequency = [[reminderConfig objectForKey:@"isEnableReminderOnFrequency"] boolValue];
        //            isEnableReminderOnTime = [[reminderConfig objectForKey:@"isEnableReminderOnTime"] boolValue];
        isEnable = [[reminderConfig objectForKey:@"isEnable"] boolValue];
        
        remindDate = [reminderConfig objectForKey:@"remindDate"];
        remindTime = [reminderConfig objectForKey:@"remindTime"];
        
        remindFrequency = [reminderConfig objectForKey:@"remindFrequency"];
        freq = [[reminderConfig objectForKey:@"freq"] intValue];
    }
    [tbView reloadData];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //pickerDate
    if (![self.navigationController.view viewWithTag:1111])
    {
        UIView* vwFade = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 650)];
        vwFade.alpha = 0.0;
        vwFade.tag = 1111;
        pickerDate = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 650, 320, 162)];
        pickerDate.backgroundColor = [UIColor whiteColor];
        
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapFade:)];
        [vwFade addGestureRecognizer:tap];
        
        [self.navigationController.view addSubview:vwFade];
        [self.navigationController.view addSubview:pickerDate];
        
        //wpickerDate
        wpickerDate = [[WDatePicker alloc] initWithFrame:CGRectMake(0, 650, 320, 162)];
        wpickerDate.backgroundColor = [UIColor whiteColor];
        [self.navigationController.view addSubview:wpickerDate];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    // cehck for current status
    NSDictionary    *dict  = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReminderConfig"];
    if (![[dict objectForKey:@"isEnable"] boolValue]) {
        // disable
        //UISwitch *sw = (UISwitch*)[tbView viewWithTag:11];
        [enableSwitch  setSelected:NO];
        isEnable = NO;
        //        [tbView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        //
        //sEnableReminderOnFrequency = isEnableReminderOnTime;
        [tbView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationFade];
    }
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc
{
    NLog(@"RELEASE %@",NSStringFromClass([self class]));
}

//MAIN
enum {
    kFreqYear,
    kFreq6Months,
    kFreq3Months,
    kFreqMonthly,
    kFreqFortnight,
    kFreqWeek
};

- (void) showDatePicker:(NSDate*)currentDate andOnDone:(void(^)(id))onDone
{
    if (onDone) onPickerDateDone = [onDone copy];
    
    pickerDate.datePickerMode = UIDatePickerModeDate;
    [pickerDate setDate:currentDate animated:NO];
    
    UIView * vwFade = [self.navigationController.view viewWithTag:1111];
    vwFade.backgroundColor = [UIColor blackColor];
    
    [appDelegate.window setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.3 animations:^(void){
        vwFade.alpha = 0.3;
        pickerDate.frame = CGRectMake(0, self.view.frame.size.height-162+64, 320, 162);
    } completion:^(BOOL finished) {
        [appDelegate.window setUserInteractionEnabled:YES];
    }];
}

- (void) showDatePicker2:(NSDate*)currentDate andOnDone:(void(^)(id))onDone
{
    if (onDone) onWPickerDateDone = [onDone copy];
    
    [wpickerDate setCurrentDate:currentDate];
    
    UIView * vwFade = [self.navigationController.view viewWithTag:1111];
    vwFade.backgroundColor = [UIColor blackColor];
    
    [UIView animateWithDuration:0.3 animations:^(void){
        vwFade.alpha = 0.3;
        wpickerDate.frame = CGRectMake(0, self.view.frame.size.height-162+64, 320, 162);
    }];
}

- (void) showTimePicker:(NSDate*)currentTime andOnDone:(void(^)(id))onDone
{
    if (onDone) onPickerDateDone = [onDone copy];
    
    pickerDate.datePickerMode = UIDatePickerModeTime;
    [pickerDate setDate:currentTime animated:NO] ;
    
    UIView * vwFade = [self.navigationController.view viewWithTag:1111];
    vwFade.backgroundColor = [UIColor blackColor];
    
    [appDelegate.window setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.3 animations:^(void){
        vwFade.alpha = 0.3;
        pickerDate.frame = CGRectMake(0, self.view.frame.size.height-162+64, 320, 162);
    } completion:^(BOOL finished) {
        [appDelegate.window setUserInteractionEnabled:YES];
    }];
}

- (void) updateReminder
{
    if (!isViewLoaded) //load old pref
    {
        NSMutableDictionary* reminderConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReminderConfig"];
        if (reminderConfig)
        {
            //            isEnableReminderOnFrequency = [[reminderConfig objectForKey:@"isEnableReminderOnFrequency"] boolValue];
            //            isEnableReminderOnTime = [[reminderConfig objectForKey:@"isEnableReminderOnTime"] boolValue];
            isEnable = [[reminderConfig objectForKey:@"isEnable"] boolValue];
            
            remindDate = [reminderConfig objectForKey:@"remindDate"];
            remindTime = [reminderConfig objectForKey:@"remindTime"];
            
            remindFrequency = [reminderConfig objectForKey:@"remindFrequency"];
            freq = [[reminderConfig objectForKey:@"freq"] intValue];
        }
    }
    else
    {
        isEnable = enableSwitch.isOn;
    }
    
    // look for date
    NSDate *theDate = nil;
    NSDate *currDate = [NSDate date];
    
    if (isUserSaving)
    {
        // clean all notification
        NSArray* arr = [[UIApplication sharedApplication] scheduledLocalNotifications];
        DLog(@"Found %d notificaition need to be removed",arr.count);
        for (UILocalNotification* notify in arr)
        {
            //        if ([notify.alertBody hasPrefix:@"Reminder"])
            //        {
            //            NSDictionary* d = notify.userInfo;
            //            if ([d objectForKey:@"isEnableReminderOnFrequency"])
            //            {
            [[UIApplication sharedApplication] cancelLocalNotification:notify];
            //            }
            //        }
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastRemindDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // set new date for the date
        NSString* s = [NSString stringWithFormat:@"%@ %@",remindDate,remindTime];
        [formatter setDateFormat:@"EEE d/M/yyyy h:mm a"];
        theDate = [formatter dateFromString:s];
    }
    else {
        theDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastRemindDate"];
    }
    
    if (!theDate) {
        // okie there is no remind time setup
        return;
    }
    
    DLog(@"Last time or select time = %@",theDate);
    NSComparisonResult result = [theDate compare:currDate];
    if (result == NSOrderedAscending) {
        // need to replace now
        // loop until find new date
        while (YES) {
            // save date
            
            switch (freq) {
                case kFreqYear:
                    theDate = [self yearFromDate:theDate];
                    break;
                case kFreq6Months:
                    theDate = [self sixMonthFromDate:theDate];
                    break;
                case kFreq3Months:
                    theDate = [self threeMonthFromDate:theDate];
                    break;
                case kFreqMonthly:
                    theDate = [self monthFromDate:theDate];
                    break;
                case kFreqFortnight:
                    theDate = [self fortnightFromDate:theDate];
                    break;
                case kFreqWeek:
                    theDate = [self weeklyFromDate:theDate];
                    break;
                default:
                    break;
            }
            
            if ([theDate compare:currDate] == NSOrderedDescending) {
                // break;
                break;
            }
        }
    }

    DLog(@"Culculate new time = %@",theDate);
    
    // save last date to user default
    NSUserDefaults  *userDefault= [NSUserDefaults standardUserDefaults];
    [userDefault setObject:theDate forKey:@"LastRemindDate"];
    
    NSMutableDictionary *reminderConfig = [[NSMutableDictionary alloc] init];
//    [reminderConfig setObject:[NSNumber numberWithBool:isEnableReminderOnFrequency] forKey:@"isEnableReminderOnFrequency"];
//    [reminderConfig setObject:[NSNumber numberWithBool:isEnableReminderOnTime] forKey:@"isEnableReminderOnTime"];
    [reminderConfig setObject:[NSNumber numberWithBool:isEnable] forKey:@"isEnable"];
    [reminderConfig setObject:remindDate forKey:@"remindDate"];
    [reminderConfig setObject:remindTime forKey:@"remindTime"];
    
    [reminderConfig setObject:remindFrequency forKey:@"remindFrequency"];
    [reminderConfig setObject:[NSNumber numberWithInt:freq] forKey:@"freq"];
    [[NSUserDefaults standardUserDefaults] setObject:reminderConfig forKey:@"ReminderConfig"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    isUserSaving = NO;
    
    if (!isEnable) {
        return;
    }
    
    //apply new notification
    DLog(@"==> %@",remindFrequency);
    
    // now we set new local notification
    // maximum 10 notification from the last day
    for (int i=0; i<10; i++) {
        // save date
        

        UILocalNotification* notify = [[UILocalNotification alloc] init];
        // now add to notification
        notify.fireDate = theDate;
        notify.timeZone = [NSTimeZone defaultTimeZone];
        notify.repeatInterval = 0;
        notify.soundName = @"alarmsound.caf";
        notify.alertBody = @"Reminder: It's now time to take your monitoring photos";
        notify.userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"isEnableReminderOnTime"];
        [[UIApplication sharedApplication] scheduleLocalNotification:notify];

        //get new date
        switch (freq) {
            case kFreqYear:
                theDate = [self yearFromDate:theDate];
                break;
            case kFreq6Months:
                theDate = [self sixMonthFromDate:theDate];
                break;
            case kFreq3Months:
                theDate = [self threeMonthFromDate:theDate];
                break;
            case kFreqMonthly:
                theDate = [self monthFromDate:theDate];
                break;
            case kFreqFortnight:
                theDate = [self fortnightFromDate:theDate];
                break;
            case kFreqWeek:
                theDate = [self weeklyFromDate:theDate];
                break;
            default:
                break;
        }
    }
}

//UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        if (isEnable) return 3;
        else return 1;
    }
    
    if (isEnable) return frequencies.count;
    else return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) return @"    On Date/Time";
    
    if (isEnable) return @"    Frequency";
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell  = nil;
    
    switch (indexPath.section) {
        case 0:
        {
            if (indexPath.row == 0)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"cell00"];
                if (!cell)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell00"];
                    cell.textLabel.text = @"Enable";
                    
                    if (appDelegate.osVersion >= 8)
                    {
                        cell.layoutMargins = UIEdgeInsetsZero;
                        cell.preservesSuperviewLayoutMargins = NO;
                    }
                    
                    UISwitch* sw = [[UISwitch alloc] init];
                    sw.tag = 11;
                    UIView* vw = [[UIView alloc] initWithFrame:CGRectMake(290 - sw.frame.size.width, 6, sw.frame.size.width, 30)];
                    vw.tag = 1;
                    [vw addSubview:sw];
                    [cell.contentView addSubview:vw];
                    [sw addTarget:self action:@selector(onSwitchEnableReminder:) forControlEvents:UIControlEventValueChanged];
                    enableSwitch = sw;
                }
                
                UISwitch * sw = (UISwitch *)[[cell.contentView viewWithTag:1] viewWithTag:11];
                [sw setOn:isEnable];
                cell.textLabel.text = @"Enable";
            }
            else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"cell01"];
                if (!cell)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell01"];
                    if (appDelegate.osVersion >= 8)
                    {
                        cell.layoutMargins = UIEdgeInsetsZero;
                        cell.preservesSuperviewLayoutMargins = NO;
                    }

                    UITextField* txtField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 180, 34)];
                    txtField.backgroundColor = [UIColor clearColor];
                    txtField.textColor = [UIColor blackColor];
                    txtField.borderStyle = UITextBorderStyleNone;
                    txtField.tag = 11;
                    txtField.delegate = self;
                    
                    UIView* vw = [[UIView alloc] initWithFrame:CGRectMake(290 - txtField.frame.size.width, 5, txtField.frame.size.width, 34)];
                    vw.tag = 1;
                    
                    [vw addSubview:txtField];
                    [cell.contentView addSubview:vw];
                    
                    cell.textLabel.frame = CGRectMake(cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y, 100, cell.textLabel.frame.size.height);
                    cell.textLabel.backgroundColor = [UIColor clearColor];
                }
                
                UITextField * txtField = (UITextField *)[[cell.contentView viewWithTag:1] viewWithTag:11];
                
                if (indexPath.row == 1)
                {
                    txtField.text = remindDate;
                    cell.textLabel.text = @"Date";
                }
                else
                {
                    txtField.text = remindTime;
                    cell.textLabel.text = @"Time";
                }
            }
        }
            break;
            
        case 1:
        {
           
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"cell11"];
                if (!cell)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell11"];
                    if (appDelegate.osVersion >= 8)
                    {
                        cell.layoutMargins = UIEdgeInsetsZero;
                        cell.preservesSuperviewLayoutMargins = NO;
                    }

                }
                
                cell.textLabel.text = [frequencies objectAtIndex:indexPath.row];
                if ([cell.textLabel.text isEqualToString:remindFrequency])
                {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else
                    cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
            break;
            
        default:
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
            if (appDelegate.osVersion >= 8)
            {
                cell.layoutMargins = UIEdgeInsetsZero;
                cell.preservesSuperviewLayoutMargins = NO;
            }
        }
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

//UITableViewDelegate
- (BOOL) tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) return YES;
    
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != 1) return;
    
    DLog(@"index path => %@",indexPath);
    freq = indexPath.row;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    remindFrequency = [frequencies objectAtIndex:indexPath.row];
    
    [tbView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}

//UITextFieldDelegate
- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    id vw = textField.superview;
    while (vw && ![vw isKindOfClass:[UITableViewCell class]]) {
        vw = [vw superview];
    }
    
    UITableViewCell* cell = (UITableViewCell*) vw;
    
    if ([cell.textLabel.text isEqualToString:@"Date"])
    {
        [formatter setDateFormat:@"EEE d/M/yyyy"];
        NSDate* date = [formatter dateFromString:remindDate];
        //select date
        [self showDatePicker:date andOnDone:^(NSDate* date){
            
            //            if ([date timeIntervalSinceNow] < 0)
            //            {
            //                date = [NSDate date];
            //            }
            [formatter setDateFormat:@"EEE d/M/yyyy"];
            
            self->remindDate = [formatter stringFromDate:date];
            textField.text = self->remindDate;
        }];
    }
    else if  ([cell.textLabel.text isEqualToString:@"Time"])
    {
        [formatter setDateFormat:@"h:mm a"];
        NSDate* time = [formatter dateFromString:remindTime];
        
        //select time
        [self showTimePicker:time andOnDone:^(NSDate* time){            
            
            [formatter setDateFormat:@"h:mm a"];
            self->remindTime = [formatter stringFromDate:time];
            textField.text = self->remindTime;
        }];
    }
    return NO;
}

//SELETORS
- (void) onSwitchEnableReminder:(id) sender
{
    UISwitch* sw = (UISwitch*)sender;
    if (sw.tag == 11)
    {
        isEnable = sw.isOn;
        //        [tbView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        //
        //sEnableReminderOnFrequency = isEnableReminderOnTime;
        [tbView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationFade];
        
        if (isEnable)
        {
            [appDelegate enableLocalNotificationWithOnDone:nil];
        }
    }
    else if (sw.tag == 12)
    {
        isEnable = sw.isOn;
        [tbView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void) onSave:(id) sender
{
//    NSDictionary* dic = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReminderConfig"];
//    
//    NSMutableDictionary* reminderConfig = [NSMutableDictionary dictionaryWithDictionary:dic];
//    
//    [reminderConfig setObject:[NSNumber numberWithBool:isEnableReminderOnFrequency] forKey:@"isEnableReminderOnFrequency"];
//    [reminderConfig setObject:[NSNumber numberWithBool:isEnableReminderOnTime] forKey:@"isEnableReminderOnTime"];
//    
//    [reminderConfig setObject:remindDate forKey:@"remindDate"];
//    [reminderConfig setObject:remindTime forKey:@"remindTime"];
//    
//    [reminderConfig setObject:remindFrequency forKey:@"remindFrequency"];
//    
//    [[NSUserDefaults standardUserDefaults] setObject:reminderConfig forKey:@"ReminderConfig"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    isUserSaving = YES;
    [self updateReminder];
    
    if (self.onDidTouchNavItemBack)
    {
        self.onDidTouchNavItemBack(nil);
    }
}


#pragma mark utilities

-(NSDate*) yearFromDate:(NSDate*) aDate {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setYear:1];
    NSDate *rtnDate = [cal dateByAddingComponents:comps toDate:aDate options:0];
    
    return rtnDate;
}

-(NSDate*) sixMonthFromDate:(NSDate*) aDate {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setMonth:6];
    NSDate *rtnDate = [cal dateByAddingComponents:comps toDate:aDate options:0];
    
    return rtnDate;
}

-(NSDate*) threeMonthFromDate:(NSDate*) aDate {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setMonth:3];
    NSDate *rtnDate = [cal dateByAddingComponents:comps toDate:aDate options:0];
    
    return rtnDate;
}

-(NSDate*) monthFromDate:(NSDate*) aDate {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setMonth:1];
    NSDate *rtnDate = [cal dateByAddingComponents:comps toDate:aDate options:0];
    
    return rtnDate;
}

-(NSDate*) fortnightFromDate:(NSDate*) aDate {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setDay:14];
    NSDate *rtnDate = [cal dateByAddingComponents:comps toDate:aDate options:0];
    
    return rtnDate;
}

-(NSDate*) weeklyFromDate:(NSDate*) aDate {
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setWeek:1];
    NSDate *rtnDate = [cal dateByAddingComponents:comps toDate:aDate options:0];
    
    return rtnDate;
}

#pragma mark SELECTORS
- (void) onTapFade:(UITapGestureRecognizer*)tap
{
    NSAssert([NSThread isMainThread], @"MAIN THREAD ERROR");
    
    UIView* vwFade = tap.view;
    
    if (onPickerDateDone)
    {
        onPickerDateDone(pickerDate.date);
        onPickerDateDone = nil;
    }
    
    [UIView animateWithDuration:0.3 animations:^(void){
        vwFade.alpha = 0.0;
        pickerDate.frame = CGRectMake(0, 650, 320, 162);
    }];
    
    if (onWPickerDateDone)
    {
        onWPickerDateDone(wpickerDate.currentDate);
        onWPickerDateDone = nil;
    }
    
    [UIView animateWithDuration:0.3 animations:^(void){
        vwFade.alpha = 0.0;
        wpickerDate.frame = CGRectMake(0, 650, 320, 162);
    }];
}

@end
