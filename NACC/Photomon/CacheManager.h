//
//  CacheManager.h
//  Photomon
//  Copyright © 2018 Appiphany. All rights reserved.
//

#import <Foundation/Foundation.h>
#define CACHE_KEY @"CacheItems"
#define CACHE_ID @"CacheId"
@interface CacheManager : NSObject
+(CacheManager*) share;
-(void) addCache:(NSMutableDictionary*) dict forKey:(NSString*) key;
- (void) removeCache:(NSString*) key;
-(NSArray*) getCaches;
@end
