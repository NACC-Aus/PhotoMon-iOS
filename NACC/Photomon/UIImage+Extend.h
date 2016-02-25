
#import <Foundation/Foundation.h>

@interface UIImage(UIImageFunctions)
- (UIImage *) scaleToSize: (CGSize)size;
- (UIImage *) scaleProportionalToSize: (CGSize)size;
- (UIImage *) resizableImageWithSize:(CGSize)size;
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;
@end
