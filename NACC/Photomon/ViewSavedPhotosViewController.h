
#import <UIKit/UIKit.h>
#import "EasyTableView.h"
@class MainViewController;

@interface ViewSavedPhotosViewController : BaseAppViewController<EasyTableViewDelegate, UIScrollViewDelegate, UIAlertViewDelegate,UITextViewDelegate>
{
    EasyTableView *horizontalView;
    NSMutableArray *photos;
    int currentIndex;
    UIScrollView *scrollView2;
    UIImageView *scroll2ImageView;
    UIView *zoomView;
    
    NSMutableDictionary* storeImgs ;
    
    BOOL isShowingNote;
    
    UIToolbar* toolBarNotes;
    BOOL isKeyboardShowing;
    UITextView* currentTxtViewNote;
    
    //refresh current view
    NSDate* dateLastRefreshView;
    NSTimer* tmrRefreshView;
    
}

@property (nonatomic,weak) MainViewController* controllerMain;
@property(nonatomic, strong) NSArray *photos;
@property (nonatomic,strong) UIImage* imgThumbnail;

@property (nonatomic,copy) void(^onAttemptToRemovePhoto)(id);

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andPhotos:(NSArray*)photos_ andSelectedIndex:(int)index;
- (BOOL) isGuideAvailableForSite:(NSString*)siteID andDirection:(NSString*)direction andNotPhoto:(Photo*)photo;

- (void) refreshView;
@end
