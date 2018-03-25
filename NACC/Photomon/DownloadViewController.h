
#import <UIKit/UIKit.h>
#import "Site.h"
#import "MainViewController.h"

@interface DownloadViewController : BaseAppViewController <UITableViewDataSource,UITableViewDelegate>{
    IBOutlet UITableView    *tblView;
    BOOL isSelectAll;
    NSMutableArray  *arrPreloadSites;
    int orientation;
}

@property (nonatomic, strong) NSMutableArray    *arrList;
@property (nonatomic, strong) NSArray* photos;
@property  (nonatomic, weak) MainViewController   *mainController;
@end
