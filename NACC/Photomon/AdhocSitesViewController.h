
#import <UIKit/UIKit.h>

//**************************************************
@interface AdhocSiteTextField : UITextField

@property (nonatomic,weak) NSDictionary* data;
@end

//**************************************************
@interface AdhocSitesViewController : BaseAppViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
{
    BOOL isGotSetupView;
    
    IBOutlet UITableView* tbView;
    UIToolbar* toolBarEdit;
    
    AdhocSiteTextField* currentTextField;
    
    UIBarButtonItem* btEdit;
    UIBarButtonItem* btDone;
    UIBarButtonItem* btAdd;
    NSMutableArray* datasource;
}

#pragma mark MAIN
@property (nonatomic, weak) NSMutableArray* allSites;
- (void) setupView;
@end
