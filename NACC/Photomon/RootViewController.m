
#import "RootViewController.h"
#import "MainViewController.h"
#import "DonateViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

#pragma mark STATIC
static RootViewController* shared_ = nil;

+ (RootViewController*) shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_ = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:[NSBundle mainBundle]];
    });
    return shared_;
}

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
    [btSubmit addTarget:self action:@selector(submit:) forControlEvents:UIControlEventTouchUpInside];
    [self registerForNotifications];
    float height = [UIScreen mainScreen].bounds.size.height;
    if (height >= 480)
    {
        svContentView.top = 10;
    }
    
    svContentView.contentSize = CGSizeMake(320, 600);
    [svContentView scrollsToTop];
    
    svContentView.scrollEnabled = NO;
    tfPassword.delegate = tfEmailAddress.delegate = tfServerName.delegate = self;
    tfPassword.secureTextEntry = YES;
    tfEmailAddress.keyboardType = UIKeyboardTypeEmailAddress;
    
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    if ([df objectForKey:@"HOST"])
    {
        tfServerName.text = [df objectForKey:@"HOST"];
        tfEmailAddress.text = [df objectForKey:@"USER"];
        tfPassword.text = [df objectForKey:@"PASSWORD"];
    }
    else
    {
        tfServerName.text = HOST;
        tfEmailAddress.text = @"";
        tfPassword.text = @"";
    }
    
//    [[DonateViewController shared] view];
    
#ifdef DEBUG
  

#else
    if (tfServerName.isHidden)
    {
        tfServerName.text = @"http://photomon.nacc.com.au";
    }
#endif
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillAppear:animated];
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

#pragma mark- Button Actions
-(void)submit:(id)sender
{
    if (![self validateEmail:tfEmailAddress.text])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Please give a valid email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    if ([tfPassword.text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Please give a password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [tfEmailAddress resignFirstResponder];
    [tfPassword resignFirstResponder];
    [tfServerName resignFirstResponder];
    //NSLog(@"\nserver name: %@\n", tfServerName.text);
    
    //NSLog(@"\nSubmit to server......\n");
    [tfEmailAddress resignFirstResponder];
    [tfPassword resignFirstResponder];
    [tfServerName resignFirstResponder];
    [self adjustTableViewHeightForCoveringFrame:CGRectZero];
    [svContentView scrollRectToVisible:CGRectMake(0, 1, 320, 1) animated:YES];
    //check valid field and start send to server
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    APIController *api = [APIController shared];
    
//    api.server = HOST;
//    if (![[tfServerName.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] isEqualToString:@""]) {
//        api.server = tfServerName.text;
//    }
    
    NSString* serverName = tfServerName.text;
    [APIController shared].server = serverName;
    [APIController shared].user = tfEmailAddress.text;
    
    __block UIButton *bt = (UIButton*)sender;
    bt.userInteractionEnabled = NO;
    [bt setEnabled:NO];
    [btDemo setEnabled:NO];
    
    NSString* p = tfPassword.text;
    NSString* hashedPassword = [APIController hashSHA1:p];
    
    [api login:tfEmailAddress.text andPassword:tfPassword.text andFinishedBlock:^(BOOL back) {
        
        if (back)
        {
            [df setObject:api.server forKey:@"HOST"];
            [df setObject:api.user forKey:@"USER"];
            [df setObject:p forKey:@"PASSWORD"];
            [df synchronize];
            
            [APIController shared].server = serverName;            
            // enable
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"GuideRestore"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Demo"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NavViewController *navi = (NavViewController*) [appDelegate loadMainControllerForAccessToken:[[NSUserDefaults standardUserDefaults] objectForKey:@"AccessToken"]];
            appDelegate.mainViewController = [navi.viewControllers objectAtIndex:0];
            appDelegate.window.rootViewController = navi;
            
            bt.userInteractionEnabled = YES;
            [bt setEnabled:YES];
            [btDemo setEnabled:YES];

            //BEGIN : save for offline login
            [api archiveOfflineLoginWithUser:api.user server:api.server password:p accessToken:[[NSUserDefaults standardUserDefaults] objectForKey:@"AccessToken"]];
            //END            
        }
        else
        {
            //do offline login
            id login = [api getOfflineLoginWithUser:api.user server:api.server];
            if (login)
            {
                if ([[login objectForKey:@"hashed_password"] isEqualToString:hashedPassword])
                {
                    [df setObject:[login objectForKey:@"access_token"] forKey:@"AccessToken"];
                    [df setObject:api.server forKey:@"HOST"];
                    [df setObject:api.user forKey:@"USER"];
                    [df setObject:p forKey:@"PASSWORD"];
                    [df synchronize];
                    
                    [APIController shared].server = serverName;
                    
                    // enable
                    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"GuideRestore"];
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Demo"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    NavViewController *navi = (NavViewController*) [appDelegate loadMainControllerForAccessToken:[[NSUserDefaults standardUserDefaults] objectForKey:@"AccessToken"]];
                    appDelegate.mainViewController = [navi.viewControllers objectAtIndex:0];
                    appDelegate.window.rootViewController = navi;
                    
                    bt.userInteractionEnabled = YES;
                    [bt setEnabled:YES];
                    [btDemo setEnabled:YES];
                
                    return;
                }
            }
            
            if (appDelegate.currentNetworkType == NetworkTypeOffline)
            {
                bt.userInteractionEnabled = YES;
                [bt setEnabled:YES];
                [btDemo setEnabled:YES];
                
                [[[UIAlertView alloc] initWithTitle:@"Information" message:@"The Internet Connection appears to be offline." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                return ;
            }
            
            bt.userInteractionEnabled = YES;
            [bt setEnabled:YES];
            [btDemo setEnabled:YES];
            
//            [[[UIAlertView alloc] initWithTitle:@"Information" message:@"Server Address or Username or Password is wrong." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            [[[UIAlertView alloc] initWithTitle:@"Information" message:@"Username or Password is wrong." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];

        }
    }];

}

#pragma mark MAIN
- (IBAction) wenDemo:(id)sender
{
    [APIController shared].server = @"demo";
    [APIController shared].user = @"demo";
    
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"Demo"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GuideRestore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NavViewController *navi = (NavViewController*) [appDelegate loadMainControllerForAccessToken:@"demo"];
    appDelegate.mainViewController = [navi.viewControllers objectAtIndex:0];
    appDelegate.window.rootViewController = navi;

}

- (IBAction) wenDonate:(id)sender
{
//    DonateViewController* controller = [DonateViewController shared];
//    [self.navigationController pushViewController:controller animated:YES];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://photomon.nacc.com.au/mobile/index.html"]];
}

#pragma mark- UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == tfServerName)
    {
        NSString *serveraddress = tfServerName.text;
        if ([serveraddress stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]].length > 0 && ([serveraddress rangeOfString:@"http://"].location == NSNotFound ))
        {
            serveraddress = [NSString stringWithFormat:@"http://%@", serveraddress];
            tfServerName.text = serveraddress;
        }
        
        if ([serveraddress stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]].length == 0) {
            tfServerName.text = HOST;
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"\n"])
    {
        [textField resignFirstResponder];
        [self adjustTableViewHeightForCoveringFrame:CGRectZero];
        [svContentView scrollRectToVisible:CGRectMake(0, 1, 320, 1) animated:YES];
        if (textField == tfServerName)
        {
            NSString *serveraddress = tfServerName.text;
            if ([serveraddress stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]].length > 0 && ([serveraddress rangeOfString:@"http://"].location == NSNotFound ))
            {
                serveraddress = [NSString stringWithFormat:@"http://%@", serveraddress];
                tfServerName.text = serveraddress;
            }
            
            if ([serveraddress stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]].length == 0) {
                tfServerName.text = HOST;
            }
        }
        return NO;
    }
    return YES;
}

