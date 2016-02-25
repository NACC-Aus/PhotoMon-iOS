#import <Foundation/Foundation.h>

@interface DownloadRequest : NSObject {
    
}

// TYPE DEFINITION
typedef void (^DownloaderFailureBlock) (NSError*);
typedef void (^DownloaderCompletionBlock)(NSData *data);

typedef enum DOWNLOAD_PRIORITY {
    DOWNLOAD_PRIORITY_NONE,
    DOWNLOAD_PRIORITY_LOW,
    DOWNLOAD_PRIORITY_HIGH,
    DOWNLOAD_PRIORITY_AS_SOON_AS_POSSIBLE
} DOWNLOAD_PRIORITY;

#define DEFAULT_TIME_OUT    15

@property   (nonatomic, strong) DownloaderFailureBlock failureBlock;
@property   (nonatomic, strong) DownloaderCompletionBlock  completionBlock;
@property   (nonatomic, strong) NSString    *url;
@property   (nonatomic)         DOWNLOAD_PRIORITY    priority;
@property   (nonatomic,strong)   NSString    *completedPath;
@property   (nonatomic)          BOOL        completed;
@property   (nonatomic, strong) NSDictionary    *userInfo;
@property   (readonly,nonatomic)NSString    *requestId;
@property   (nonatomic)         BOOL        allowCached;
@property   (nonatomic)         BOOL        allowForceRedownload;
@property   (nonatomic)         NSTimeInterval  timeout;
@property   (nonatomic)         BOOL        getThumbOnly;

+(DownloadRequest*) requestWithURL:(NSString*) aURL;
+(DownloadRequest*) requestWithURL:(NSString*) aURL andCompletionBlock:(DownloaderCompletionBlock) aCompletionBlock andFailureBlock:(DownloaderFailureBlock) aFailureBlock;

-(void) go;
-(void) cancel;
-(void) updatePriority:(DOWNLOAD_PRIORITY)  aPriority;
@end
