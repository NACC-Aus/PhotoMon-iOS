#import "PMAlertView.h"

@interface PMAlertView ()

@property (nonatomic, copy) NSString *alertTitle;
@property (nonatomic, copy) NSString *alertMessage;
@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, strong) NSMutableArray<NSString *> *otherButtonTitles;
@property (nonatomic, strong) UIAlertController *alertController;

@end

@implementation PMAlertView

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                     delegate:(id)delegate
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    self = [super init];
    if (self) {
        _alertTitle = [title copy];
        _alertMessage = [message copy];
        _delegate = delegate;
        _cancelButtonTitle = [cancelButtonTitle copy];
        _otherButtonTitles = [NSMutableArray array];

        if (otherButtonTitles) {
            [_otherButtonTitles addObject:otherButtonTitles];
            va_list arguments;
            va_start(arguments, otherButtonTitles);
            NSString *buttonTitle = nil;
            while ((buttonTitle = va_arg(arguments, NSString *))) {
                [_otherButtonTitles addObject:buttonTitle];
            }
            va_end(arguments);
        }
    }
    return self;
}

- (NSInteger)cancelButtonIndex
{
    return self.cancelButtonTitle ? 0 : -1;
}

- (NSInteger)firstOtherButtonIndex
{
    return self.cancelButtonTitle ? 1 : (self.otherButtonTitles.count > 0 ? 0 : -1);
}

- (void)show
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.alertController =
            [UIAlertController alertControllerWithTitle:self.alertTitle
                                                message:self.alertMessage
                                         preferredStyle:UIAlertControllerStyleAlert];

        if (self.alertViewStyle == UIAlertViewStylePlainTextInput ||
            self.alertViewStyle == UIAlertViewStyleSecureTextInput ||
            self.alertViewStyle == UIAlertViewStyleLoginAndPasswordInput) {
            [self.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.secureTextEntry = self.alertViewStyle == UIAlertViewStyleSecureTextInput;
            }];
        }
        if (self.alertViewStyle == UIAlertViewStyleLoginAndPasswordInput) {
            [self.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.secureTextEntry = YES;
            }];
        }

        NSInteger buttonIndex = 0;
        if (self.cancelButtonTitle) {
            [self addActionWithTitle:self.cancelButtonTitle
                               style:UIAlertActionStyleCancel
                         buttonIndex:buttonIndex++];
        }
        for (NSString *title in self.otherButtonTitles) {
            [self addActionWithTitle:title
                               style:UIAlertActionStyleDefault
                         buttonIndex:buttonIndex++];
        }

        UIViewController *presentingViewController = [self presentingViewController];
        [presentingViewController presentViewController:self.alertController animated:YES completion:nil];
    });
}

- (void)addActionWithTitle:(NSString *)title
                     style:(UIAlertActionStyle)style
               buttonIndex:(NSInteger)buttonIndex
{
    __weak typeof(self) weakSelf = self;
    UIAlertAction *action =
        [UIAlertAction actionWithTitle:title
                                 style:style
                               handler:^(__unused UIAlertAction *selectedAction) {
        [weakSelf notifyDelegateForButtonIndex:buttonIndex];
    }];
    [self.alertController addAction:action];
}

- (void)notifyDelegateForButtonIndex:(NSInteger)buttonIndex
{
    id delegate = self.delegate;
    SEL clickedSelector = @selector(alertView:clickedButtonAtIndex:);
    if ([delegate respondsToSelector:clickedSelector]) {
        IMP implementation = [delegate methodForSelector:clickedSelector];
        void (*function)(id, SEL, id, NSInteger) = (void *)implementation;
        function(delegate, clickedSelector, self, buttonIndex);
    }

    SEL dismissedSelector = @selector(alertView:didDismissWithButtonIndex:);
    if ([delegate respondsToSelector:dismissedSelector]) {
        IMP implementation = [delegate methodForSelector:dismissedSelector];
        void (*function)(id, SEL, id, NSInteger) = (void *)implementation;
        function(delegate, dismissedSelector, self, buttonIndex);
    }
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    [self.alertController dismissViewControllerAnimated:animated completion:^{
        [self notifyDelegateForButtonIndex:buttonIndex];
    }];
}

- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex
{
    if (textFieldIndex < 0 || textFieldIndex >= self.alertController.textFields.count) {
        return nil;
    }
    return self.alertController.textFields[textFieldIndex];
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex
{
    if (self.cancelButtonTitle) {
        if (buttonIndex == 0) {
            return self.cancelButtonTitle;
        }
        buttonIndex--;
    }
    if (buttonIndex < 0 || buttonIndex >= self.otherButtonTitles.count) {
        return nil;
    }
    return self.otherButtonTitles[buttonIndex];
}

- (UIViewController *)presentingViewController
{
    id applicationDelegate = [[UIApplication sharedApplication] delegate];
    UIWindow *window = [applicationDelegate valueForKey:@"window"];
    UIViewController *viewController = window.rootViewController;
    while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
    }
    return viewController;
}

@end
