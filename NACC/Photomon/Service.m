
#import "Service.h"

@implementation Service

#pragma mark STATIC
static Service* shared_ = nil;

+ (Service*) shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_ = [[Service alloc] init];
    });
    return shared_;
}

#pragma mark MAIN
- (void) setupInit
{
    NSString* path = [@"~/Documents/db" stringByExpandingTildeInPath];
    NSData* data = [NSData dataWithContentsOfFile:path];
    if (!data)
    {
        dataRecordPath = [[NSMutableDictionary alloc] init];
    }
    else
    {
        dataRecordPath = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:nil];
    }
    
    path = [@"~/Documents/adhoc" stringByExpandingTildeInPath];
    data = [NSData dataWithContentsOfFile:path];
    if (data)
    {
        self.adHocSites = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:nil];
    }
    else
    {
        self.adHocSites = [[NSMutableArray alloc] init];
    }

//TEST
    //should be 50, not 10
//END TEST
    self.minAdHocDistance = 50;
    
    self.refSiteToGuides = [[NSMutableDictionary alloc] init];
}

- (void) addNewRecordPath:(NSString*)path andData:(NSDictionary*)d
{
    [dataRecordPath setObject:d forKey:path];
    
    NSString* db = [@"~/Documents/db" stringByExpandingTildeInPath];
    NSData* data = [NSJSONSerialization dataWithJSONObject:dataRecordPath options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:db atomically:YES];
}

- (void) updateRecordPath:(NSString*)path andData:(NSDictionary*)d
{
    [dataRecordPath setObject:d forKey:path];
    
    NSString* db = [@"~/Documents/db" stringByExpandingTildeInPath];
    NSData* data = [NSJSONSerialization dataWithJSONObject:dataRecordPath options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:db atomically:YES];
}

- (void) deleteRecordPath:(NSString*)path
{
    [dataRecordPath removeObjectForKey:path];
    
    NSString* db = [@"~/Documents/db" stringByExpandingTildeInPath];
    NSData* data = [NSJSONSerialization dataWithJSONObject:dataRecordPath options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:db atomically:YES];
}

- (NSDictionary*) getDataOfRecordPath:(NSString*)path
{
    return [dataRecordPath objectForKey:path];
}

- (BOOL) checkIfSiteNameAvailable:(NSString*)name
{
    for (id site in self.adHocSites)
    {
        if ([[site objectForKey:@"Name"] isEqualToString:name]) return NO;
    }
    return YES;
}

- (void) addNewAdHocSiteWithData:(NSDictionary*)data //ID , Name , Longitude , Latitude
{
    [self.adHocSites addObject:data];
    
    NSString* db = [@"~/Documents/adhoc" stringByExpandingTildeInPath];
    NSData* daa = [NSJSONSerialization dataWithJSONObject:self.adHocSites options:NSJSONWritingPrettyPrinted error:nil];
    [daa writeToFile:db atomically:YES];
}

- (void) updateAdhocSite:(NSDictionary*)data withNewName:(NSString*)newName
{
    NSString* oldName = [data objectForKey:@"Name"];
    NSString* oldID = [data objectForKey:@"ID"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    if ([oldName isEqualToString:newName]) return;
    
    if (newName)
    {
        [((NSMutableDictionary*)data) setObject:newName forKey:@"Name"];
        
        //change pref/SavedPhotos and photo name
        //change db
        
        NSMutableArray* marr = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"SavedPhotos"]];

        NSArray* arr = [NSArray arrayWithArray:dataRecordPath.allKeys];
        
        NSString* oldIDD = [NSString stringWithFormat:@"_%@_",oldName];
        NSString* newIDD = [NSString stringWithFormat:@"_%@_",newName];
        
        for (NSString* key in arr)
        {
            if ([key rangeOfString:oldIDD].location != NSNotFound)
            {
                NSString* newPath = [key stringByReplacingOccurrencesOfString:oldIDD withString:newIDD];
                
                NSString* oldFullPath = [documentsDirectory stringByAppendingPathComponent:key];
                NSString* newFullPath = [documentsDirectory stringByAppendingPathComponent:newPath];
                [[NSFileManager defaultManager] moveItemAtPath:oldFullPath toPath:newFullPath error:nil];
                
                [dataRecordPath setObject:[dataRecordPath objectForKey:key] forKey:newPath];
                [dataRecordPath removeObjectForKey:key];

                [marr removeObject:key];
                [marr addObject:newPath];
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:marr forKey:@"SavedPhotos"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else //nil newName mean delete
    {
        id target = nil;
        for (id site in self.adHocSites)
        {
            if ([[site objectForKey:@"ID"] isEqualToString:oldID])
            {
                target = site;
            }
        }
        [self.adHocSites removeObject:target];

        NSString* oldIDD = [NSString stringWithFormat:@"_%@_",oldName];
        
        NSArray* arr = [NSArray arrayWithArray:dataRecordPath.allKeys];
        NSMutableArray* marr = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"SavedPhotos"]];
        
        for (NSString* key in arr)
        {
            if ([key rangeOfString:oldIDD].location != NSNotFound)
            {
                NSString* oldPath = [documentsDirectory stringByAppendingPathComponent:key];
                [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
                
                [dataRecordPath removeObjectForKey:key];
                
                [marr removeObject:key];
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:marr forKey:@"SavedPhotos"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    {
        NSString* db = [@"~/Documents/adhoc" stringByExpandingTildeInPath];
        NSData* daa = [NSJSONSerialization dataWithJSONObject:self.adHocSites options:NSJSONWritingPrettyPrinted error:nil];
        [daa writeToFile:db atomically:YES];
    }
    
    {
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSString* db = [@"~/Documents/db" stringByExpandingTildeInPath];
        NSData* data = [NSJSONSerialization dataWithJSONObject:dataRecordPath options:NSJSONWritingPrettyPrinted error:nil];
        [data writeToFile:db atomically:YES];
    }

    //propagate for other UI changes
    [[NSNotificationCenter defaultCenter] postNotificationName:NotifyAdhocSitesGetChanged object:nil];
}

- (NSMutableArray*) getAllSiteModels
{
    NSMutableArray* models = [[NSMutableArray alloc] init];
    for (id it in self.adHocSites)
    {
        Site *st = [[Site alloc] init];
        st.Name = [it objectForKey:@"Name"];
        st.Longitude = [it objectForKey:@"Longitude"];
        st.ID = [it objectForKey:@"ID"];
        st.Latitude = [it objectForKey:@"Latitude"];
        st.ProjectID = [it objectForKey:@"ProjectID"];
        
        [models addObject:st];
    }
    return models;
}

- (NSString*) getNonce
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef s = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    NSString* s2 = (__bridge NSString*)s ;
    return [s2 stringByReplacingOccurrencesOfString:@"-" withString:@""];
}
@end
