

/*
 REQUIRE
    SystemConfiguration
 
 */
#import <Foundation/Foundation.h>

@class Reachability;

@interface NetworkManager : NSObject
{
    Reachability* reach;
}

#pragma mark MAIN
@property (nonatomic,strong) NSString* serverURL;
@property (nonatomic,copy) void(^onNetworkChange)(id);

@end
