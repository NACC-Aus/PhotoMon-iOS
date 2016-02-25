//
//  NSString+FontSize.h
//
//
// on 7/22/10.
// Rubify. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NSString(FontSizeAdjust) 

- (CGFloat)fontSizeForWidth:(CGFloat)width andHeight:(CGFloat)textHeight andInitialFont:(UIFont *)initialFont;

@end
