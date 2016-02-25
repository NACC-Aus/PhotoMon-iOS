

#import <UIKit/UIKit.h>
@interface RootViewController : BaseAppViewController<UITextFieldDelegate,UIActionSheetDelegate>
{
    IBOutlet UIButton *btSubmit;
    IBOutlet UIButton* btDemo;
    
    IBOutlet UIScrollView *svContentView;
    IBOutlet UITextField *tfServerName;
    IBOutlet UITextField *tfEmailAddress;
    IBOutlet UITextField *tfPassword;
    CGRect keyboardFrame;
            
}

#pragma mark STATIC
+ (RootViewController*) shared;

#pragma mark MAIN
- (IBAction) wenDemo:(id)sender;
- (IBAction) wenDonate:(id)sender;

@end
