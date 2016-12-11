
#import <UIKit/UIKit.h>
#import "Photo.h"

@class MainViewController;

typedef void (^ReturnBlock)(Photo*);

@interface ReviewViewController : BaseAppViewController<UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    IBOutlet UIImageView *imgCapturedPhoto;
    IBOutlet UIImageView *imgBackgroundImage;
    IBOutlet UILabel *lbTimeDirection;
    IBOutlet UIButton *btMakeGuide;
    IBOutlet UIButton *btViewPhoto;
    IBOutlet UIView *viewOverlay;
    UIView *holder;
    UIScrollView * imgScrollView;
    Photo *photo;
    ReturnBlock retBlock;
    
    UIScrollView *scrollView2;
    UIImageView *scroll2ImageView;
    UIView *subview;
    NSArray *source;
    
    IBOutlet UIView* vwNotes;
    IBOutlet UITextView* txtViewNotes;
    UIToolbar* toolBarNotes;
    
    __weak IBOutlet UISlider *guideSlider;
    
    __weak IBOutlet UIImageView *guidePhoto;
    IBOutlet UITextField* txtAdhocSite;
}

@property(nonatomic, strong) UIImage *guideImage;
@property(nonatomic, strong) Photo *photo;
@property(nonatomic, strong) NSArray *source;
@property (nonatomic,strong) MainViewController* controllerMain;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andSourcePhoto:(NSArray*)source_ andImage:(Photo*)photo_ andBlock:(ReturnBlock)finished;
- (IBAction) wenNote:(id)sender;

- (IBAction)guideAlphaChanged:(id)sender;

@end
