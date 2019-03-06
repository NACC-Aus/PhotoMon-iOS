
#import <UIKit/UIKit.h>

@class MapViewController;
@interface ReminderViewController : BaseAppViewController<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UINavigationBarDelegate>
{
    IBOutlet UITableView* tbView;
    
    NSDateFormatter* formatter;
    
//    BOOL isEnableReminderOnTime;
//    BOOL isEnableReminderOnFrequency;
    BOOL isEnable;
    NSString* remindDate;
    NSString* remindTime;
    NSString* remindFrequency;
    
    int freq;
    UISwitch    *enableSwitch;
    NSArray* frequencies;
    NSArray* frequencyIntervals;
    
    BOOL isUserSaving;
    
    BOOL isViewLoaded;
    
    //picker date
    UIDatePicker* pickerDate;
    void(^onPickerDateDone)(id);
    NSMutableArray *uploading;
    
    WDatePicker* wpickerDate;
    void(^onWPickerDateDone)(id);
}

//STATIC
+ (ReminderViewController *) shared;

//MAIN
@property (nonatomic,weak) MapViewController* mapController;
@property (nonatomic,weak) UIAlertView* currentReminderAlert;
@property (nonatomic,weak) IBOutlet UILabel* lbTest;

//date picker
- (void) showDatePicker:(NSDate*)currentDate andOnDone:(void(^)(id))onDone;
- (void) showDatePicker2:(NSDate*)currentDate andOnDone:(void(^)(id))onDone;
- (void) showTimePicker:(NSDate*)currentTime andOnDone:(void(^)(id))onDone;

//update reminder
- (void) updateReminder;

@end
