
#import <Foundation/Foundation.h>

@interface Site : NSObject
{
    NSString *ID;
    NSString *Latitude;
    NSString *Longitude;
    NSString *Name;
}

@property(nonatomic, strong) NSString *ID;
@property(nonatomic, strong) NSString *Latitude;
@property(nonatomic, strong) NSString *Longitude;
@property(nonatomic, strong) NSString *Name;
@property(nonatomic, strong) NSString *ProjectID;

@property (nonatomic) double distance;
@end
