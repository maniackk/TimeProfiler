//
//  TPModel.h
//  KKMagicHook
//
//  Created by 吴凯凯 on 2020/4/2.
//  Copyright © 2020 吴凯凯. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TPModel : NSObject

@property (nonatomic, copy)NSString *featureName;
@property (nonatomic, copy)NSArray *sequentialMethodRecord;
@property (nonatomic, copy)NSArray *costTimeSortMethodRecord;
@property (nonatomic, copy)NSArray *callCountSortMethodRecord;

@end

NS_ASSUME_NONNULL_END
