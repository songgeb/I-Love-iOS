//
//  EditMenuInteractionDummy.h
//
//  Created by songgeb on 2023/9/27.
//  Copyright © 2023 songgeb. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// 该类用于配合EditMenuInteraction一同实现EditMenu效果
@interface EditMenuInteractionDummy : UIView

+ (instancetype)dummyWithActionCallback:(void (^)(SEL))callback;
- (void)updateActions:(NSSet<NSString *> *)actions;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
