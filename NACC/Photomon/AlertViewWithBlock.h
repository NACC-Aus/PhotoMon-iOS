

/*
 This version used old block handle mechanism
 */

#import <Foundation/Foundation.h>

@interface AlertBlock : NSObject
@end

//==================================================

@interface UIAlertView(UIAlertView_Block)<UIAlertViewDelegate>

+(id) alertViewTitle:(NSString *) title andMsg:(NSString*)msg onOK:(void(^)(void))_onOK;
+(id) alertViewWithTitle:(NSString *)title andMsg:(NSString*)msg
                       onOK:(void (^)(void))_onOK onCancel:(void (^)(void))_onCancel;
+(id) alertViewWithTitle:(NSString *)title andMsg:(NSString *)msg
                   onYes:(void (^)(void))_onYes onNo:(void(^)(void))_onNo;

@end