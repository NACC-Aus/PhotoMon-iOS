#pragma once

#import <UIKit/UIKit.h>

@interface PMAlertView : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic) NSInteger tag;
@property (nonatomic) UIAlertViewStyle alertViewStyle;
@property (nonatomic, readonly) NSInteger cancelButtonIndex;
@property (nonatomic, readonly) NSInteger firstOtherButtonIndex;

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                     delegate:(id)delegate
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;
- (void)show;
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;
- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex;
- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;

@end
