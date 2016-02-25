//
//  ZooZService.h
//  NACC
//
//  Created by dev1 on 6/14/13.
//  Copyright (c) 2013 Appiphany. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol ZooZPaymentCallbackDelegate;

@interface ZooZService : NSObject<ZooZPaymentCallbackDelegate>
{
    NSMutableDictionary *payData;
    
    void(^onSuccess)(id);
    void(^onUserClose)(id);
    void(^onError)(id);
    
    NSString* serverAPIKey;
}

#pragma mark STATIC
+ (ZooZService*) shared;

#pragma mark MAIN
- (void) setupServerAPIKey:(NSString*)key;

- (void) payForApp:(NSString*)appKey WithCurrencyCode:(NSString*)currency andIsSandbox:(BOOL)isSandbox andFirstName:(NSString*)firstname andLastName:(NSString*)lastname
          andEmail:(NSString*)email andZipCode:(NSString*)zipCode andInvoice:(float)invoice andDescription:(NSString*)description
       andQuantity:(int)quantity andItemName:(NSString*)itemName andItemDetail:(NSString*)detail andItemId:(NSString*)itemid
       andOnSuccess:(void(^)(id))aOnSuccess andOnUserClose:(void(^)(id))aOnUserClose andOnError:(void(^)(id))aOnError;

- (void) getDetailOfTransaction2:(NSString*) transactionID withAppKey:(NSString*)appKey andDevMail:(NSString*)devmail andServer:(NSString*) server andServerVersion:(NSString*) version andOnSuccess:(void(^)(id))aOnSuccess andOnError:(void(^)(id))aOnError;
@end
