

#import <Foundation/Foundation.h>

@interface ProjectPickObserver : NSObject <UIPickerViewDataSource, UIPickerViewDelegate>
{
    UINavigationController* controllerNav;
    UIPickerView* pickerView;
    UIView* vwFade;
    NSInteger selectedRow;
    UIView* containerView;
}

#pragma mark MAIN

@property (nonatomic) BOOL isDisabledPicker;
- (void) configNavViewController:(UINavigationController*)nav;

@end
