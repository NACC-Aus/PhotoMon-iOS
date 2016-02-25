
#import "TimerWithBlock.h"

//==================================================
//  TIMER BLOCK
//==================================================
@implementation TimerBlock

#pragma mark MAIN
//----------------------------------------
//  MAIN
//----------------------------------------
-(id) initWithBlock:(void(^)(NSTimer*))_onExec
{
    self=[super init];
    onExec=[_onExec copy];
    
    return self;
}

-(void) execWithTimer:(NSTimer*)timer
{
    if (onExec!=nil) onExec(timer);
}

-(void) dealloc
{
    onExec = nil;
    //[onExec release];    
    //[super dealloc];
}
@end

//==================================================
//  NSTIMER - Override
//==================================================
@implementation NSTimer(Override)

#pragma mark STATIC
//----------------------------------------
//  STATIC
//----------------------------------------
static NSMutableDictionary* sessions_=nil;
static NSString* currentSessionName_=nil;

+(void) startSession:(NSString*)name
{
    if (sessions_==nil) sessions_=[[NSMutableDictionary alloc] init]; 
    
    if ([sessions_ objectForKey:name]==nil)
        [sessions_ setObject:[NSMutableArray array] forKey:name];    
    
    currentSessionName_=name;    
//    DLog(@"[NSTimer] start session %@",name);
}

+(void) continueSession:(NSString*)name
{
    currentSessionName_=name;
//    DLog(@"[NSTimer] continue session %@",name);    
}

+(void) endSession:(NSString*)name
{
    NSMutableArray* arr=[sessions_ objectForKey:name];
    if (arr!=nil)
    {
        for (NSTimer* tm in arr) [tm invalidate];
        [arr removeAllObjects];
    }
//    DLog(@"[NSTimer] end sessionc %@",name);    
}

+ (int) countOfRunningTimers
{
    NSArray* arr=[sessions_ objectForKey:currentSessionName_];
    if (arr!=nil) return arr.count;
    return 0;
}

+(id) timerWithTimeout:(float)seconds andBlock:(void(^)(NSTimer*))onTimeout
{
    TimerBlock *tmrBlock=[[TimerBlock alloc] initWithBlock:onTimeout];    
    //[tmrBlock autorelease];
    NSTimer* tm=[NSTimer scheduledTimerWithTimeInterval:seconds target:tmrBlock selector:@selector(execWithTimer:) userInfo:[NSNumber numberWithInt:1] repeats:NO];
    
    if (currentSessionName_!=nil)
    {
        NSMutableArray* arr=[sessions_ objectForKey:currentSessionName_];
        [arr addObject:tm];
    }
    
    return tm;
}

+(id) timerWithInterval:(float)seconds andBlock:(void(^)(NSTimer*))onInterval
{
    TimerBlock *tmrBlock=[[TimerBlock alloc] initWithBlock:onInterval];    
    //[tmrBlock autorelease];
    
    NSTimer *tm= [NSTimer scheduledTimerWithTimeInterval:seconds target:tmrBlock selector:@selector(execWithTimer:) userInfo:nil repeats:YES];    
    
    if (currentSessionName_!=nil)
    {
        NSMutableArray* arr=[sessions_ objectForKey:currentSessionName_];
        [arr addObject:tm];
    }
    
    return tm;
}
@end
