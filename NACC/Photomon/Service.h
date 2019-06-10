
#import <Foundation/Foundation.h>

#define NotifyAdhocSitesGetChanged              @"NotifyAdhocSitesGetChanged"

@interface Service : NSObject
{
    NSMutableDictionary* dataRecordPath; //path -> detail data
}

#pragma mark STATIC
+ (Service*) shared;

#pragma mark MAIN
@property (nonatomic,strong) NSMutableArray* adHocSites;
@property (nonatomic) double minAdHocDistance;
@property (nonatomic,strong) NSMutableDictionary* mapPathImage;
@property (nonatomic,strong) NSMutableDictionary* refSiteToGuides;

- (void) setupInit;

- (void) addNewRecordPath:(NSString*)path andData:(NSDictionary*)d;
- (void) updateRecordPath:(NSString*)path andData:(NSDictionary*)d;
- (void) deleteRecordPath:(NSString*)path;
- (NSDictionary*) getDataOfRecordPath:(NSString*)path;

- (BOOL) checkIfSiteNameAvailable:(NSString*)name;
- (void) addNewAdHocSiteWithData:(NSDictionary*)data;
- (void) updateAdhocSite:(NSDictionary*)data withNewName:(NSString*)newName;
- (NSMutableArray*) getAllSiteModels;

- (NSString*) getNonce;
- (UIImage*) loadImageOfFile:(NSString*)path;
@end
