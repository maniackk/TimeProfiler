//
//  TPRecordHierarchyModel.h
//  VideoIphone
//
//  Created by 吴凯凯 on 2019/6/29.
//  Copyright © 2019 com.baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TPRecordHierarchyModel : NSObject <NSCopying>

@property (nonatomic, strong)TPRecordModel *rootMethod;
@property (nonatomic, copy)NSArray *subMethods;
@property (nonatomic, assign)BOOL isExpand;   //是否展开所有的子函数

- (instancetype)initWithRecordModelArr:(NSArray *)recordModelArr;
- (TPRecordModel *)getRecordModel:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
