
#import <CommonCrypto/CommonCrypto.h>
#import "NSData+Wrapper.h"
#import "APIController.h"
#import "TimerWithBlock.h"
#import "NSURLConnection+Wrapper.h"

@implementation APIController

#pragma mark STATIC
static APIController* shared_ = nil;
+ (APIController*) shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_ = [[APIController alloc] init];
    });
    return shared_;
}

+ (NSString*) hashSHA1:(NSString*)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_LONG lng = (CC_LONG) data.length;
    
    CC_SHA1(data.bytes, lng, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

#pragma mark MESS

@synthesize server, photo;

-(id)init
{
    self = [super init];
    if (self)
    {
        self.server = [[NSUserDefaults standardUserDefaults] objectForKey:@"HOST"];
        self.user = [[NSUserDefaults standardUserDefaults] objectForKey:@"USER"];
    }
    return self;
}

#pragma mark- ASIProgressDelegate

- (void) request:(ASIHTTPRequest *)request didProgress:(NSNumber*)progress
{
    if ([progress floatValue] >= 1.0f) return; //completion block already handled it
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:progress,@"percent",request.userInfo,@"info", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:NotifyUploadProgress object:d];
    });
}

#pragma mark- Upload Photo

-(void)uploadVideo:(NSData*)photoData andDirection:(NSString*)direction andSiteID:(NSString*)siteID andUpdateBlock:(UpdateStatusBlock)block andBackground:(BOOL)isBackGround
{
    //no
}

-(ASIHTTPRequest*)uploadPhoto:(NSData*)photoData withInfo:(id)info andCreatedAt:(NSString*)created_at andNote:(NSString*)note andDirection:(NSString*)direction andSiteID:(NSString*)siteID andUpdateBlock:(UpdateStatusBlock)block andBackground:(BOOL)isBackGround
{
    if ([[APIController shared] checkIfDemo])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0],@"percent",info,@"info", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:NotifyUploadProgress object:d];
        });
        return nil;
    }
    
    if (![info objectForKey:@"Photo"])
    {
        NSLog(@"CATCHED");
    }
    Photo* p = [info objectForKey:@"Photo"];
    NSString* path = p.imgPath;
    
    if ([[APIController shared] checkIfImagePathUploading:path])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            uploadPhotoBlock(@[[NSNumber numberWithFloat:-1.0f]]);
            NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:-1.0],@"percent",info,@"info", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:NotifyUploadProgress object:d];
        });
        return nil;
    }
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    uploadPhotoBlock = [block copy];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.server, @"/photos.json"]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
    [request setTimeOutSeconds:TIME_OUT];
    [request setNumberOfTimesToRetryOnTimeout: 5];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request setRequestMethod:@"POST"];
    [request addData:photoData withFileName:@"image.jpg" andContentType:@"image/png" forKey:@"image"];
    [request addPostValue:[def objectForKey:@"AccessToken"] forKey:@"access_token"];
    [request addPostValue:siteID forKey:@"site_id"];
    [request addPostValue:direction forKey:@"direction"];
    [request addPostValue:[self.currentProject objectForKey:@"uid"] forKey:@"project_id"];
    [request addPostValue:created_at forKey:@"created_at"];
    [request addPostValue:note forKey:@"note"];
    
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    [request addPostValue:[NSString stringWithFormat:@"%llu", fileSize] forKey:@"Content-Length"];
    
    request.userInfo = info;
    [uploadingPaths addObject:path];
    
    [request setUploadProgressDelegate:self];
    __block ASIFormDataRequest*  blockRequest = request;
    
    [request setCompletionBlock:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            /*
             Direction = North;
             ID = 51a6f262b186d71a73000001;
             ImageUrl = "http://s3.amazonaws.com/nacc-prod/photos/images/51a6/f262/b186/d71a/7300/0001/original/image.jpg?1369895522";
             Note = "Nokia 1202 ";
             Status = new;
             */
            id resp = [NSJSONSerialization JSONObjectWithData:blockRequest.responseData options:NSJSONReadingAllowFragments error:nil];
            uploadPhotoBlock(@[[NSNumber numberWithFloat:1.0f],resp]);
            
            NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0],@"percent",info,@"info",resp,@"response", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:NotifyUploadProgress object:d];
            [self->uploadingPaths removeObject:path];
            
            blockRequest = nil;
        });
    }];
    
    [request setFailedBlock:^{
        
        NLog(@"\nFailed to uploading\n");
        dispatch_async(dispatch_get_main_queue(), ^{
            uploadPhotoBlock(@[[NSNumber numberWithFloat:-1.0f]]);

            NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:-1.0],@"percent",info,@"info", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:NotifyUploadProgress object:d];
            [self->uploadingPaths removeObject:path];
        });

    }];
        
    if (isBackGround)
    {
        [request startSynchronous];
    }
    else
    {
        [request startAsynchronous];
    }
    
