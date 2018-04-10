

#import "SettingViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

#pragma mark INIT
- (void)viewDidLoad {
    //init
    lstObjs = [[NSMutableArray alloc] init];
    
    //go
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self refreshView];
    [self reloadData];
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

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    if ([self.navigationController visibleViewController] == nil)
    {
        if (self.onDidMoveOut) self.onDidMoveOut(nil);
    }
}

- (void)dealloc
{
    NLog(@"RELEASE %@",NSStringFromClass([self class]));
}

#pragma mark MAIN
- (void) reloadData
{
    [lstObjs addObjectsFromArray:@[
                                   @{@"cmd":@"Info",@"text":@"Info",@"transition":@"push"},
                                   @{@"cmd":@"Donate",@"text":@"Donate",@"transition":@"none"},
                                   @{@"cmd":@"Reminder",@"text":@"Reminder",@"transition":@"push"},
                                   ]];
    
    
    
    [lstObjs addObject:@{@"cmd":@"ManageAdhoc",@"text":@"Manage sites",@"transition":@"push"}];
    
//    if (![[APIController shared] checkIfDemo])
//    {
//        [lstObjs addObject:@{@"cmd":@"RefreshGuides",@"text":@"Refresh guide photos",@"transition":@"none"}];
//    }
    [lstObjs addObject:@{@"cmd":@"Logout",@"text":@"Logout",@"transition":@"none"}];
    
    [self refreshView];
}

- (void) refreshView
{
    [self setTitle:@"Settings"];
    [tbView reloadData];
}

#pragma mark UITableViewDataSource,UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return lstObjs.count;
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
        [cell.textLabel setTextColor:[UIColor blackColor]];
        
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.1];
        
        if (appDelegate.osVersion >= 8)
        {
            cell.layoutMargins = UIEdgeInsetsZero;
            cell.preservesSuperviewLayoutMargins = NO;
        }
    }
    
    id obj = [lstObjs objectAtIndex:indexPath.row];
    [cell.textLabel setText:[obj objectForKey:@"text"]];
    
    BOOL isUsePushTransition = [[obj objectForKey:@"transition"] isEqualToString:@"push"];
    if (isUsePushTransition)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id obj = [lstObjs objectAtIndex:indexPath.row];
    
    if (self.onDidTouchSettingCmd)
    {
        self.onDidTouchSettingCmd(obj);
    }
}
@end
