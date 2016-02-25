
#import "Reachability.h"
#import "TimerWithBlock.h"
#import "NetworkManager.h"

@implementation NetworkManager

#pragma mark INIT
- (id) init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onkReachabilityChangedNotification:) name:kReachabilityChangedNotification object:nil];
        reach = [Reachability reachabilityForInternetConnection];
        [reach startNotifier];
        [NSTimer timerWithTimeout:2.0 andBlock:^(NSTimer* tmr) {
            [self onkReachabilityChangedNotification:nil];
        }];
    }
    return self;
}

#pragma mark MAIN

#pragma mark SELECTORs
- (void) onkReachabilityChangedNotification:(NSNotification*)notif
{
    if (self.onNetworkChange)
    {
        NSString* type = @"";
        if (reach.currentReachabilityStatus == ReachableViaWiFi)
        {
            type = @"Wifi";
        }
        else if (reach.currentReachabilityStatus == ReachableViaWWAN)
        {
            type = @"Cellular";
        }
        else if (reach.currentReachabilityStatus == NotReachable)
        {
            type = @"Offline";
        }
        self.onNetworkChange(type);
    }
}
@end
