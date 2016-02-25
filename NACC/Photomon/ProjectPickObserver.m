
#import "ProjectPickObserver.h"

@interface ProjectPickObserver()

#pragma mark PRIVATE
- (void) dismiss;

@end

@implementation ProjectPickObserver

#pragma mark MAIN
- (void) configNavViewController:(UINavigationController*)nav
{
    controllerNav = nav;
    
    UIButton* bt = [[UIButton alloc] initWithFrame:CGRectMake(nav.navigationBar.frame.size.width/2-100, 0, 200, nav.navigationBar.frame.size.height)];
    bt.backgroundColor = [UIColor clearColor];
    [bt addTarget:self action:@selector(onUIControlEventTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [nav.navigationBar addSubview:bt];
    
    pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, nav.view.frame.size.height, nav.view.frame.size.width, 162)];
    pickerView.dataSource = self;
    pickerView.delegate = self;
    
    vwFade = [[UIView alloc] init];
    vwFade.backgroundColor = [UIColor blackColor];
    vwFade.alpha = 0.3;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapVwFade:)];
    [vwFade addGestureRecognizer:tap];
}

#pragma mark PRIVATE
- (void) dismiss
{
    [vwFade removeFromSuperview];
    [UIView animateWithDuration:0.3 animations:^{
        [pickerView setFrame:CGRectMake(0, controllerNav.view.frame.size.height, controllerNav.view.frame.size.width, 162)];
    } completion:^(BOOL finished) {
        [pickerView removeFromSuperview];
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
    id prj = [[APIController shared].projects objectAtIndex:row];
    [[APIController shared] updateCurrentProject:prj];
    
    [self dismiss];
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
    
    int idx = [[APIController shared].projects indexOfObject:[APIController shared].currentProject];
    [pickerView selectRow:idx inComponent:0 animated:NO];

    pickerView.backgroundColor = [UIColor whiteColor];
    
    vwFade.frame = controllerNav.view.bounds;
    vwFade.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
    [controllerNav.view addSubview:vwFade];
    
    [controllerNav.view addSubview:pickerView];
    [UIView animateWithDuration:0.3 animations:^{
        pickerView.frame = CGRectMake(0, controllerNav.view.frame.size.height-162, controllerNav.view.frame.size.width, 162);
    }];
}

@end