//    self.mainRequest = request;
    return request;
}

- (void) updateNote:(NSString*)note ofPhotoID:(NSString*)serverID andOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/photos/%@", self.server, serverID]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
    [request setTimeOutSeconds:TIME_OUT];
    [request setNumberOfTimesToRetryOnTimeout: 5];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request setRequestMethod:@"PUT"];
    [request addPostValue:[def objectForKey:@"AccessToken"] forKey:@"access_token"];
    [request addPostValue:note forKey:@"note"];
    [request addPostValue:[self.currentProject objectForKey:@"uid"] forKey:@"project_id"];

    [request setCompletionBlock:^{
        if (onDone) onDone(nil);
    }];
    
    [request setFailedBlock:^{
        if (onDone) onError(nil);
    }];
    
    [request startAsynchronous];
}


#pragma mark- Get All Site
-(void)downloadAllSites:(FinishedBlockWithArray)retBlock
{
    if ([[APIController shared] checkIfDemo])
    {
        retBlock([[Service shared] getAllSiteModels]);
        return;
    }
    
    //user-server specific site
    NSString* name = [NSString stringWithFormat:@"%@_sites.json?project_id=%@",self.server,[self.currentProject objectForKey:@"uid"]];
    NSData* data = [name dataUsingEncoding:NSUTF8StringEncoding];
    name = [[data base64EncodedString] stringByReplacingOccurrencesOfString:@"/" withString:@"S"];
    name = [name stringByReplacingOccurrencesOfString:@"=" withString:@"E"];
    
    NSString* pathAllJson = [[[Downloader storagePathForURL:@"temp"] stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathAllJson])
    {
        NSData* data = [NSData dataWithContentsOfFile:pathAllJson];
        JSONDecoder *json = [[JSONDecoder alloc] init];
        NSArray *arr = [json objectWithData:data];
        
        NSMutableArray *retArr = [NSMutableArray array];
        for (NSDictionary *it in arr)
        {
            Site *st = [[Site alloc] init];
            st.Name = [it objectForKey:@"Name"];
            st.Longitude = [it objectForKey:@"Longitude"];
            st.ID = [it objectForKey:@"ID"];
            st.Latitude = [it objectForKey:@"Latitude"];
            st.ProjectID = [it objectForKey:@"ProjectId"];
            [retArr addObject: st];
        }
        
        retBlock(retArr);
    }
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString* accToken = [def objectForKey:@"AccessToken"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@?project_id=%@&access_token=%@", self.server, @"/sites.json",[self.currentProject objectForKey:@"uid"], accToken]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
    [request setTimeOutSeconds:TIME_OUT];
    [request setNumberOfTimesToRetryOnTimeout: 5];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request setRequestMethod:@"GET"];
    
    __weak ASIFormDataRequest* weakRequest = request;
    
    [request setCompletionBlock:^{
        
        [weakRequest.responseData writeToFile:pathAllJson atomically:YES];
        
        JSONDecoder *json = [[JSONDecoder alloc] init];
        NSArray *arr = [json objectWithData:weakRequest.responseData];
//        arr = nil;
        
        NSMutableArray *retArr = [NSMutableArray array];
        for (NSDictionary *it in arr)
        {
            Site *st = [[Site alloc] init];
            st.Name = [it objectForKey:@"Name"];
            st.Longitude = [it objectForKey:@"Longitude"];
            st.ID = [it objectForKey:@"ID"];
            st.Latitude = [it objectForKey:@"Latitude"];
            st.ProjectID = [it objectForKey:@"ProjectId"];

            [retArr addObject: st];
        }
        
        retBlock(retArr);
    }];
    
    [request setFailedBlock:^{
        
//        retBlock(nil);
    }];
    
    [request startAsynchronous];
//    self.mainRequest = request;
}

