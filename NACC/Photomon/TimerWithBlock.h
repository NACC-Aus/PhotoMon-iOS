#import <Foundation/Foundation.h>

//==================================================
//  TIMER BLOCK
//==================================================
@interface TimerBlock : NSObject {
    void(^onExec)(NSTimer*);
}

//----------------------------------------
//  MAIN
//----------------------------------------
- (id) initWithBlock:(void(^)(NSTimer*))_onExec;
- (void) execWithTimer:(NSTimer*)timer;
@end

//==================================================
//  NSTIMER - Override
//==================================================
@interface NSTimer (Override) 

//----------------------------------------
//  STATIC
//----------------------------------------

//when call start session,all nstimer which be created will belong to session within name 
//call endsession if you need to destroy all timers of particular session
+ (void) startSession:(NSString*)name;
+ (void) continueSession:(NSString*)name;
+ (void) endSession:(NSString*)name;
+ (int) countOfRunningTimers;

+ (id) timerWithTimeout:(float)seconds andBlock:(void(^)(NSTimer*))onTimeout;
+ (id) timerWithInterval:(float)seconds andBlock:(void(^)(NSTimer*))onInterval;

@end

