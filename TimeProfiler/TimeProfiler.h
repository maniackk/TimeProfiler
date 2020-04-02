//
//  TimeProfiler.h
//  KKMagicHook
//
//  Created by 吴凯凯 on 2020/4/2.
//  Copyright © 2020 吴凯凯. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TimeProfiler : NSObject

@property (nonatomic, copy, readonly)NSArray *ignoreClassArr;

+ (instancetype)shareInstance;
- (void)TPStartTrace;
- (void)TPStopTrace;
- (void)TPSetMaxDepth:(int)depth;
- (void)TPSetCostMinTime:(uint64_t)time; //单位为us，1ms = 1000us
- (void)TPSetFilterClass:(NSArray *)classArr; //需要过滤的类，不调用此方法，默认为TimeProfilerVC、TPRecordHierarchyModel、 TPRecordCell、TPRecordModel（不统计过滤的类）

@end

NS_ASSUME_NONNULL_END
