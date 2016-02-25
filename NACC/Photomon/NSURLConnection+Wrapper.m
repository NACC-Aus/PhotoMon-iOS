//core
#import <UIKit/UIKit.h>

//lib def
#import "LibDefines.h"

//lib base
#import "NSData+Wrapper.h"

//...
#import "NSURLConnection+Wrapper.h"

@implementation NSURLConnection(Wrapper)

#pragma mark STATIC
+ (void) requestGet:(NSString*)surl withParams:(NSDictionary*)params andOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError
{
    BOOL isRequestCookie = NO;
    BOOL isRequestRawResponse = NO;
    
    NSString* ss = @"";
    for (id k in params.allKeys)
    {
        if ([k hasPrefix:@"#isRequestCookie"])
        {
            isRequestCookie = [[params objectForKey:k] boolValue];
            continue;
        }
        
        if ([k hasPrefix:@"#isRequestRawResponse"])
        {
            isRequestRawResponse = [[params objectForKey:k] boolValue];
            continue;
        }
        
        NSString* v = [params objectForKey:k];
        if ([v isKindOfClass:[NSString class]])
        {
            v = [v stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            v = [v stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
        }
        if (ss.length == 0)
        {
            ss = [ss stringByAppendingFormat:@"%@=%@",k,v];
        }
        else
        {
            ss = [ss stringByAppendingFormat:@"&%@=%@",k,v];
        }
    }
    
    NSString* surlWithParams = nil;
    if (ss.length > 0) surlWithParams = [surl stringByAppendingFormat:@"?%@",ss];
    else surlWithParams = surl;
    
    NSURL* url = [NSURL URLWithString:surlWithParams];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
    
    req.HTTPMethod = @"GET";
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse* response,NSData* data,NSError* err){
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        //main thread return
        if (err)
        {
            if (onError) onError(err);
            return;
        }
        
        NSHTTPURLResponse* http = (NSHTTPURLResponse*)response;
        if (http.statusCode >= 500)
        {
            if (onError) onError(@"Server error");
        }
        
        if (isRequestCookie)
        {
            NSHTTPURLResponse* resp = (NSHTTPURLResponse*) response;
            
            NSMutableDictionary* md = [NSMutableDictionary dictionary];
            
            NSMutableDictionary* cookies = [NSMutableDictionary dictionary];
            NSString* ss = [resp.allHeaderFields objectForKey:@"Set-Cookie"];
            NSArray* arr = [ss componentsSeparatedByString:@";"];
            for (NSString* s in arr)
            {
                NSArray* arr2 = [s componentsSeparatedByString:@"="];
                if (arr2.count == 1) continue;
                [cookies setObject:[arr2 objectAtIndex:1] forKey:[arr2 objectAtIndex:0]];
            }
            
            [md setObject:cookies forKey:@"COOKIES"];
            
            if (isRequestRawResponse)
            {
                [md setObject:[data toString] forKey:@"RAW"];
            }
            
            if (onDone) onDone(md);
            return;
        }

        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        
        if (err)
        {
            if (onDone) onDone([data toString]);
            return;
        }
        
        if (onDone)
        {
            onDone(obj);
        }
        
    }];
}

+ (void) requestPost:(NSString*)surl withMethod:(NSString*)method andParams:(NSDictionary*)params andOnDone:(void(^)(id))onDone andOnError:(void(^)(id))onError
{
    NSURL* url = [NSURL URLWithString:surl];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
    
    req.HTTPMethod = method;
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse* response,NSData* data,NSError* err){
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        //main thread return
        if (err)
        {
            if (onError) onError(err);
            return;
        }
        
        NSHTTPURLResponse* http = (NSHTTPURLResponse*)response;
        if (http.statusCode >= 500)
        {
            if (onError) onError(@"Server error");
            return;
        }

        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        if (err)
        {
            if (onError) onError(err);
            return;
        }
        
        onDone(obj);
    }];
}

