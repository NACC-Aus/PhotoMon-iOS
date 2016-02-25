#import "DownloadRequest.h"
#import "Downloader.h"
#import "MD5.h"

@implementation DownloadRequest

@synthesize completionBlock;
@synthesize failureBlock;
@synthesize completed;
@synthesize url;
@synthesize priority;
@synthesize completedPath;
@synthesize userInfo;
@synthesize requestId = _requestId;
@synthesize allowCached = _allowCached;
@synthesize allowForceRedownload = _allowForceRedownload;
@synthesize timeout;
@synthesize getThumbOnly = _getThumbOnly;

-(id) init {
    self = [super init];
    if (self) {
        completionBlock = nil;
        failureBlock = nil;
        completed = NO;
        completedPath = nil;
        url = nil;
        priority = DOWNLOAD_PRIORITY_NONE;
        userInfo = nil;
        // generate id
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
        NSString    *uniqueStr = [[dateFormatter stringFromDate:[NSDate date]] stringByAppendingFormat:@" - %@",self.description];
        _requestId = [uniqueStr md5];
        _allowCached = NO;
        _allowForceRedownload = NO;
        _getThumbOnly = NO;
    }
    return self;
}

+(DownloadRequest*) requestWithURL:(NSString*) aURL {
    DownloadRequest *request = [[DownloadRequest alloc] init];
    request.url = aURL;
    request.timeout = DEFAULT_TIME_OUT;
    return request;
}


+(DownloadRequest*) requestWithURL:(NSString*) aURL andCompletionBlock:(DownloaderCompletionBlock) aCompletionBlock andFailureBlock:(DownloaderFailureBlock) aFailureBlock; {
    DownloadRequest *request = [[DownloadRequest alloc] init];
    request.url = aURL;
    request.completionBlock = aCompletionBlock;
    request.failureBlock = aFailureBlock;
    request.timeout = DEFAULT_TIME_OUT;
    return request;
}

-(void) go {
    [[Downloader sharedDownloader] addRequest:self];
}

-(void) cancel {
    [[Downloader sharedDownloader] removeRequest:self];
}

-(void) updatePriority:(DOWNLOAD_PRIORITY)  aPriority {
    // reserve for future use
    DLog(@"THIS METHOD IS RESERVED FOR FUTURE USE");
}

@end
