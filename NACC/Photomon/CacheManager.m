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
    dispatch_once(&onceToken, ^
    {
        shared_ = [[CacheManager alloc] init];
    });
    
    return shared_;
}

-(void) addCache:(NSMutableDictionary*) dict forKey:(NSString*) key andType:(int) type
{
    NSDictionary* temp = [self getCaches];
    NSMutableDictionary* caches;
    if(!temp)
    {
        caches = [[NSMutableDictionary alloc] init];
    }
    else
    {
        caches = [temp mutableCopy];
    }
    
    [dict setObject:key forKey:CACHE_ID];
    [dict setObject:[NSNumber numberWithInt:type] forKey:CACHE_TYPE];
    
    [caches setObject:dict forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:caches forKey:CACHE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void) removeCache:(NSString*) key
{
    NSDictionary* dict = [self getCaches];
    if(dict)
    {
        NSMutableDictionary *mutableDict = [dict mutableCopy];
        [mutableDict removeObjectForKey:key];
        
        [[NSUserDefaults standardUserDefaults] setObject:mutableDict forKey:CACHE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(NSDictionary*) getCaches
{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:CACHE_KEY];
    return dict;
}

-(NSDictionary*) getCache:(NSString*) key
{
    NSDictionary* dict = [self getCaches];
    if(dict) {
        return [dict objectForKey:key];
    }
    
    return nil;
}

@end
