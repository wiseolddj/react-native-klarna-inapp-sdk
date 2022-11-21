//
//  PaymentViewWrapper.m
//  react-native-klarna-payment-view
//
//  Created by Gabriel Banfalvi on 2019-07-24.
//

#import "PaymentViewWrapper.h"

#import <KlarnaMobileSDK/KlarnaMobileSDK-Swift.h>
#import <React/RCTLog.h>
#import <objc/runtime.h>

@interface PaymentViewWrapper () <KlarnaPaymentEventListener>

@property (nonatomic, strong) KlarnaPaymentViewDebug* actualPaymentView;


@end


@implementation UIView (MoveToWindow)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(didMoveToWindow);
        SEL swizzledSelector = @selector(xxx_didMoveToWindow);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        IMP originalImp = method_getImplementation(originalMethod);
        IMP swizzledImp = method_getImplementation(swizzledMethod);

        class_replaceMethod(class,
                swizzledSelector,
                originalImp,
                method_getTypeEncoding(originalMethod));
        class_replaceMethod(class,
                originalSelector,
                swizzledImp,
                method_getTypeEncoding(originalMethod));

    });
    
    
}

#pragma mark - Method Swizzling

- (void)xxx_didMoveToWindow {
    [self xxx_didMoveToWindow];
    NSString * class = NSStringFromClass([self class]);
    if ([class hasPrefix: @"KlarnaMobileSDK"]) {
        RCTLogWarn([NSString stringWithFormat: @"==================================\n    %@\n    did move to window\n    %@", self, self.window]);
        
        if (self.window == nil) {
            NSArray *syms = [NSThread  callStackSymbols];
            if ([syms count] > 1) {
                for (int i = 0; i < [syms count]; i++) {
                    RCTLogWarn(@"<%@ %p> %@ - caller: %@ ", [self class], self, NSStringFromSelector(_cmd), [syms objectAtIndex:i]);
                }
            } else {
                RCTLogWarn(@"<%@ %p> %@", [self class], self, NSStringFromSelector(_cmd));
            }
        }
    }
}

@end



@implementation NSURLSession (Analytics)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(dataTaskWithRequest:completionHandler:);
        SEL swizzledSelector = @selector(xxx_dataTaskWithRequest:completionHandler:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        IMP originalImp = method_getImplementation(originalMethod);
        IMP swizzledImp = method_getImplementation(swizzledMethod);

        class_replaceMethod(class,
                swizzledSelector,
                originalImp,
                method_getTypeEncoding(originalMethod));
        class_replaceMethod(class,
                originalSelector,
                swizzledImp,
                method_getTypeEncoding(originalMethod));

    });
    
    
}

#pragma mark - Method Swizzling

- (NSURLSessionDataTask *)xxx_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURL* url = request.URL;
    if (url != nil && ([url.absoluteString.lowercaseString rangeOfString: @"klarna"].location != NSNotFound)) {
        RCTLogWarn(@"==================================================");
        RCTLogWarn([NSString stringWithFormat: @"Request to %@", url]);
        
        NSData* body = request.HTTPBody;
        if (body != nil) {
            NSString* dataString = [[NSString alloc] initWithData: body encoding: NSUTF8StringEncoding];
            RCTLogWarn([NSString stringWithFormat: @"Data: %@", dataString]);
        }
    }
    return [self xxx_dataTaskWithRequest: request completionHandler: completionHandler];
}

@end

@implementation PaymentViewWrapper

#pragma mark - React Native Overrides

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        RCTLogWarn(@"View at %p initialized.", &self);
    }
    return self;
}

- (void) dealloc {
    RCTLogWarn(@"View at %p dealloced.", &self);
    
//    void *addr[2];
//    int nframes = backtrace(addr, sizeof(addr)/sizeof(*addr));
//    if (nframes > 1) {
//        char **syms = backtrace_symbols(addr, nframes);
//        RCTLogWarn(@"%s: caller: %s", __func__, syms[1]);
//        free(syms);
//    } else {
//        RCTLogWarn(@"%s: *** Failed to generate backtrace.", __func__);
//    }
//
//    NSArray *syms = [NSThread  callStackSymbols];
//    if ([syms count] > 1) {
//        for (int i = 0; i < [syms count]; i++) {
//            RCTLogWarn(@"<%@ %p> %@ - caller: %@ ", [self class], self, NSStringFromSelector(_cmd), [syms objectAtIndex:i]);
//        }
//    } else {
//        RCTLogWarn(@"<%@ %p> %@", [self class], self, NSStringFromSelector(_cmd));
//    }
}

- (void) setCategory:(NSString *)category {
    _category = category;
    [self evaluateProps];
}

- (void) evaluateProps {
    if (self.category != nil) {
        [self initializeActualPaymentView];
    }
}



- (void) didMoveToWindow_swizzle {
    RCTLogWarn(@"Did move %@ to window %@", self, self.window);

    [self didMoveToWindow_swizzle];
    
}

