#import "InfoViewController.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

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
    
    [self setTitle:@"Info"];
    
//    UIBarButtonItem* barItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
//    self.navigationItem.rightBarButtonItem = barItem;
    
    webView.delegate = self;
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

#pragma mark MAIN
- (void) setup
{
    [self view];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSString* path = [@"~/Documents/info.html" stringByExpandingTildeInPath];
    if (![fileMgr fileExistsAtPath:path])
    {
        NSString* old = [[NSBundle mainBundle] pathForResource:@"info.html" ofType:@""];
        [fileMgr copyItemAtPath:old toPath:path error:nil];
    }

    //read org source
    //path = [[NSBundle mainBundle] pathForResource:@"info.html" ofType:@""];
    //NSString* src = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    //[webView loadHTMLString:src baseURL:[NSURL URLWithString:@""]];
//    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://nacc2.appiphany.com.au/mobile/info.html"]]];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.nacc.com.au/photomon"]]];
    
}

#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    return YES;
}
#pragma mark SELECTORS
- (void) onDone:(id)sender
{
    DLog(@"Dismiss 2");

    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
