//
//  TimeProfiler.m
//  KKMagicHook
//
//  Created by 吴凯凯 on 2020/4/2.
//  Copyright © 2020 吴凯凯. All rights reserved.
//

#import "TimeProfiler.h"
#import "TPCallTrace.h"
#import "TPRecordModel.h"
#import "TPRecordHierarchyModel.h"
#import "TPModel.h"

#define IS_SHOW_DEBUG_INFO_IN_CONSOLE 0

NSNotificationName const TPTimeProfilerProcessedDataNotification = @"TPTimeProfilerProcessedDataNotification";

@interface TimeProfiler()
{
    NSArray *_defaultIgnoreClass;
    NSArray *_ignoreClassArr;
}

@property (nonatomic, copy, readwrite)NSArray *ignoreClassArr;
@property (nonatomic, strong, readwrite)NSMutableArray<TPModel *> *modelArr;

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
        _defaultIgnoreClass = @[NSClassFromString(@"TPModel"), NSClassFromString(@"TPMainVC"), NSClassFromString(@"TimeProfiler"), NSClassFromString(@"TimeProfilerVC"), NSClassFromString(@"TPRecordHierarchyModel"), NSClassFromString(@"TPRecordCell"), NSClassFromString(@"TPRecordModel")];
    }
    return self;
}

- (void)TPStartTrace:(char *)featureName
{
    startTrace(featureName);
}

- (void)TPStopTrace
{
    [self stopAndGetCallRecord];
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

- (NSUInteger)findStartDepthIndex:(NSUInteger)start arr:(NSArray *)arr
{
    NSUInteger index = start;
    if (arr.count > index) {
        TPRecordModel *model = arr[index];
        int minDepth = model.depth;
        int minTotal = model.total;
        for (NSUInteger i = index+1; i < arr.count; i++) {
            TPRecordModel *tmp = arr[i];
            if (tmp.depth < minDepth || (tmp.depth == minDepth && tmp.total < minTotal)) {
                minDepth = tmp.depth;
                minTotal = tmp.total;
                index = i;
            }
        }
    }
    return index;
}

- (NSArray *)recursive_getRecord:(NSMutableArray *)arr
{
    if ([arr isKindOfClass:NSArray.class] && arr.count > 0) {
        BOOL isValid = YES;
        NSMutableArray *recordArr = [NSMutableArray array];
        NSMutableArray *splitArr = [NSMutableArray array];
        NSUInteger index = [self findStartDepthIndex:0 arr:arr];
        if (index > 0) {
            [splitArr addObject:[NSMutableArray array]];
            for (int i = 0; i < index; i++) {
                [[splitArr lastObject] addObject:arr[i]];
            }
        }
        TPRecordModel *model = arr[index];
        [recordArr addObject:model];
        [arr removeObjectAtIndex:index];
        int startDepth = model.depth;
        int startTotal = model.total;
        for (NSUInteger i = index; i < arr.count; ) {
            model = arr[i];
            if (model.total == startTotal && model.depth-1==startDepth) {
                [recordArr addObject:model];
                [arr removeObjectAtIndex:i];
                startDepth++;
                isValid = YES;
            }
            else
            {
                if (isValid) {
                    isValid = NO;
                    [splitArr addObject:[NSMutableArray array]];
                }
                [[splitArr lastObject] addObject:model];
                i++;
            }
            
        }
        
        for (NSUInteger i = splitArr.count; i > 0; i--) {
            NSMutableArray *sArr = splitArr[i-1];
            [recordArr addObjectsFromArray:[self recursive_getRecord:sArr]];
        }
        return recordArr;
    }
    return @[];
}

- (void)setRecordDic:(NSMutableArray *)arr record:(TPCallRecord *)record
{
    if ([arr isKindOfClass:NSMutableArray.class] && record) {
        int total=1;
        for (NSUInteger i = 0; i < arr.count; i++)
        {
            TPRecordModel *model = arr[i];
            if (model.depth == record->depth) {
                total = model.total+1;
                break;
            }
        }
        
        TPRecordModel *model = [[TPRecordModel alloc] initWithCls:record->cls sel:record->sel time:record->costTime depth:record->depth total:total is_objc_msgSendSuper:record->is_objc_msgSendSuper];
        [arr insertObject:model atIndex:0];
    }
}


- (void)stopAndGetCallRecord
{
    stopTrace();
    TPMainThreadCallRecord *mainThreadCallRecord = getMainThreadCallRecord();
    if (mainThreadCallRecord==NULL) {
        NSLog(@"=====================================");
        NSLog(@"=====================================");
        NSLog(@"函数TPStartTrace跟TPStopTrace需要成对调用");
        NSLog(@"具体用法请看：https://github.com/maniackk/TimeProfiler");
        NSLog(@"=====================================");
        NSLog(@"=====================================");
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        #if IS_SHOW_DEBUG_INFO_IN_CONSOLE
        NSMutableString *textM = [[NSMutableString alloc] init];
        #endif
        NSMutableArray *allMethodRecord = [NSMutableArray array];
        int i = 0, j;
        while (i <= mainThreadCallRecord->index) {
            NSMutableArray *methodRecord = [NSMutableArray array];
            for (j = i; j <= mainThreadCallRecord->index;j++)
            {
                TPCallRecord *callRecord = &mainThreadCallRecord->record[j];
                #if IS_SHOW_DEBUG_INFO_IN_CONSOLE
                NSString *str = [self debug_getMethodCallStr:callRecord];
                [textM appendString:str];
                [textM appendString:@"\r"];
                #endif
                [self setRecordDic:methodRecord record:callRecord];
                if (callRecord->depth==0 || j==mainThreadCallRecord->index)
                {
                    NSArray *recordModelArr = [self recursive_getRecord:methodRecord];
                    recordModelArr = [self filterClass:recordModelArr];
                    if (recordModelArr.count > 0) {
                        TPRecordHierarchyModel *model = [[TPRecordHierarchyModel alloc] initWithRecordModelArr:recordModelArr];
                        [allMethodRecord addObject:model];
                    }
                    //退出循环
                    break;
                }
            }
            
            i = j+1;
        }
        
        TPModel *model = [[TPModel alloc] init];
        model.sequentialMethodRecord = [[NSArray alloc] initWithArray:allMethodRecord copyItems:YES];
        model.costTimeSortMethodRecord = [self sortCostTimeRecord:[[NSArray alloc] initWithArray:allMethodRecord copyItems:YES]];
        model.callCountSortMethodRecord = [self sortCallCountRecord:[[NSArray alloc] initWithArray:allMethodRecord copyItems:YES]];
        char *featureName = mainThreadCallRecord->featureName;
        if (featureName) {
            model.featureName = [NSString stringWithUTF8String:featureName];
        }
        if (!model.featureName) {
            model.featureName = @"调用TPStartTrace:函数，需要传name";
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.modelArr addObject:model];
            [[NSNotificationCenter defaultCenter] postNotificationName:TPTimeProfilerProcessedDataNotification object:nil];
        });
        if (mainThreadCallRecord) {
            free(mainThreadCallRecord->record);
            free(mainThreadCallRecord);
        }
        #if IS_SHOW_DEBUG_INFO_IN_CONSOLE
        [self debug_printMethodRecord:textM];
        #endif
    });
}

