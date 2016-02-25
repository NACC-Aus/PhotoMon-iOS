

#import "BaseAppViewController.h"

@interface SettingViewController : BaseAppViewController <UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray* lstObjs;
    IBOutlet UITableView* tbView;
}

#pragma mark MAIN
@property (nonatomic,copy) void(^onDidTouchSettingCmd)(id);
@property (nonatomic,copy) void(^onDidMoveOut)(id);

- (void) reloadData;
- (void) refreshView;

@end
