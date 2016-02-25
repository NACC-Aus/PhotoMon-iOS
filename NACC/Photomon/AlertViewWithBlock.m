
#import "AlertViewWithBlock.h"

@implementation UIAlertView(UIAlertView_Block)

static int _tagID=1;
static NSMutableDictionary* _dictOnOKs=nil; //tag -> onOK
static NSMutableDictionary* _dictOnCancels=nil; //tag -> onCancel
static NSMutableDictionary* _dictOnYeses=nil; //tag -> onYes
static NSMutableDictionary* _dictOnNoes=nil; //tag -> onNo
static NSMutableDictionary* _dictBlocks=nil;//tag->block

+(void) clearDictBlocks
{
    @synchronized(_dictBlocks)
    {
        if (_dictBlocks==nil) _dictBlocks=[[NSMutableDictionary alloc] init ];
        
        //release block objects
        if (_tagID>1)
        {
            for (int i=1;i<10;i++)
            {
                if (_dictBlocks.count>1){
                    NSNumber *nm=[NSNumber numberWithInt:_tagID-i];
                    [_dictBlocks removeObjectForKey:nm];
                    
                    [_dictOnYeses removeObjectForKey:nm] ;
                    [_dictOnNoes removeObjectForKey:nm] ;
                    [_dictOnOKs removeObjectForKey:nm] ;
                    [_dictOnCancels removeObjectForKey:nm] ;
                }
            }
        }
    }
}

+(id) alertViewTitle:(NSString *) title andMsg:(NSString*)msg onOK:(void(^)(void))_onOK
{
    [UIAlertView clearDictBlocks];
    
    void (^onOK)(void)=[_onOK copy];
    
    //[onOK autorelease];
    if (_dictOnOKs==nil) _dictOnOKs=[[NSMutableDictionary alloc] init];
    
    UIAlertView *v=[[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    AlertBlock *blk=[[AlertBlock alloc] init];
    //[blk autorelease];
    [v setDelegate:blk];
    
    _tagID++;
    v.tag=_tagID;
    NSNumber *tag=[NSNumber numberWithInt:v.tag];
    
    if (onOK!=nil) [_dictOnOKs setObject:onOK forKey:tag];
    if (blk!=nil) [_dictBlocks setObject:blk forKey:tag];
    
    //[v autorelease];
    [v show];
    return v;
}

+(id) alertViewWithTitle:(NSString *)title andMsg:(NSString*)msg
                    onOK:(void (^)(void))_onOK onCancel:(void (^)(void))_onCancel
{
    [UIAlertView clearDictBlocks];
    
    void (^onOK)(void)=[_onOK copy];
    void (^onCancel)(void)=[_onCancel copy];
    
    //[onOK autorelease];
    //[onCancel autorelease];
    
    if (_dictOnOKs==nil) _dictOnOKs=[[NSMutableDictionary alloc] init];
    if (_dictOnCancels==nil) _dictOnCancels=[[NSMutableDictionary alloc] init];
    
    UIAlertView *v=[[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    AlertBlock *blk=[[AlertBlock alloc] init];
    //[blk autorelease];
    [v setDelegate:blk];
    
    _tagID++;
    v.tag=_tagID;
    NSNumber *tag=[NSNumber numberWithInt:v.tag];
    if (onOK!=nil) [_dictOnOKs setObject:onOK forKey:tag];
    if (onCancel!=nil) [_dictOnCancels setObject:onCancel forKey:tag];
    if (blk!=nil) [_dictBlocks setObject:blk forKey:tag];
    //[v autorelease];
    
    [v show];
    return v;
}

+(id) alertViewWithTitle:(NSString *)title andMsg:(NSString *)msg
                   onYes:(void (^)(void))_onYes onNo:(void(^)(void))_onNo
{
    [UIAlertView clearDictBlocks];
    
    void (^onYes)(void)=[_onYes copy];
    void (^onNo)(void)=[_onNo copy];
    
    //[onYes autorelease];
    //[onNo autorelease];
    
    if (_dictOnYeses==nil) _dictOnYeses=[[NSMutableDictionary alloc] init];
    if (_dictOnNoes==nil) _dictOnNoes=[[NSMutableDictionary alloc] init];
    
    UIAlertView *v=[[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    
    AlertBlock *blk=[[AlertBlock alloc] init];
    //[blk autorelease];
    [v setDelegate:blk];
    
    _tagID++;
    v.tag=_tagID;
    NSNumber *tag=[NSNumber numberWithInt:v.tag];
    if (onYes!=nil) [_dictOnYeses setObject:onYes forKey:tag];
    if (onNo!=nil) [_dictOnNoes setObject:onNo forKey:tag];
    if (blk!=nil) [_dictBlocks setObject:blk forKey:tag];
    
    //[v autorelease];
    [v show];
    return v;
}

@end

@implementation AlertBlock
- (void) dealloc
{
    //[super dealloc];
}

//==================================================
//Conform to UIAlertViewDelegate
//==================================================
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSNumber *tag=[NSNumber numberWithInt:alertView.tag];
    
    if (buttonIndex==0) //cancel
    {
        void (^onCancel)(void);
        onCancel=[_dictOnCancels objectForKey:tag];
        if (onCancel!=nil){
            onCancel();
            return;
        }
        
        void (^onNo)(void);
        onNo=[_dictOnNoes objectForKey:tag];
        if (onNo!=nil){
            onNo();
            return;
        }
        
        void (^onOK)(void);
        onOK=[_dictOnOKs objectForKey:tag];
        if (onOK!=nil){
            onOK();
            return;
        }
        return;
    }
    
    void (^onOK)(void);
    onOK=[_dictOnOKs objectForKey:tag];
    if (onOK!=nil){
        onOK();
        return;
    }
    
    void (^onYes)(void);
    onYes=[_dictOnYeses objectForKey:tag];
    if (onYes!=nil){
        onYes();
    }
}
@end

