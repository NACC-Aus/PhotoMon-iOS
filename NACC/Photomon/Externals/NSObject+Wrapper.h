//
//  NSObject+Wrapper.h
//  MyLocks
//
//  Created by luongnguyen on 7/24/14.
//  Copyright (c) 2014 luongnguyen2506. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Wrapper)

#pragma mark STATIC
+ (NSArray*) getPropNamesOfClass:(NSString*)clsName;

#pragma mark MAIN
- (void) fillPropertiesWithDictionary:(NSDictionary*)dict;

// for Array or Dictionary propery
- (id) fillCustomObjectWithDictionary:(NSDictionary*)dict;

- (NSDictionary*) getPropertiesDictionary;

- (void) setDetail:(id)value forKey:(NSString*)key;
- (id) getDetailOfKey:(NSString*)key;
- (void) removeDetailOfKey:(NSString*)key;

- (void) clearAllDetails;

@end
