//
//  NSObject+Wrapper.m
//  MyLocks
//
//  Created by luongnguyen on 7/24/14.
//  Copyright (c) 2014 luongnguyen2506. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+Wrapper.h"

@interface NSObject (Private)

- (void) fillPropertiesWithDictionary:(NSDictionary*)dict forClass:(Class)cls;
- (NSDictionary*) getPropertiesDictionaryOfClass:(Class)cls;

@end

@implementation NSObject (Wrapper)
#pragma mark STATIC
static const char* detailPropertyName_ = "detailPropertyName_";
static NSMutableDictionary* propNamesOfClasses_ = nil;

+ (NSArray*) getPropNamesOfClass:(NSString*)clsName
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        propNamesOfClasses_ = [[NSMutableDictionary alloc] init];
    });
    
    NSArray* props = [propNamesOfClasses_ objectForKey:clsName];
    if (!props)
    {
        NSMutableArray* arr = [NSMutableArray array];
        
        Class cls = NSClassFromString(clsName);
        unsigned int outCount;
        objc_property_t *properties = class_copyPropertyList(cls, &outCount);
        for (int i = 0; i < outCount; i++)
        {
            objc_property_t property = properties[i];
            const char *name = property_getName(property);
            NSString* propName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            [arr addObject:propName];
        }
        
        [propNamesOfClasses_ setObject:arr forKey:clsName];
        props = arr;
    }
    
    return props;
}

#pragma mark MAIN

- (void) fillPropertiesWithDictionary:(NSDictionary*)dict
{
    if (!dict || [dict isKindOfClass:[NSNull class]])
    {
        return;
    }
    
    [self setDetail:dict forKey:@"PropertiesFilled"];

    Class cls = [self class];
    [self fillPropertiesWithDictionary:dict forClass:cls];
    
    if ([[cls superclass] isSubclassOfClass:[NSObject class]])
    {
        [self fillPropertiesWithDictionary:dict forClass:[cls superclass]];
    }
}

- (id) fillCustomObjectWithDictionary:(NSDictionary*)dict
{
    return nil;
}

- (NSDictionary*) getPropertiesDictionary
{
    NSDictionary* d = [self getDetailOfKey:@"PropertiesFilled"];
    if (d) return d;
    
    return [self getPropertiesDictionaryOfClass:[self class]];
}

- (void) setDetail:(id)value forKey:(NSString*)key
{
    NSMutableDictionary* d = objc_getAssociatedObject(self, detailPropertyName_);
    if (!d)
    {
        d = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, detailPropertyName_, d, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [d setObject:value forKey:key];
}

- (id) getDetailOfKey:(NSString*)key;
{
    NSMutableDictionary* d = objc_getAssociatedObject(self, detailPropertyName_);
    if (!d)
    {
        d = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, detailPropertyName_, d, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return [d objectForKey:key];
}

- (void) removeDetailOfKey:(NSString*)key
{
    NSMutableDictionary* d = objc_getAssociatedObject(self, detailPropertyName_);
    if (!d)
    {
        d = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, detailPropertyName_, d, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [d removeObjectForKey:key];
}

- (void) clearAllDetails
{
    NSMutableDictionary* d = objc_getAssociatedObject(self, detailPropertyName_);
    if (!d)
    {
        d = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, detailPropertyName_, d, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [d removeAllObjects];
}

#pragma mark PRIVATE
- (void) fillPropertiesWithDictionary:(NSDictionary*)dict forClass:(Class)cls
{
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    for (int i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        const char *attr = property_getAttributes(property);
        
        NSString* propName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        NSString* propType = [NSString stringWithCString:attr encoding:NSUTF8StringEncoding];
        
        id v = [dict objectForKey:propName];
        
        if ([v isKindOfClass:[NSArray class]])
        {
            NSMutableArray* arrayObj = [NSMutableArray array];
            
            for (id custom in v)
            {
                if ([self respondsToSelector:@selector(fillCustomObjectWithDictionary:)])
                {
                    id customObj = [self performSelector:@selector(fillCustomObjectWithDictionary:) withObject:custom];
                    if (customObj)
                    {
                        [arrayObj addObject:customObj];
                    }
                }
            }
            
            [self setValue:arrayObj forKey:propName];
            
            continue;
        }
        
        if ([v isKindOfClass:[NSDictionary class]])
        {
            if ([self respondsToSelector:@selector(fillCustomObjectWithDictionary:)])
            {
                id customObj = [self performSelector:@selector(fillCustomObjectWithDictionary:) withObject:v];
                if (customObj)
                {
                    [self setValue:customObj forKey:propName];
                }
            }
            
            continue;
        }
        
        if (v)
        {
            //type-force
//            if ([propType rangeOfString:@"NSString"].location != NSNotFound && )
//                v = [NSString stringWithFormat:@"%@",v];
//            else if ([propType rangeOfString:@"NSNumber"].location != NSNotFound && ![v isKindOfClass:[NSNumber class]])
//                v = [NSNumber numberWithDouble:[v doubleValue]];
            
            //and assign
            
            if ([v isKindOfClass:[NSNull class]])
            {
                if ([dict objectForKey:@"#IgnoreNullValue"]) continue;
            }
            
            if ([propType rangeOfString:@"NSString"].location != NSNotFound && ![v isKindOfClass:[NSString class]])
            {
                //force to NSString
                v = [NSString stringWithFormat:@"%@",v];
            }
            else if ([propType rangeOfString:@"NSNumber"].location != NSNotFound && ![v isKindOfClass:[NSNumber class]])
            {
                //force default
                v = [NSNull null];
            }
            
            [self setValue:v forKey:propName];
        }
    }
    free(properties);
}

- (NSDictionary*) getPropertiesDictionaryOfClass:(Class)cls
{
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    for (int i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        NSString* propName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        
        id v = [self valueForKey:propName];
        if (v) [d setObject:v forKey:propName];
    }
    
    if ([[cls superclass] isSubclassOfClass:[NSObject class]])
    {
        [d addEntriesFromDictionary:[self getPropertiesDictionaryOfClass:[cls superclass]]];
    }
    return d;

}
@end
