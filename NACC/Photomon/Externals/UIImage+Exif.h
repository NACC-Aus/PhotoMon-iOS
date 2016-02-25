
#import <UIKit/UIKit.h>

@class ExifContainer;

@interface UIImage (Exif)

- (NSData *)addExif:(ExifContainer *)container;

@end
