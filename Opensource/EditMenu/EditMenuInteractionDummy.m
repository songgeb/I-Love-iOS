//
//  EditMenuInteractionDummy.m
//
//  Created by songgeb on 2023/9/27.
//  Copyright © 2023 songgeb. All rights reserved.
//

#import "EditMenuInteractionDummy.h"

@interface EditMenuInteractionDummy ()
@property(nonatomic, copy) NSSet<NSString *> *actions;
@property(nonatomic, strong) void (^callback)(SEL);
@end

@implementation EditMenuInteractionDummy

+ (instancetype)dummyWithActionCallback:(void (^)(SEL))callback {
    NSParameterAssert(callback);
    return [[EditMenuInteractionDummy alloc] initWithCallback:callback];
}

- (instancetype)initWithCallback:(void (^)(SEL))callback {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _actions = [NSSet set];
        _callback = callback;
    }
    return self;
}

- (void)updateActions:(NSSet<NSString *> *)actions {
    if (!actions) return;
    self.actions = actions;
}

- (BOOL)isSelectorSupported:(SEL)selector {
    BOOL supported = NO;
    for (NSString *actionStr in self.actions) {
        SEL supportedAction = NSSelectorFromString(actionStr);
        if (supportedAction == selector) {
            supported = YES;
            break;
        }
    }
    return supported;
}

+ (void)fake {
}

#pragma mark override
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [self isSelectorSupported:action];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([self isSelectorSupported:anInvocation.selector]) {
        self.callback(anInvocation.selector);
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [EditMenuInteractionDummy methodSignatureForSelector:@selector(fake)];
}

@end
