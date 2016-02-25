
#import <UIKit/UIKit.h>

@interface BaseAppViewController : UIViewController
{
    
}

@property (nonatomic,copy) void(^onDidTouchNavItemBack)(id);
@property (nonatomic,copy) void(^onDidTouchNavItemDone)(id); //right bar for dismiss purpupose

@end
