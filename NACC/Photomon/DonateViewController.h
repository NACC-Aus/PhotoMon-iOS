
#import <UIKit/UIKit.h>

@interface DonateViewController : BaseAppViewController<UITableViewDataSource,UITableViewDelegate , UIWebViewDelegate>
{
    NSMutableArray* data;
    IBOutlet UITableView* tbView;
    IBOutlet UIView* vwFade;
    IBOutlet UIWebView* wbView;

    NSString* headerText;
    
    int selectedIdx;
    UIAlertView* alertView;
    BOOL isViewAppeared;
    UIBarButtonItem* btBack;
}

#pragma mark STATIC
+ (DonateViewController*) shared;

@end
