#import "RNBraintreeDropIn.h"

@implementation RNBraintreeDropIn

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(show,
                 showWithOptions:(NSDictionary*)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* clientToken = options[@"clientToken"];
    if (!clientToken) {
        reject(@"NO_CLIENT_TOKEN", @"You must provide a client token", nil);
        return;
    }

    BTDropInRequest *request = [[BTDropInRequest alloc] init];

    NSDictionary* threeDSecureOptions = options[@"threeDSecure"];
    if (threeDSecureOptions) {
        request.threeDSecureVerification = YES;
        request.amount = threeDSecureOptions[@"amount"];
    }

    BTDropInController *dropIn = [[BTDropInController alloc] initWithAuthorization:clientToken request:request handler:^(BTDropInController * _Nonnull controller, BTDropInResult * _Nullable result, NSError * _Nullable error) {
            [self.reactRoot dismissViewControllerAnimated:YES completion:nil];

            if (error != nil) {
                reject(error.description, error.description, error);
            } else if (result.cancelled) {
                reject(@"USER_CANCELLATION", @"The user cancelled", nil);
            } else {
                NSMutableDictionary* jsResult = [NSMutableDictionary new];
                [jsResult setObject:result.paymentMethod.nonce forKey:@"nonce"];
                [jsResult setObject:result.paymentMethod.type forKey:@"type"];
                [jsResult setObject:result.paymentDescription forKey:@"description"];
                [jsResult setObject:[NSNumber numberWithBool:result.paymentMethod.isDefault] forKey:@"isDefault"];
                resolve(jsResult);
            }
        }];
    [self.reactRoot presentViewController:dropIn animated:YES completion:nil];
}

- (UIViewController*)reactRoot {
    UIViewController *root  = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *maybeModal = root.presentedViewController;

    UIViewController *modalRoot = root;

    if (maybeModal != nil) {
        modalRoot = maybeModal;
    }

    return modalRoot;
}

@end
