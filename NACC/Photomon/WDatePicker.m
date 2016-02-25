

#import "WDatePicker.h"

@interface WDatePicker(Private)
- (void) resetDateSources;

@end

@implementation WDatePicker

//INIT
- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        weekDays = [[NSMutableArray alloc] initWithArray:@[@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat",@"Sun"]];
        days = [[NSMutableArray alloc] init];
        months = [[NSMutableArray alloc] init];
        years = [[NSMutableArray alloc] init];
        
        formatter = [[NSDateFormatter alloc] init];
        
        for (int i = 1900 ; i < 2100 ; i++)
            [years addObject:[NSString stringWithFormat:@"%d",i]];
        
        for (int i = 1 ; i <= 12 ; i++)
        {
            [months addObject:[NSString stringWithFormat:@"%d",i]];
        }
        
        self.delegate = self;
        self.dataSource = self;
     
        [self setShowsSelectionIndicator:YES];
    }
    return self;
}

//MAIN
- (void) loadData
{
    [self resetDateSources];    
    [self dataLoaded];
}

- (void) updateView
{
    [self reloadAllComponents];
}

- (void) dataLoaded
{
    [self updateView];
}

//PRIVATE
- (void) resetDateSources
{
    if (self.currentDate == nil) return;
    
    [formatter setDateFormat:@"MM yyyy"];
    NSString* s = [formatter stringFromDate:self.currentDate];
    NSArray* arr = [s componentsSeparatedByString:@" "];
    int year = [[arr objectAtIndex:1] intValue];
    int month = [[arr objectAtIndex:2] intValue];
    
    int d = 30;
    switch (month) {
        case 1:case 3:case 5:case 7:case 8:case 10:case 12:
            d = 31;
            break;
        case 2:
        {
            if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))
            {
                d = 28;
            }
            else
            {
                d = 29;
            }
        }
        default:
            d = 30;
            break;
    }
    
    [days removeAllObjects];
    for (int i = 1 ; i<= d; i++)
    {
        [days addObject:[NSString stringWithFormat:@"%d",i]];
    }
}

//UIPickerViewDataSource
- (int) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
//    for (UIView* vw in self.subviews)
//    {
//        if ([NSStringFromClass([vw class]) isEqualToString:@"UIPickerTableView"])
//        {
//            UITableView* tb = (UITableView*)vw;
//            tb.backgroundColor = [UIColor greenColor];
//        }
//    }
    
    switch (component) {
        case 0:
            return days.count;
        case 1:
            return months.count;
        default:
            return years.count;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    if (component == 0) return 160;
    if (component == 1) return 50;
    
    return 110;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    if (!view)
    {
        UIView* vw = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        vw.backgroundColor = [UIColor clearColor];
        view = vw;
        
        UILabel* lb = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 100, 30)];
        lb.backgroundColor = [UIColor clearColor];
        lb.font = [UIFont boldSystemFontOfSize:20];
        
        [vw addSubview:lb];
    }
    
    UILabel* lb = (UILabel*)[[view subviews] objectAtIndex:0];
    if (component == 0)
    {
        lb.text = [days objectAtIndex:row];
    }
    else if (component== 1)
    {
        lb.text = [months objectAtIndex:row];
    }
    else
    {
        lb.text = [years objectAtIndex:row];
    }
    
    return view;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self resetDateSources];
    [self reloadAllComponents];
}

@end