- (void) initializeActualPaymentView {
    
    [KlarnaMobileSDKCommon setLoggingLevel: KlarnaLoggingLevelVerbose];
    self.actualPaymentView = [[KlarnaPaymentViewDebug alloc] initWithCategory:self.category eventListener:self];
    self.actualPaymentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
//    [self.actualPaymentView setValue: ^void (KlarnaDebugEvent* event) {
//        RCTLogWarn([event debugDescription]);
//    }];

//
    [self addSubview:self.actualPaymentView];

//    Class osLogClass = objc_getClass("OS_os_log");
//
//    unsigned int methodCount = 0;
//       Method *methods = class_copyMethodList(osLogClass, &methodCount);
//
//       NSLog(@"Found %d methods on '%s'\n", methodCount, class_getName(osLogClass));
//
//       for (unsigned int i = 0; i < methodCount; i++) {
//           Method method = methods[i];
//
//           printf("\t'%s' has method named '%s' of encoding '%s'\n",
//                  class_getName(osLogClass),
//                  sel_getName(method_getName(method)),
//                  method_getTypeEncoding(method));
//
//           /**
//            *  Or do whatever you need here...
//            */
//       }
//
//       free(methods);
//    for(i=0;i<ic;i++) {
//        NSLog(@"Method no #%d: %s", i, sel_getName(method_getName(mlist[i])));
//    }
    
    [NSLayoutConstraint activateConstraints:[[NSArray alloc] initWithObjects:
        [self.actualPaymentView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.actualPaymentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.actualPaymentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.actualPaymentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor], nil
    ]];
    

}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.actualPaymentView.frame = self.bounds;
    [self.actualPaymentView layoutSubviews];
}

#pragma mark - Payment View Methods

- (void)initializePaymentViewWithClientToken:(NSString *)clientToken withReturnUrl:(NSString *)returnUrl{
    NSURL* url = [NSURL URLWithString:returnUrl];
    [self.actualPaymentView initializeWithClientToken:clientToken returnUrl:url];
}

- (void)loadPaymentViewWithSessionData:(NSString*)sessionData {
    [self.actualPaymentView loadWithJsonData:sessionData];
}

- (void)loadPaymentReview {
    [self.actualPaymentView loadPaymentReview];
}

- (void)authorizePaymentViewWithAutoFinalize:(BOOL)autoFinalize sessionData:(NSString*)sessionData {
    [self.actualPaymentView authorizeWithAutoFinalize:autoFinalize jsonData:sessionData];
}

- (void)reauthorizePaymentViewWithSessionData:(NSString*)sessionData {
    [self.actualPaymentView reauthorizeWithJsonData:sessionData];
}

- (void)finalizePaymentViewWithSessionData:(NSString*)sessionData {
    [self.actualPaymentView finaliseWithJsonData:sessionData];

}

#pragma mark - Klarna PaymentEventListener


- (void)klarnaInitializedWithPaymentView:(KlarnaPaymentView * _Nonnull)paymentView {
    if (!self.onInitialized) {
        RCTLog(@"Missing 'onInitialized' callback prop.");
        return;
    }
    
    self.onInitialized(@{});
}

- (void)klarnaLoadedWithPaymentView:(KlarnaPaymentView * _Nonnull)paymentView {
    if (!self.onLoaded) {
        RCTLog(@"Missing 'onLoaded' callback prop.");
        return;
    }
    
    self.onLoaded(@{});
}

- (void)klarnaLoadedPaymentReviewWithPaymentView:(KlarnaPaymentView * _Nonnull)paymentView {
    if (!self.onLoadedPaymentReview) {
        RCTLog(@"Missing 'onLoadedPaymentReview' callback prop.");
        return;
    }
    
    self.onLoadedPaymentReview(@{});
}

- (void)klarnaAuthorizedWithPaymentView:(KlarnaPaymentView * _Nonnull)paymentView approved:(BOOL)approved authToken:(NSString * _Nullable)authToken finalizeRequired:(BOOL)finalizeRequired {
    if (!self.onAuthorized) {
        RCTLog(@"Missing 'onAuthorized' callback prop.");
        return;
    }
    
    self.onAuthorized(@{
        @"approved": [NSNumber numberWithBool:approved],
        @"authToken": authToken ? authToken : NSNull.null,
        @"finalizeRequired": [NSNumber numberWithBool:finalizeRequired]
    });

}
- (void)klarnaReauthorizedWithPaymentView:(KlarnaPaymentView * _Nonnull)paymentView approved:(BOOL)approved authToken:(NSString * _Nullable)authToken {
    if (!self.onReauthorized) {
        RCTLog(@"Missing 'onReauthorized' callback prop.");
        return;
    }
    
    self.onReauthorized(@{
        @"approved": [NSNumber numberWithBool:approved],
        @"authToken": authToken ? authToken : NSNull.null,
    });
}

- (void)klarnaFinalizedWithPaymentView:(KlarnaPaymentView * _Nonnull)paymentView approved:(BOOL)approved authToken:(NSString * _Nullable)authToken {
    if (!self.onFinalized) {
        RCTLog(@"Missing 'onFinalized' callback prop.");
        return;
    }
    
    self.onFinalized(@{
        @"approved": [NSNumber numberWithBool:approved],
        @"authToken": authToken ? authToken : NSNull.null,
    });
}

- (void)klarnaFailedInPaymentView:(KlarnaPaymentView * _Nonnull)paymentView withError:(KlarnaPaymentError * _Nonnull)error {
       if (!self.onError) {
        RCTLog(@"Missing 'onError' callback prop.");
        return;
    }

    self.onError(@{
        @"error": @{
            @"action": error.action,
            @"isFatal": [NSNumber numberWithBool:error.isFatal],
            @"message": error.message,
            @"name": error.name
        }
    });
}

- (void)klarnaResizedWithPaymentView:(KlarnaPaymentView * _Nonnull)paymentView to:(CGFloat)newHeight {

    [self.uiManager setIntrinsicContentSize:CGSizeMake(UIViewNoIntrinsicMetric, newHeight) forView:self];
}

@end
