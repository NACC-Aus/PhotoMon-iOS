//
//  CacheManager.m
//  Photomon
//
//  Copyright © 2018 Appiphany. All rights reserved.
//

#import "CacheManager.h"

@implementation CacheManager
static CacheManager* shared_ = nil;

+(CacheManager*) share
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_ = [[CacheManager alloc] init];
    });
    
    return shared_;
}

-(void) addCache:(NSMutableDictionary*) dict forKey:(NSString*) key
{
    NSArray* arr = [self getCaches];
    NSMutableArray* caches;
    if(!arr){
        caches = [[NSMutableArray alloc] init];
    }else{
        caches = [arr mutableCopy];
    }
    
    [dict setObject:key forKey:CACHE_ID];
    [caches addObject:dict];
    [[NSUserDefaults standardUserDefaults] setObject:caches forKey:CACHE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void) removeCache:(NSString*) key
{
    NSArray* arr = [self getCaches];
    if(arr) {
        NSMutableArray* caches = [[NSMutableArray alloc] init];
        for (id item in arr) {
            NSString* itemId = [item objectForKey:CACHE_ID];
            if(![key isEqualToString:itemId]){
                [caches addObject:item];
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:caches forKey:CACHE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(NSArray*) getCaches{
    NSArray *arr = [[NSUserDefaults standardUserDefaults] objectForKey:CACHE_KEY];
    return arr;
}
@end
