
#import <UIKit/UIKit.h>

@interface WDatePicker : UIPickerView<UIPickerViewDelegate,UIPickerViewDataSource>
{
    NSDateFormatter* formatter;
    NSMutableArray* weekDays;
    NSMutableArray* days;
    NSMutableArray* months;
    NSMutableArray* years;
}

@property (nonatomic,strong) NSDate* currentDate;

//MAIN
- (void) loadData;
- (void) updateView;
- (void) dataLoaded;

@end
