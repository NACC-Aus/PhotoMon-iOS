//
//  ZooZService.m
//  NACC
//
//  Created by dev1 on 6/14/13.
//  Copyright (c) 2013 Appiphany. All rights reserved.
//

#import "ZooZService.h"
#import "ZooZSDK/ZooZ.h"

@implementation ZooZService

#pragma mark STATIC
static ZooZService* shared_ = nil;

+ (ZooZService*) shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_ = [[ZooZService alloc] init];
    });
    return shared_;
}

#pragma mark MAIN

- (void) setupServerAPIKey:(NSString*)key
{
    serverAPIKey = key;
}

//single item support
- (void) payForApp:(NSString*)appKey WithCurrencyCode:(NSString*)currency andIsSandbox:(BOOL)isSandbox andFirstName:(NSString*)firstname andLastName:(NSString*)lastname
          andEmail:(NSString*)email andZipCode:(NSString*)zipCode andInvoice:(float)invoice andDescription:(NSString*)description
       andQuantity:(int)quantity andItemName:(NSString*)itemName andItemDetail:(NSString*)detail andItemId:(NSString*)itemid
      andOnSuccess:(void(^)(id))aOnSuccess andOnUserClose:(void(^)(id))aOnUserClose andOnError:(void(^)(id))aOnError
{
    if (!aOnSuccess) return;
    
    if (onSuccess) return;
    
    onSuccess = [aOnSuccess copy];
    onUserClose = [aOnUserClose copy];
    onError = [aOnError copy];
    
    ZooZ * zooz = [ZooZ sharedInstance];
    
    zooz.sandbox = isSandbox;
    
    zooz.tintColor = [UIColor colorWithRed:1 green:0.8 blue:0 alpha:1];
    
    zooz.barButtonTintColor = [UIColor darkGrayColor];
    
    ZooZPaymentRequest * req = [zooz createPaymentRequestWithTotal:invoice*quantity  invoiceRefNumber:@"" delegate:self]; //use ref if you want track invoice
    
    req.currencyCode = currency;
    
    req.payerDetails.firstName = firstname;
    req.payerDetails.lastName = lastname;
    req.payerDetails.email = email;
    
    req.requireAddress = NO;
    
    ZooZInvoiceItem * item = [ZooZInvoiceItem invoiceItem:invoice  quantity:quantity  name:itemName];
    item.additionalDetails = detail;
    item.itemId = itemid; // optional
    
    [req addItem:item];
    
    req.invoice.additionalDetails = description;
    
    [zooz openPayment:req forAppKey:appKey];
}

- (void) getDetailOfTransaction:(NSString*) transactionID withAppKey:(NSString*)appKey andDevMail:(NSString*)devmail andServer:(NSString*) server andServerVersion:(NSString*) version andOnSuccess:(void(^)(id))aOnSuccess andOnError:(void(^)(id))aOnError;
{
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:server]];
    req.HTTPMethod = @"POST";
    [req addValue:devmail forHTTPHeaderField:@"ZooZDeveloperId"];
    [req addValue:serverAPIKey forHTTPHeaderField:@"ZooZServerAPIKey"];
    
    NSString* src = [NSString stringWithFormat:@"cmd=getTransactionDetails&ver=1.4.5&transactionID=%@",transactionID];
    req.HTTPBody = [src dataUsingEncoding:NSUTF8StringEncoding];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError * error) {
        if (error)
        {
            if (aOnError) aOnError(error);
            return;
        }
        
        NSError* err;
        id back = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments|NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&err];
        if (err)
        {
            if (aOnError) aOnError(err);
            return;
        }
        
        if (aOnSuccess) aOnSuccess(back);
    }];
}

#pragma mark ZooZPaymentCallBackDelegate
- (void)openPaymentRequestFailed:(ZooZPaymentRequest *)request withErrorCode:(int)errorCode andErrorMessage:(NSString *)errorMessage{
	NSLog(@"failed: %@", errorMessage);
    
    //this is a network / integration failure, not a payment processing failure.
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (onError) onError(errorMessage);
        
        onSuccess = nil ;
        onError = nil;
        onUserClose = nil;
    
    });
}

//Called in the background thread - before user closes the payment dialog
//Do not refresh UI at this callback - see paymentSuccessDialogClosed
- (void)paymentSuccessWithResponse:(ZooZPaymentResponse *)response
{
    dispatch_async(dispatch_get_main_queue(), ^{

        payData = [[NSMutableDictionary alloc] init];
        [payData setObject:response.transactionID forKey:@"transactionID"];
        
        NSLog(@"payment success with payment Id: %@, %@, %@, %f %@", response.transactionDisplayID, response.fundSourceType, response.lastFourDigits, response.paidAmount, response.transactionID);
    });
}

//called after successful payment and after the user closed the payment dialog
//Do the UI changes on success at this point
-(void)paymentSuccessDialogClosed
{
    dispatch_async(dispatch_get_main_queue(), ^{

        NSLog(@"Payment dialog closed after success");
        //see paymentSuccessWithResponse: for the response transaction ID.
        
        if (onSuccess) onSuccess(payData);
        
        onSuccess = nil ;
        onError = nil;
        onUserClose = nil;
    });
}

- (void)paymentCanceled{
    
	NSLog(@"payment cancelled");
    //dialog closed without payment completed
    if (onUserClose) onUserClose(nil);
    
    onSuccess = nil ;
    onError = nil;
    onUserClose = nil;

}

@end