#pragma mark- Helpers Functions
- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}

- (void)registerSelector:(SEL)selector withNotification:(NSString *)notificationKey {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:selector name:notificationKey object:nil];
}

- (void)registerForNotifications
{
	[self registerSelector:@selector(inputManagerWillShow:) withNotification:UIKeyboardWillShowNotification];
}

- (void)inputManagerWillShow:(NSNotification *)notification {
	NSDictionary* info = [notification userInfo];
	CGRect keyboardFrame_ = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	[self adjustTableViewHeightForCoveringFrame:[self rectForOrientationFrame:keyboardFrame_]];
}

- (CGRect)rectForOrientationFrame:(CGRect)frame {
	if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
		return frame;
	}
	else {
		return CGRectMake(frame.origin.y, frame.origin.x, frame.size.height, frame.size.width);
	}
}

- (void)adjustTableViewHeightForCoveringFrame:(CGRect)coveringFrame {
	if (!CGRectEqualToRect(coveringFrame, keyboardFrame)) {
		keyboardFrame = coveringFrame;
		CGRect normalisedWindowBounds = [self rectForOrientationFrame:[[[UIApplication sharedApplication] keyWindow] bounds]];
		CGRect normalisedTableViewFrame = [self rectForOrientationFrame:[svContentView.superview convertRect:svContentView.frame
                                                                                              toView:[[UIApplication sharedApplication] keyWindow]]];
		CGFloat height = CGRectEqualToRect(coveringFrame, CGRectZero) ? 0 : coveringFrame.size.height - (normalisedWindowBounds.size.height - CGRectGetMaxY(normalisedTableViewFrame));
		UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, height, 0);
		svContentView.contentInset = contentInsets;
		svContentView.scrollIndicatorInsets = contentInsets;
        [svContentView scrollRectToVisible:CGRectMake(0, btSubmit.top + 10, 320, btSubmit.height) animated:YES];
	}
}

@end
