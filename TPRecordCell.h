//
//  TPRecordCell.h
//  VideoIphone
//
//  Created by 吴凯凯 on 2019/6/24.
//  Copyright © 2019 com.baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TPRecordModel;

@interface TPRecordCell : UITableViewCell

- (void)bindRecordModel:(TPRecordModel *)model;

@end

NS_ASSUME_NONNULL_END
