//
//  TPRecordModel.m
//  VideoIphone
//
//  Created by 吴凯凯 on 2019/6/24.
//  Copyright © 2019 com.baidu. All rights reserved.
//

#import "TPRecordModel.h"

@implementation TPRecordModel

- (instancetype)initWithCls:(Class)cls sel:(SEL)sel time:(uint64_t)costTime depth:(int)depth total:(int)total
{
    self = [super init];
    if (self) {
        self.callCount = 0;
        self.cls = cls;
        self.sel = sel;
        self.costTime = costTime;
        self.depth = depth;
        self.total = total;
        self.isUsed = NO;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    TPRecordModel *model = [[[self class]  allocWithZone:zone] init];
    model.cls = self.cls;
    model.sel = self.sel;
    model.costTime = self.costTime;
    model.depth = self.depth;
    model.total = self.total;
    model.isUsed = self.isUsed;
    model.callCount = self.callCount;
    return model;
}

- (BOOL)isEqualRecordModel:(TPRecordModel *)model
{
    if ([self.cls isEqual:model.cls] && self.sel==model.sel) {
        return YES;
    }
    return NO;
}

@end
