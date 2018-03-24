

#import <Foundation/Foundation.h>

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIProgressDelegate.h"
#import "JSONKit.h"
#import "Site.h"
#import "Photo.h"

//#define DEFAULT_SERVER @"http://192.168.11.108:3001"

//#define DEFAULT_SERVER @"http://beachmonitoring.nacc.com.au/"
#define DEFAULT_SERVER @"http://photomon.nacc.com.au/"

#define HOST DEFAULT_SERVER

#define DID_LOAD_SITES @"DID_LOAD_SITES"
#define TIME_OUT 60

#define NotifyUploadProgress                @"NotifyUploadProgress"
#define NotifyUploadFailed                  @"NotifyUploadFailed"
#define NotifyUploadCompleted               @"NotifyUploadCompleted"
#define NotifAppDidRefreshGuidePhotos       @"NotifAppDidRefreshGuidePhotos"

#define NotifProjectsDidRefresh             @"NotifProjectsDidRefresh"

typedef void (^FinishedBlockWithBOOL)(BOOL);
typedef void (^UpdateStatusBlock)(id);
typedef void (^FinishedBlockWithArray)(NSMutableArray*);

@class JKDictionary;

@interface APIController : NSObject<ASIProgressDelegate>
{
    NSString *server;
    UpdateStatusBlock uploadPhotoBlock;
    Photo *photo;
    ASIHTTPRequest *mainRequest;
    
    NSMutableArray* uploadingPaths;
}

+ (APIController*) shared;
+ (NSString*) hashSHA1:(NSString*)input;

@property(nonatomic, strong) ASIHTTPRequest *mainRequest;
@property(nonatomic, strong) Photo *photo;
@property(nonatomic, strong) NSString *server;
@property(nonatomic, strong) NSString *user;

@property (nonatomic,strong) NSMutableArray* projects;
@property (nonatomic,strong) id currentProject;

-(void)login:(NSString*)email andPassword:(NSString*)password andFinishedBlock:(FinishedBlockWithBOOL)retBlock;

-(void)downloadAllSites:(FinishedBlockWithArray)retBlock;

- (void) cacheProjectsOfUser;
- (void) loadProjects:(BOOL)isNotify;
- (void) getProjectsOfUserWithOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError;
- (void) updateCurrentProject:(id)prj;
- (void) addNewSite:(NSString*) siteName lat:(NSString*)lat lng:(NSString*)lng withOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError;

-(ASIHTTPRequest*)uploadPhoto:(NSData*)photoData withInfo:(id)info andCreatedAt:(NSString*)created_at andNote:(NSString*)note andDirection:(NSString*)direction andSiteID:(NSString*)siteID andUpdateBlock:(UpdateStatusBlock)block andBackground:(BOOL)isBackGround;

-(void)uploadVideo:(NSData*)photoData andDirection:(NSString*)direction andSiteID:(NSString*)siteID andUpdateBlock:(UpdateStatusBlock)block andBackground:(BOOL)isBackGround;

- (void) updateNote:(NSString*)note ofPhotoID:(NSString*)serverID andOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError;

#pragma mark MAIN
- (void) setupInit;
- (void) loadInfoPageWithOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError;

- (BOOL) checkIfDemo;

- (BOOL) checkIfImagePathUploading:(NSString*)path;

@property (nonatomic) BOOL isRefreshingGuidePhotos;
- (void) refreshGuidePhotos;

//offline login
- (void) archiveOfflineLoginWithUser:(NSString*)usr server:(NSString*)aServer password:(NSString*)password accessToken:(NSString*)accessToken;
- (id) getOfflineLoginWithUser:(NSString*)usr server:(NSString*)aServer;

//map photo model
@property (nonatomic,strong) NSMutableDictionary* mapPhoto;
- (Photo*) getPhotoInstanceForID:(NSString*)pid;

@end
