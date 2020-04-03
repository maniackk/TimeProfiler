//
//  TimeProfiler.h
//  KKMagicHook
//
//  Created by 吴凯凯 on 2020/4/2.
//  Copyright © 2020 吴凯凯. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName _Nonnull const TPTimeProfilerProcessedDataNotification;

@class TPModel;

@interface TimeProfiler : NSObject

@property (nonatomic, copy, readonly)NSArray *ignoreClassArr;
@property (nonatomic, strong, readonly)NSMutableArray<TPModel *> *modelArr;

+ (instancetype)shareInstance;

/**
 开始/停止统计，需成对使用
 可以用来测多个功能点的耗时问题
 */
- (void)TPStartTrace:(char *)featureName;
- (void)TPStopTrace;

- (void)TPSetMaxDepth:(int)depth;
- (void)TPSetCostMinTime:(uint64_t)time; //单位为us，1ms = 1000us
- (void)TPSetFilterClass:(NSArray *)classArr; //需要过滤的类，不调用此方法，默认为TimeProfilerVC、TPRecordHierarchyModel、 TPRecordCell、TPRecordModel等TimeProfiler本身类（不统计过滤的类）

@end

NS_ASSUME_NONNULL_END
