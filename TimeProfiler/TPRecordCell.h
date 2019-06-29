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
@class TPRecordCell;

@protocol TPRecordCellDelegate <NSObject>

- (void)recordCell:(TPRecordCell *)cell clickExpandWithSection:(NSInteger)section;

@end

@interface TPRecordCell : UITableViewCell

@property (nonatomic, weak)id<TPRecordCellDelegate> delegate;

- (void)bindRecordModel:(TPRecordModel *)model isHiddenExpandBtn:(BOOL)isHidden isExpand:(BOOL)isExpand section:(NSInteger)section isCallCountType:(BOOL)isCallCountType;

@end

NS_ASSUME_NONNULL_END