- (void) addNewSite:(NSString*) siteName lat:(NSString*)lat lng:(NSString*)lng withOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString* accToken = [def objectForKey:@"AccessToken"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.server, @"/sites"]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
    [request setTimeOutSeconds:TIME_OUT];
    [request setNumberOfTimesToRetryOnTimeout: 5];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request setRequestMethod:@"POST"];
    [request addPostValue:accToken forKey:@"access_token"];
    [request addPostValue:siteName forKey:@"name"];
    [request addPostValue:lat forKey:@"latitude"];
    [request addPostValue:lng forKey:@"longitude"];
    [request addPostValue:[self.currentProject objectForKey:@"uid"] forKey:@"project_id"];
    
    __weak ASIFormDataRequest* weakRequest = request;
    
    [request setCompletionBlock:^{
        JSONDecoder *json = [[JSONDecoder alloc] init];
        NSDictionary *dic = [json objectWithData:weakRequest.responseData];
        Site *st = [[Site alloc] init];
        st.Name = [dic objectForKey:@"Name"];
        st.Longitude = [dic objectForKey:@"Longitude"];
        st.ID = [dic objectForKey:@"ID"];
        st.Latitude = [dic objectForKey:@"Latitude"];
        st.ProjectID = [dic objectForKey:@"ProjectId"];        
        onDone(st);
    }];
    
    [request setFailedBlock:^{
        onError(nil);
        //        retBlock(nil);
    }];
    
    [request startAsynchronous];
}
- (void) cacheProjectsOfUser
{
    if ([self checkIfDemo])
    {
        return;
    };
    
    [self getProjectsOfUserWithOnDone:^(id arrProjects){
        
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        
        if (![def objectForKey:[NSString stringWithFormat:@"projects_%@",self.user]])
        {
            [def setObject:arrProjects forKey:[NSString stringWithFormat:@"projects_%@",self.user]];
            [def synchronize];
            
            [self loadProjects:YES];
        }
        else
        {
            [def setObject:arrProjects forKey:[NSString stringWithFormat:@"projects_%@",self.user]];
            [def synchronize];
        }
        
    } andOnError:^(id err) {
        NLog(@"Error while caching projects");
    }];
}

- (void) loadProjects:(BOOL)isNotify
{
    if ([self checkIfDemo])
    {
        self.projects = [[NSMutableArray alloc] initWithArray:@[@{@"uid":@"1",@"name":@"Demo"}]];
        self.currentProject = [self.projects objectAtIndex:0];
        
        if(isNotify)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NotifProjectsDidRefresh object:@{@"projects":self.projects,@"current-project":self.currentProject}];
        }
        
        return;
    }
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSArray* arr = [def objectForKey:[NSString stringWithFormat:@"projects_%@",self.user]];
    
    if (arr)
    {
        self.projects = [[NSMutableArray alloc] initWithArray:arr];
        
        if (self.projects.count > 0)
        {
            self.currentProject = [self.projects objectAtIndex:0];
        }
        
        if (self.currentProject && isNotify)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NotifProjectsDidRefresh object:@{@"projects":self.projects,@"current-project":self.currentProject}];
        }
    }
    
    if(isNotify)
    {
        [self cacheProjectsOfUser];
    }
}

- (void) getProjectsOfUserWithOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString* accToken = [def objectForKey:@"AccessToken"];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@?access_token=%@", self.server, @"/projects",accToken]];
    NSMutableURLRequest * req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"GET"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (err)
        {
            if (onError)
            {
                onError(err);
            }
            return;
        }
        
        NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:nil];
        
        if ([dic objectForKey:@"projects"])
        {
            if (onDone) onDone([dic objectForKey:@"projects"]);
        }
        else
        {
            if (onError) onError(@"Unknown error");
        }
    }];
}

- (void) updateCurrentProject:(id)prj
{
    self.currentProject = prj;
    
    if (self.currentProject)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NotifProjectsDidRefresh object:@{@"projects":self.projects,@"current-project":self.currentProject}];
    }
}

