
#import "ProjectPickObserver.h"

@interface ProjectPickObserver()

#pragma mark PRIVATE
- (void) dismiss;

@end

@implementation ProjectPickObserver
int height;

#pragma mark MAIN
- (void) configNavViewController:(UINavigationController*)nav
{
    controllerNav = nav;
    
    UIButton* bt = [[UIButton alloc] initWithFrame:CGRectMake(nav.navigationBar.frame.size.width/2-100, 0, 200, nav.navigationBar.frame.size.height)];
    bt.backgroundColor = [UIColor clearColor];
    [bt addTarget:self action:@selector(onUIControlEventTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [nav.navigationBar addSubview:bt];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    UIToolbar *toolBar= [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 36)];
    [toolBar setBarStyle:UIBarStyleDefault];
    toolBar.clipsToBounds = YES;
    toolBar.translucent = YES;
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *barButtonDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneClicked:)];
    toolBar.items = @[flex, barButtonDone];
    
    pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, toolBar.frame.size.height, screenWidth, 162)];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
    
    height = toolBar.frame.size.height + pickerView.frame.size.height;
    
    containerView = [[UIView alloc] initWithFrame:CGRectMake(0, controllerNav.view.frame.size.height, screenWidth, height)];
    containerView.backgroundColor = [UIColor clearColor];
    [containerView addSubview:pickerView];
    [containerView addSubview:toolBar];
    containerView.alpha = 0;
}

#pragma mark PRIVATE
- (void)doneClicked:(id)sender {
    id prj = [[APIController shared].projects objectAtIndex:selectedRow];
    [[APIController shared] updateCurrentProject:prj];
    [self dismiss];
}

- (void) dismiss
{
    [UIView animateWithDuration:0.3 animations:^{
        containerView.alpha = 0;
        containerView.frame = CGRectMake(0, controllerNav.view.frame.size.height, containerView.width, height);
    } completion:^(BOOL finished) {
        [containerView removeFromSuperview];
    }];
}

#pragma mark UIPickerViewDataSource, UIPickerViewDelegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [APIController shared].projects.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[[APIController shared].projects objectAtIndex:row] objectForKey:@"name"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    selectedRow = row;
}

#pragma mark SELECTORS
- (void) onTapVwFade:(UITapGestureRecognizer*)tap
{
    [self dismiss];
}

- (void) onUIControlEventTouchUpInside:(id)sender
{
    if (self.isDisabledPicker)
    {
        return;
    }
    
    if ([APIController shared].projects.count < 2)
    {
        //do nothing
        return;
    }
    
    [pickerView reloadAllComponents];
    
    NSInteger idx = [[APIController shared].projects indexOfObject:[APIController shared].currentProject];
    selectedRow = idx;
    [pickerView selectRow:idx inComponent:0 animated:NO];

    pickerView.backgroundColor = [UIColor whiteColor];
    
    [containerView removeFromSuperview];
    [controllerNav.view addSubview:containerView];
    [UIView animateWithDuration:0.3 animations:^{
        containerView.alpha = 1;
        containerView.frame = CGRectMake(0, controllerNav.view.frame.size.height - height, containerView.width, height);

    }];
}

@end
