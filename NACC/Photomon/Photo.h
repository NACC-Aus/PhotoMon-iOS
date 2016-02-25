
#import <Foundation/Foundation.h>

@interface Photo : NSObject
{
    NSString *siteID;
    NSString *sID;
    NSString *date;
    NSString *direction;
    UIImage *img;
    NSString *imgPath;
    NSString *thumbPath;
    BOOL isFinished;
    float progress;
    BOOL isGuide;
}

@property(nonatomic,readwrite) BOOL isGuide;
@property(nonatomic, strong) NSString *imgPath;
@property(nonatomic,readwrite) float progress;
@property(nonatomic, strong) NSString *siteID;
@property(nonatomic, strong) NSString *projectID;

@property(nonatomic, strong) NSString *date;
@property(nonatomic, strong) NSString *direction;
@property(nonatomic, strong) UIImage *img;
@property(nonatomic,strong) UIImage* imgThumbnail;
@property(nonatomic,strong) NSString *thumbPath;
@property(nonatomic, strong) NSString *sID;
@property(nonatomic,readwrite) BOOL isFinished;
@property (nonatomic) BOOL isUploading;
@property (nonatomic,strong) NSData* imageData;

@property (nonatomic,strong) NSString* note;

@property (nonatomic,weak) id view;

@property (nonatomic) float alphaValue;

@property (nonatomic,strong) NSString* photoID;

@end