- (NSArray *)filterClass:(NSArray *)recordModelArr
{
    NSArray *ignoreClassArr = [TimeProfiler shareInstance].ignoreClassArr;
    NSMutableArray *result = [NSMutableArray array];
    if ([recordModelArr isKindOfClass:NSArray.class]) {
        int depth = 0;
        BOOL isIgnore = FALSE;
        for (TPRecordModel *model in recordModelArr) {
            if (isIgnore) {
                if (depth >= model.depth) {
                    isIgnore = [ignoreClassArr containsObject:model.cls];
                    depth = model.depth;
                }
            }
            else
            {
                isIgnore = [ignoreClassArr containsObject:model.cls];
                depth = model.depth;
            }
            if (!isIgnore) {
                [result addObject:model];
            }
        }
    }
    return result;
}

#if IS_SHOW_DEBUG_INFO_IN_CONSOLE

- (void)debug_printMethodRecord:(NSString *)text
{
    //记录的顺序是方法完成时间
    NSLog(@"=========printMethodRecord==Start================");
    NSLog(@"%@", text);
    NSLog(@"=========printMethodRecord==End================");
}

- (NSString *)debug_getMethodCallStr:(TPCallRecord *)callRecord
{
    NSMutableString *str = [[NSMutableString alloc] init];
    double ms = callRecord->costTime/1000.0;
    [str appendString:[NSString stringWithFormat:@"　%d　|　%lgms　|　", callRecord->depth, ms]];
    if (callRecord->depth>0) {
        [str appendString:[[NSString string] stringByPaddingToLength:callRecord->depth withString:@"　" startingAtIndex:0]];
    }
    if (class_isMetaClass(callRecord->cls))
    {
        [str appendString:@"+"];
    }
    else
    {
        [str appendString:@"-"];
    }
    if (callRecord->is_objc_msgSendSuper) {
        [str appendString:[NSString stringWithFormat:@"[(super)%@　　%@]", NSStringFromClass(callRecord->cls), NSStringFromSelector(callRecord->sel)]];
    }
    else
    {
        [str appendString:[NSString stringWithFormat:@"[%@　　%@]", NSStringFromClass(callRecord->cls), NSStringFromSelector(callRecord->sel)]];
    }
    return str.copy;
}

#endif

- (NSArray *)sortCostTimeRecord:(NSArray *)arr
{
    NSArray *sortArr = [arr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        TPRecordHierarchyModel *model1 = (TPRecordHierarchyModel *)obj1;
        TPRecordHierarchyModel *model2 = (TPRecordHierarchyModel *)obj2;
        if (model1.rootMethod.costTime > model2.rootMethod.costTime) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    for (TPRecordHierarchyModel *model in sortArr) {
        model.isExpand = NO;
    }
    return sortArr;
}

- (void)arrAddRecord:(TPRecordModel *)model arr:(NSMutableArray *)arr
{
    for (int i = 0; i < arr.count; i++) {
        TPRecordModel *temp = arr[i];
        if ([temp isEqualRecordModel:model]) {
            temp.callCount++;
            return;
        }
    }
    model.callCount = 1;
    [arr addObject:model];
}

- (NSArray *)sortCallCountRecord:(NSArray *)arr
{
    NSMutableArray *arrM = [NSMutableArray array];
    for (TPRecordHierarchyModel *model in arr) {
        [self arrAddRecord:model.rootMethod arr:arrM];
        if ([model.subMethods isKindOfClass:NSArray.class]) {
            for (TPRecordModel *recoreModel in model.subMethods) {
                [self arrAddRecord:recoreModel arr:arrM];
            }
        }
    }
    
    NSArray *sortArr = [arrM sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        TPRecordModel *model1 = (TPRecordModel *)obj1;
        TPRecordModel *model2 = (TPRecordModel *)obj2;
        if (model1.callCount > model2.callCount) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    return sortArr;
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

- (NSMutableArray<TPModel *> *)modelArr
{
    if (!_modelArr) {
        _modelArr = [NSMutableArray array];
    }
    return _modelArr;
}

@end
