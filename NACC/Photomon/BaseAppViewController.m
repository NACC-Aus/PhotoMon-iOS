

#import "BaseAppViewController.h"

@interface BaseAppViewController ()

@end

@implementation BaseAppViewController

- (void)viewDidLoad {
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.onDidTouchNavItemBack)
    {
        UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"images/back_btn.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onTouchNavItemBack:)];
        self.navigationItem.leftBarButtonItem = bt;
    }
    
    if (self.onDidTouchNavItemDone)
    {
        UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onTouchNavItemDone:)];
        self.navigationItem.rightBarButtonItem = bt;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark SELECTOR
- (void) onTouchNavItemBack:(id)sender
{
    if (self.onDidTouchNavItemBack)
    {
        self.onDidTouchNavItemBack(nil);
    }
}

- (void) onTouchNavItemDone:(id)sender
{
    if (self.onDidTouchNavItemDone)
    {
        self.onDidTouchNavItemDone(nil);
    }
}
@end
