//
//  TPRecordCell.m
//  VideoIphone
//
//  Created by 吴凯凯 on 2019/6/24.
//  Copyright © 2019 com.baidu. All rights reserved.
//

#import "TPRecordCell.h"
#import "TPRecordModel.h"

#define kDepthLabelWidth 30
#define kTimeLabelWidth 70
#define kMethodLabelWidth 500

@interface TPRecordCell()
{
    NSInteger _section;
}

@property (nonatomic, strong)UILabel *depthLabel;
@property (nonatomic, strong)UILabel *timeLabel;
@property (nonatomic, strong)UILabel *methodLabel;
@property (nonatomic, strong)UIButton *expandBtn;
@property (nonatomic, strong)UILabel *callCountLabel;

@end

@implementation TPRecordCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.depthLabel];
        [self.contentView addSubview:[self LineView:CGRectMake(kDepthLabelWidth+2, 0, 2, 18)]];
        [self.contentView addSubview:self.timeLabel];
        [self.contentView addSubview:[self LineView:CGRectMake(CGRectGetMaxX(self.timeLabel.frame)+2, 0, 2, 18)]];
        [self.contentView addSubview:self.expandBtn];
        [self.contentView addSubview:self.callCountLabel];
        [self.contentView addSubview:[self LineView:CGRectMake(CGRectGetMaxX(self.callCountLabel.frame)+2, 0, 2, 18)]];
        [self.contentView addSubview:self.methodLabel];
    }
    return self;
}

- (UIView *)LineView:(CGRect)rect
{
    UIView *line = [[UIView alloc] initWithFrame:rect];
    line.backgroundColor = [UIColor grayColor];
    return line;
}

- (void)bindRecordModel:(TPRecordModel *)model isHiddenExpandBtn:(BOOL)isHidden isExpand:(BOOL)isExpand section:(NSInteger)section isCallCountType:(BOOL)isCallCountType
{
    _section = section;
    self.expandBtn.hidden = isHidden;
    if (!self.expandBtn.hidden) {
        self.expandBtn.selected = isExpand;
    }
    self.depthLabel.text = [NSString stringWithFormat:@"%d", model.depth];
    self.timeLabel.text = [NSString stringWithFormat:@"%lgms", model.costTime/1000.0];
    self.callCountLabel.hidden = !isCallCountType;
    if (isCallCountType) {
        self.callCountLabel.text = [NSString stringWithFormat:@"%d", model.callCount];
    }
    
    NSMutableString *methodStr = [NSMutableString string];
    if (model.depth>0 && !isCallCountType) {
        [methodStr appendString:[[NSString string] stringByPaddingToLength:model.depth withString:@"　　" startingAtIndex:0]];
    }
    if (class_isMetaClass(model.cls)) {
        [methodStr appendString:@"+"];
    }
    else
    {
        [methodStr appendString:@"-"];
    }
    [methodStr appendString:[NSString stringWithFormat:@"[%@  %@]", NSStringFromClass(model.cls), NSStringFromSelector(model.sel)]];
    self.methodLabel.text = methodStr;
}

- (void)clickExpandBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(recordCell:clickExpandWithSection:)]) {
        [self.delegate recordCell:self clickExpandWithSection:_section];
    }
}

#pragma mark - get method

- (UILabel *)depthLabel
{
    if (!_depthLabel) {
        _depthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kDepthLabelWidth, 18)];
        _depthLabel.textAlignment = NSTextAlignmentCenter;
        _depthLabel.font = [UIFont systemFontOfSize:12];
    }
    return _depthLabel;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kDepthLabelWidth+6, 0, kTimeLabelWidth, 18)];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        _timeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _timeLabel;
}

- (UILabel *)methodLabel
{
    if (!_methodLabel) {
        _methodLabel = [[UILabel alloc] initWithFrame:CGRectMake(kDepthLabelWidth+kTimeLabelWidth+18+26, 0, kMethodLabelWidth, 18)];
        _methodLabel.font = [UIFont systemFontOfSize:12];
    }
    return _methodLabel;
}

- (UIButton *)expandBtn
{
    if (!_expandBtn) {
        _expandBtn = [[UIButton alloc] initWithFrame:CGRectMake(kDepthLabelWidth+kTimeLabelWidth+16, 0, 18, 18)];
        [_expandBtn setBackgroundImage:[UIImage imageNamed:@"TPNOExpandIcon"] forState:UIControlStateNormal];
        [_expandBtn setBackgroundImage:[UIImage imageNamed:@"TPExpandIcon"] forState:UIControlStateSelected];
        [_expandBtn addTarget:self action:@selector(clickExpandBtn:) forControlEvents:UIControlEventTouchUpInside];
        _expandBtn.hidden = YES;
    }
    return _expandBtn;
}

- (UILabel *)callCountLabel
{
    if (!_callCountLabel) {
        _callCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(kDepthLabelWidth+kTimeLabelWidth+12, 0, 26, 18)];
        _callCountLabel.textAlignment = NSTextAlignmentCenter;
        _callCountLabel.font = [UIFont systemFontOfSize:12];
        _callCountLabel.hidden = YES;
    }
    return _callCountLabel;
}

@end
