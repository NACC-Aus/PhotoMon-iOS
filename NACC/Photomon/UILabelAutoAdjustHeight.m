//
//  UILabelAutoAdjustHeight.m
//  trackasave
//
// on 5/27/10.
// Rubify. All rights reserved.
//

#import "UILabelAutoAdjustHeight.h"
#import "UIViewExtension.h"
#import "NSString+FontSize.h"

@implementation UILabel(AutoAdjustHeight)

+ (CGSize)expectedLabelSizeWithFont:(UIFont *)font andWidth:(CGFloat)width andString:(NSString *)str
{
	return [str sizeWithFont:font forWidth:width lineBreakMode:NSLineBreakByWordWrapping];
}

+ (CGSize)expectedLabelSizeWithLabel:(UILabel *)label ofString:(NSString *)str
{
	return [str sizeWithFont:label.font forWidth:label.frame.size.width lineBreakMode:label.lineBreakMode];
}

- (CGSize)expectedSizeWithString:(NSString *)str
{
	return [UILabel expectedLabelSizeWithLabel:self ofString:str];
}

- (void)adjustHeight
{
	self.lineBreakMode = NSLineBreakByWordWrapping;
	self.numberOfLines = NSIntegerMax;
	
	CGSize maximumLabelSize = CGSizeMake(self.frame.size.width, 9999);
	//UILabel *label = self;
	//CGSize expectedLabelSize = [UILabel expectedLabelSizeWithLabel:label ofString:label.text];
	
	CGSize expectedLabelSize = [self.text sizeWithFont:self.font
									 constrainedToSize:maximumLabelSize 
										 lineBreakMode:self.lineBreakMode];
	
	
	CGRect newFrame = self.frame;
	newFrame.size.height = expectedLabelSize.height;
	self.frame = newFrame;
}

- (void)adjustWidth
{
	[self adjustWidth:15];
}

- (void)adjustWidth:(CGFloat)initialSize
{
	CGFloat s = [self.text fontSizeForWidth:(CGFloat)self.width-10
								  andHeight:(CGFloat)self.height 
							 andInitialFont:[UIFont fontWithName:[self.font fontName] size:initialSize]];
	[self setFont:[UIFont fontWithName:[self.font fontName] size:s]];
}

@end
