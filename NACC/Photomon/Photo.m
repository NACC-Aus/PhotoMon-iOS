
#import "Photo.h"

@implementation Photo

@synthesize siteID;
@synthesize date;
@synthesize direction;
@synthesize img;
@synthesize isFinished;
@synthesize progress;
@synthesize sID;
@synthesize imgPath;
@synthesize isGuide;
@synthesize thumbPath;

-(id)init
{
    if (self=[super init])
    {
        self.progress = 0;
        self.isGuide = NO;
    }
    return self;
}

@end
