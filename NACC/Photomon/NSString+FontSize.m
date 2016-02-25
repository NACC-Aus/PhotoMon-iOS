//
//  NSString+FontSize.m
//
//
// on 7/22/10.
// Rubify. All rights reserved.
//

#import "NSString+FontSize.h"


@implementation NSString(FontSizeAdjust)

- (CGFloat)fontSizeForWidth:(CGFloat)width andHeight:(CGFloat)textHeight andInitialFont:(UIFont *)initialFont 
{
	
	UIFont *textFont = [UIFont fontWithName:initialFont.fontName size:initialFont.pointSize];
	CGFloat newSize = textFont.pointSize;
	CGFloat height = [self sizeWithFont:textFont constrainedToSize:CGSizeMake(width, textHeight*2)].height;


	BOOL shouldContinue = YES;
	if (height > textHeight) {
		
		CGFloat minSize = 10;
		CGFloat maxSize = textFont.pointSize;
		newSize = floor((minSize + maxSize)/2);
		
		while (shouldContinue) {
			textFont = [UIFont fontWithName:initialFont.fontName size:newSize];
			height = [self sizeWithFont:textFont constrainedToSize:CGSizeMake(width, textHeight*2)].height;
			
			if (height > textHeight) {
				maxSize = newSize;
			} else {
				minSize = newSize;
			}	
			
			if (minSize < maxSize-1) {
				newSize = floor((minSize + maxSize)/2);
			} else {
				shouldContinue = NO;
				newSize = minSize;
			}
		}
	}
	
	return newSize;
}

@end
