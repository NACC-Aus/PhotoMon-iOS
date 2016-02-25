
#import "AdhocSitesViewController.h"

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
        UIBarButtonItem* btCancel2 = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(onEditCancel:)];
        UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem* btDone2 = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onEditDone:)];
        [toolBarEdit setItems:@[btCancel2, bt,btDone2]];
        [toolBarEdit sizeToFit];
    }
    
    [self setTitle:@"Ad hoc sites"];
    
    btEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditModeBegin:)];
    btDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onEditModeEnd:)];
    self.navigationItem.rightBarButtonItem = btEdit;
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

- (NSUInteger)supportedInterfaceOrientations
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

    NSUInteger count = [Service shared].adHocSites.count;
    if (count == 0)
    {
        self.navigationItem.rightBarButtonItem = nil;
        tbView.alpha = 0;
        lb.frame = CGRectMake(0, (tableView.frame.size.height-20)/2, tableView.frame.size.width, 20);
        [lb setAlpha:1.0];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = btEdit;
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
    id d = [[Service shared].adHocSites objectAtIndex:indexPath.row];
    [cell bringSubviewToFront:txt];
    txt.text = [d objectForKey:@"Name"];
    txt.data = d;
    
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

@end
