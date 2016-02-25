
#import <UIKit/UIKit.h>

@interface InfoViewController : BaseAppViewController <UIWebViewDelegate>
{
    IBOutlet UIWebView* webView;
}

#pragma mark MAIN

- (void) setup;

@end