#pragma mark- Login APIs
-(void)login:(NSString*)email andPassword:(NSString*)password andFinishedBlock:(FinishedBlockWithBOOL)retBlock
{
//    NSString *serverAddress = [NSString stringWithFormat:@"%@%@", self.server, @"/sessions.json"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.server, @"/sessions.json"]];
    NSMutableURLRequest * req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    NSString* s = [NSString stringWithFormat:@"email=%@&password=%@",email,password];
    [req setHTTPBody:[s dataUsingEncoding:NSUTF8StringEncoding]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (err)
        {
            retBlock(NO);
            return;
        }
        NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:nil];
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        [def setObject:[dic objectForKey:@"AccessToken"] forKey:@"AccessToken"];
        [def synchronize];
        if ([dic objectForKey:@"AccessToken"]) {
            retBlock(YES);
        }else
        {
            retBlock(NO);
        }        
        
    }];
    
//    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
//    [request setTimeOutSeconds:TIME_OUT];
//    [request setNumberOfTimesToRetryOnTimeout: 5];
//    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
//    [request setRequestMethod:@"POST"];
//    [request addPostValue:email forKey:@"email"];
//    [request addPostValue:password forKey:@"password"];
//    
//    [request setCompletionBlock:^{
//        
//        JSONDecoder *json = [[JSONDecoder alloc] init];
//        NSDictionary *dic = [json objectWithData:request.responseData];
//    }];
//    
//    [request setFailedBlock:^{
//        
//        //NSLog(@"\nFailed request...: %@\n", request.error);
//        retBlock(NO);
//    }];
//    
//    [request startAsynchronous];
//    self.mainRequest = request;
}

#pragma mark MAIN
- (void) setupInit
{
    self.mapPhoto = [[NSMutableDictionary alloc] init];
    
    //download new updated info page
    [[APIController  shared] loadInfoPageWithOnDone:^(id back){
        NSString* path = [@"~/Documents/info.html" stringByExpandingTildeInPath];
        NSData* data = back;
        [data writeToFile:path atomically:YES];
    } andOnError:^(id err){
        //ignore
    }];
    
    uploadingPaths = [[NSMutableArray alloc] init];
}

- (void) loadInfoPageWithOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError
{
    return;
    
    NSString* surl = @"";
    NSURL* url = [NSURL URLWithString:surl];
    NSURLRequest* req = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        if (err)
        {
            if (onError) {
                onError(err);
                return;
            }
        }
        
        if (onDone) onDone(data);
    }];
}

- (BOOL) checkIfDemo
{
    return [self.server isEqualToString:@"demo"];
}

- (BOOL) checkIfImagePathUploading:(NSString*)path
{
    return [uploadingPaths containsObject:path];
}

- (void) refreshGuidePhotos
{
}

- (void) archiveOfflineLoginWithUser:(NSString*)usr server:(NSString*)aServer password:(NSString*)password accessToken:(NSString*)accessToken
{
    //use "usr+aServer" as key to identify login
    
    NSMutableDictionary* usrs = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"usrs"]];
 
    NSString* key = [NSString stringWithFormat:@"%@_%@",usr,aServer];
    
    NSMutableDictionary* d = [usrs objectForKey:key];
    //find - create new if not
    if (!d)
    {
        d = [NSMutableDictionary dictionary];
    }
    else
    {
        d = [NSMutableDictionary dictionaryWithDictionary:d];
    }
    
    [d setObject:[APIController hashSHA1:password] forKey:@"hashed_password"];
    [d setObject:accessToken forKey:@"access_token"];
    
    [usrs setObject:d forKey:key];
    
    [[NSUserDefaults standardUserDefaults] setObject:usrs forKey:@"usrs"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) getOfflineLoginWithUser:(NSString*)usr server:(NSString*)aServer
{
    NSString* key = [NSString stringWithFormat:@"%@_%@",usr,aServer];
    NSDictionary* usrs = [[NSUserDefaults standardUserDefaults] objectForKey:@"usrs"];
    return [usrs objectForKey:key];
}

- (Photo*) getPhotoInstanceForID:(NSString*)pid
{
    Photo* p = nil;
    p = [self.mapPhoto objectForKey:pid];
    
    if (!p)
    {
        p = [[Photo alloc] init];
        [self.mapPhoto setObject:p forKey:pid];
    }
    return p;
}
@end
