//
//  UILabelAutoAdjustHeight.h
//  trackasave
//
// on 5/27/10.
// Rubify. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface UILabel(AutoAdjustHeight)
+ (CGSize)expectedLabelSizeWithFont:(UIFont *)font andWidth:(CGFloat)width andString:(NSString *)str;
+ (CGSize)expectedLabelSizeWithLabel:(UILabel *)label ofString:(NSString *)str;
- (CGSize)expectedSizeWithString:(NSString *)str;
- (void)adjustHeight;
- (void)adjustWidth;
- (void)adjustWidth:(CGFloat)initialSize;

@end