+ (void) requestPostMultiForm:(NSString*)surl params:(NSDictionary*)params cookies:(NSDictionary*)cookies onDone:(void(^)(id))onDone onError:(void(^)(id))onError
{
    NSURL* url = [NSURL URLWithString:surl];

    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
    
    req.HTTPMethod = @"POST";
    [req setTimeoutInterval:60.0*3];
    
    if (cookies && cookies.count > 0)
    {
        NSMutableString* scookie = [NSMutableString string];
        for (NSString* k in cookies.allKeys)
        {
            [scookie appendFormat:@"%@=%@;",k,[cookies objectForKey:k]];
        }
        [req addValue:scookie forHTTPHeaderField:@"Cookie"];
    }

    NSString* boundary = @"----aBORNDWErnhrRUrEKrMqaSBnsjdypqyqeuroNYUORRYBmdoooooIII";
    NSString* contentType = str(@"multipart/form-data; boundary=%@",boundary);
    [req addValue:contentType forHTTPHeaderField:@"Content-Type"];

    NSData* dataBody = [NSURLConnection constructBodyOfParams:params];
    
    [req setHTTPBody:dataBody];
    
    //post
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        //main thread return
        if (err)
        {
            if (onError) onError(err);
            return;
        }
        
        NSHTTPURLResponse* http = (NSHTTPURLResponse*)response;
        if (http.statusCode >= 500)
        {
            if (onError) onError(@"Server error");
            return;
        }
        
        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        if (err)
        {
            if (onError) onError(err);
            return;
        }
        
        onDone(obj);
    }];
}

+ (NSData*) constructBodyOfParams:(NSDictionary*)params
{
    NSString* boundary = @"----aBORNDWErnhrRUrEKrMqaSBnsjdypqyqeuroNYUORRYBmdoooooIII";

    NSStringEncoding usingEncoding = NSASCIIStringEncoding;
    
    //construct body
    NSMutableData* dataBody = [NSMutableData data];
    
    NSData* delimeter = [str(@"\r\n--%@\r\n",boundary) dataUsingEncoding:usingEncoding];
    NSData* delimeterEnd = [str(@"\r\n--%@--\r\n",boundary) dataUsingEncoding:usingEncoding];
    
    //begin boundary
    [dataBody appendData:[str(@"--%@\r\n",boundary) dataUsingEncoding:usingEncoding]];
    
    //body
    NSArray* allKeys = params.allKeys;
    for (NSString* key in allKeys)
    {
        id obj = [params objectForKey:key];
        
        if (![obj isKindOfClass:[NSString class]] && ![obj isKindOfClass:[UIImage class]])
        {
            NSAssert(NO, @"POST not supported with obj : %@",obj);
        }
        else
        {
            NSString* disposition = nil;
            NSString* typ = nil;
            NSData* objData = nil;
            
            //header
            if ([obj isKindOfClass:[NSString class]])
            {
                disposition = str(@"Content-Disposition: form-data; name=\"%@\"\r\n",key);
                typ = @"\r\n"; //default plaintext ---  @"Content-Type: text/plaintext\r\n\r\n";
                objData = [obj dataUsingEncoding:usingEncoding];
            }
            else if ([obj isKindOfClass:[UIImage class]])
            {
                disposition = str(@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.jpg\"\r\n",key,key);
                typ = @"Content-Type: image/jpeg\r\n\r\n";
                objData = UIImageJPEGRepresentation(obj, 0.5);
            }
            
            [dataBody appendData:[disposition dataUsingEncoding:usingEncoding]];
            [dataBody appendData:[typ dataUsingEncoding:usingEncoding]];
            [dataBody appendData:objData];
            
            //data
            
            if (key == [allKeys lastObject])
            {
                //let end
            }
            else
            {
                [dataBody appendData:delimeter];
            }
        }
    }
    
    //end body
    [dataBody appendData:delimeterEnd];
    return dataBody;
}
@end
