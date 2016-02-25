#ifndef LibDefines_h
#define LibDefines_h

#import <math.h>

#ifdef DEBUG
#	define DLog(fmt, ...)                           NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#   define NLog(...)                                NSLog(__VA_ARGS__)
#else
#	define                                          DLog(...)
#   define                                          NLog(...)
#endif

#define SCREEN_SIZE                                 [UIScreen mainScreen].bounds.size //point
#define SCREEN_SCALE                                [UIScreen mainScreen].scale // point -> pixel

// Convenient RGB macro
#define UIColorFromRGB(rgbValue)                    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromRGBA(__r__,__g__,__b__,__a__)    [UIColor colorWithRed:__r__ green:__g__ blue:__b__ alpha:__a__]

#define RADIAN(__degree__)                          M_PI*(__degree__)/180.0
#define POINT(__x__,__y__)                          CGPointMake(__x__,__y__)
#define RECT(__x__,__y__,__w__,__h__)               CGRectMake(__x__,__y__,__w__,__h__)
#define SIZE(__w__,__h__)                           CGSizeMake(__w__,__h__)

#define str(fmt,...)                                [NSString stringWithFormat:fmt,##__VA_ARGS__]

#define JSONMutable                                 NSJSONReadingAllowFragments|NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves

#define AUTOSIZE_FULL                               UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth
#define AUTOSIZE_HOZ                                UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth
#define AUTOSIZE_VER                                UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight

#define CATransform3DPerspective(t, x, y)           (CATransform3DConcat(t, CATransform3DMake(1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1)))
#define CATransform3DMakePerspective(x, y)          (CATransform3DPerspective(CATransform3DIdentity, x, y))

#endif

