//
//  TimeProfiler.m
//  KKMagicHook
//
//  Created by 吴凯凯 on 2020/4/2.
//  Copyright © 2020 吴凯凯. All rights reserved.
//

#import "TimeProfiler.h"
#import "TPCallTrace.h"

@interface TimeProfiler()
{
    NSArray *_defaultIgnoreClass;
    NSArray *_ignoreClassArr;
}

@property (nonatomic, copy, readwrite)NSArray *ignoreClassArr;

@end

@implementation TimeProfiler

+ (instancetype)shareInstance
{
    static TimeProfiler *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TimeProfiler alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _defaultIgnoreClass = @[NSClassFromString(@"TimeProfilerVC"), NSClassFromString(@"TPRecordHierarchyModel"), NSClassFromString(@"TPRecordCell"), NSClassFromString(@"TPRecordModel")];
    }
    return self;
}

- (void)TPStartTrace
{
    startTrace();
}

- (void)TPStopTrace
{
    stopTrace();
}

- (void)TPSetMaxDepth:(int)depth
{
    setMaxDepth(depth);
}

- (void)TPSetCostMinTime:(uint64_t)time
{
    setCostMinTime(time);
}

- (void)TPSetFilterClass:(NSArray *)classArr
{
    self.ignoreClassArr = classArr;
}

#pragma mark - get&set method

- (NSArray *)ignoreClassArr
{
    if (!_ignoreClassArr) {
        _ignoreClassArr = _defaultIgnoreClass;
    }
    return _ignoreClassArr;
}

- (void)setIgnoreClassArr:(NSArray *)ignoreClassArr
{
    if (ignoreClassArr.count > 0) {
        NSMutableArray *arrM = [NSMutableArray arrayWithArray:_defaultIgnoreClass];
        [arrM addObjectsFromArray:ignoreClassArr];
        _ignoreClassArr = arrM.copy;
    }
}

@end
