
#import "DonateViewController.h"
//#import "ZooZService.h"
#import "AlertViewWithBlock.h"
#import "TimerWithBlock.h"

@interface DonateViewController ()

@end

@implementation DonateViewController

#pragma mark STATIC
static DonateViewController* shared_ = nil;
+ (DonateViewController*) shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_ = [[DonateViewController alloc] init];
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
    
    self.title = @"Donation";
    
//    headerText = @"Here description of donation ";
//    
//    data = [[NSMutableArray alloc] init];
//    
//    NSArray* arr = @[@"$5",@"$10",@"$20",@"$50",@"$100"];
//    for (NSString * price in arr)
//    {
//        NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:price,@"text",[price substringFromIndex:1],@"price", nil];
//        [data addObject:d];
//    }
//    
//    tbView.dataSource = self;
//    tbView.delegate = self;
//    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Donate" style:UIBarButtonItemStyleDone target:self action:@selector(onDonate:)];

    btBack = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(onViewBack:)];

    wbView.delegate = self;
//    [wbView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://nacc2.appiphany.com.au/mobile/index.html"]]];
    [wbView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://http://photomon.nacc.com.au"]]];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    isViewAppeared = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    isViewAppeared = NO;
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

#pragma mark UITableViewDataSource
//- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 1;
//}
//
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return headerText;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return data.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DonateCell"];
    if (!cell)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"DonateCell" owner:nil options:nil] objectAtIndex:0];
        UIButton* bt = (UIButton*) [cell viewWithTag:2];
        [bt addTarget:self action:@selector(onDonate:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    id obj = [data objectAtIndex:indexPath.row];
    UILabel* lb = (UILabel*)[cell viewWithTag:1];
    lb.text = [obj objectForKey:@"text"];
    
    if (indexPath.row == selectedIdx)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}
 
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == selectedIdx)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    NSIndexPath* oldIndexPath = [NSIndexPath indexPathForRow:selectedIdx inSection:0];
    selectedIdx = indexPath.row;    
    [tableView reloadRowsAtIndexPaths:@[oldIndexPath,indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 55;
//}

#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];    
//    [vwFade setHidden:YES];

    if ([wbView canGoBack])
    {
        self.navigationItem.rightBarButtonItem = btBack;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
//    [vwFade setHidden:NO];
    
    [NSTimer timerWithTimeout:30.0 andBlock:^(NSTimer* tmr){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//        [vwFade setHidden:YES];
    }];
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];    
//    [vwFade setHidden:YES];

    if ([wbView canGoBack])
    {
        self.navigationItem.rightBarButtonItem = btBack;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    if ([[error description] rangeOfString:@"Domain=NSURLErrorDomain"].location != NSNotFound)
    {
        if (self.navigationItem.rightBarButtonItem != nil) return;
        
        [NSTimer timerWithTimeout:10.0 andBlock:^(NSTimer* tmr){
            [wbView reload];
        }];
        
        if (isViewAppeared && alertView == nil)
        {
            alertView = [UIAlertView alertViewTitle:@"Error" andMsg:@"Internet connection failed , please try later !" onOK:^{
                self->alertView = nil;
            }];
        }
    }
}

#pragma mark SELECTORS
- (void) onViewBack:(id) sender
{
    [wbView goBack];
}
- (void) onDonate :(id) sender
{

}
@end
