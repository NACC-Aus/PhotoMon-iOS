//
//  CacheManager.h
//  Photomon
//  Copyright © 2018 Appiphany. All rights reserved.
//

#import <Foundation/Foundation.h>
#define CACHE_KEY @"CacheItems"
#define CACHE_ID @"CacheId"
#define CACHE_TYPE @"CacheType"

#define TYPE_SITE 0
#define TYPE_MARK_GUIDE 1
#define TYPE_REMOVE_GUIDE 2

@interface CacheManager : NSObject
+(CacheManager*) share;
-(void) addCache:(NSMutableDictionary*) dict forKey:(NSString*) key andType:(int) type;
- (void) removeCache:(NSString*) key;
-(NSDictionary*) getCaches;
-(NSDictionary*) getCache:(NSString*) key;

@end
