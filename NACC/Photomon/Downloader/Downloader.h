#import <Foundation/Foundation.h>
#import "DownloadRequest.h"

@interface Downloader : NSObject <NSURLConnectionDelegate>{

}



#define DownloaderFinishedDownloadURL     @"DownloaderFinishDownloadURL"

-(void) addRequest:(DownloadRequest*) aRequest;
-(void) removeRequest:(DownloadRequest*) aRequest;

+(Downloader*) sharedDownloader;

-(void) downloadURL:(NSString*) aURL
 andCompletionBlock:(DownloaderCompletionBlock)
aCompletionBlock andFailureBlock:(DownloaderFailureBlock) aFailureBlock;

-(void) downloadWithCacheURL:(NSString*) aURL allowThumb:(BOOL) allowThumb
          andCompletionBlock:(DownloaderCompletionBlock)
aCompletionBlock andFailureBlock:(DownloaderFailureBlock) aFailureBlock;

+(NSString*) storagePathForURL:(NSString*) aURL;
@end
