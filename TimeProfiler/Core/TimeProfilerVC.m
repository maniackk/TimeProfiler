//
//  TimeProfilerVC.m
//  VideoIphone
//
//  Created by 吴凯凯 on 2019/6/13.
//  Copyright © 2019 com.baidu. All rights reserved.
//

#import "TimeProfilerVC.h"
#import "TPCallTrace.h"
#import "TPRecordCell.h"
#import "TPRecordModel.h"
#import "TPRecordHierarchyModel.h"
#import "TimeProfiler.h"
#import "TPModel.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, TPTableType) {
    tableTypeSequential,
    tableTypecostTime,
    tableTypeCallCount,
};

static CGFloat TPScrollWidth = 600;
static CGFloat TPHeaderHight = 140;

#define IS_SHOW_DEBUG_INFO_IN_CONSOLE 0

@interface TimeProfilerVC () <UITableViewDataSource, TPRecordCellDelegate>

@property (nonatomic, strong)UIButton *RecordBtn;
@property (nonatomic, strong)UIButton *costTimeSortBtn;
@property (nonatomic, strong)UIButton *callCountSortBtn;
@property (nonatomic, strong)UIButton *popVCBtn;
@property (nonatomic, strong)UILabel *titleLabel;
@property (nonatomic, strong)UITableView *tpTableView;
@property (nonatomic, strong)UILabel *tableHeaderViewLabel;
@property (nonatomic, strong)UIScrollView *tpScrollView;
@property (nonatomic, copy)NSArray *sequentialMethodRecord;
@property (nonatomic, copy)NSArray *costTimeSortMethodRecord;
@property (nonatomic, copy)NSArray *callCountSortMethodRecord;
@property (nonatomic, assign)TPTableType tpTableType;

@end

@implementation TimeProfilerVC

- (instancetype)initWithModel:(TPModel *)model
{
    self = [super init];
    if (self) {
        self.sequentialMethodRecord = model.sequentialMethodRecord;
        self.costTimeSortMethodRecord = model.costTimeSortMethodRecord;
        self.callCountSortMethodRecord = model.callCountSortMethodRecord;
        self.titleLabel.text = model.featureName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.RecordBtn];
    [self.view addSubview:self.costTimeSortBtn];
    [self.view addSubview:self.callCountSortBtn];
    [self.view addSubview:self.popVCBtn];
    [self.view addSubview:self.tpScrollView];
    [self.tpScrollView addSubview:self.tableHeaderViewLabel];
    [self.tpScrollView addSubview:self.tpTableView];
    // Do any additional setup after loading the view.
    [self clickRecordBtn];
}

- (void)clickPopVCBtn:(UIButton *)btn
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TPRecordCellDelegate

- (void)recordCell:(TPRecordCell *)cell clickExpandWithSection:(NSInteger)section
{
    NSIndexSet *indexSet;
    TPRecordHierarchyModel *model;
    switch (self.tpTableType) {
        case tableTypeSequential:
            model = self.sequentialMethodRecord[section];
            break;
        case tableTypecostTime:
            model = self.costTimeSortMethodRecord[section];
            break;
            
        default:
            break;
    }
    model.isExpand = !model.isExpand;
    indexSet=[[NSIndexSet alloc] initWithIndex:section];
    [self.tpTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.tpTableType == tableTypeSequential) {
        return self.sequentialMethodRecord.count;
    }
    else if (self.tpTableType == tableTypecostTime)
    {
        return self.costTimeSortMethodRecord.count;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.tpTableType == tableTypeSequential) {
        TPRecordHierarchyModel *model = self.sequentialMethodRecord[section];
        if (model.isExpand && [model.subMethods isKindOfClass:NSArray.class]) {
            return model.subMethods.count+1;
        }
    }
    else if (self.tpTableType == tableTypecostTime)
    {
        TPRecordHierarchyModel *model = self.costTimeSortMethodRecord[section];
        if (model.isExpand && [model.subMethods isKindOfClass:NSArray.class]) {
            return model.subMethods.count+1;
        }
    }
    else
    {
        return self.callCountSortMethodRecord.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *TPRecordCell_reuseIdentifier = @"TPRecordCell_reuseIdentifier";
    TPRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:TPRecordCell_reuseIdentifier];
    if (!cell) {
        cell = [[TPRecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TPRecordCell_reuseIdentifier];
    }
    TPRecordHierarchyModel *model;
    TPRecordModel *recordModel;
    BOOL isShowExpandBtn;
    switch (self.tpTableType) {
        case tableTypeSequential:
            model = self.sequentialMethodRecord[indexPath.section];
            recordModel = [model getRecordModel:indexPath.row];
            isShowExpandBtn = indexPath.row == 0 && [model.subMethods isKindOfClass:NSArray.class] && model.subMethods.count > 0;
            cell.delegate = self;
            [cell bindRecordModel:recordModel isHiddenExpandBtn:!isShowExpandBtn isExpand:model.isExpand section:indexPath.section isCallCountType:NO];
            break;
        case tableTypecostTime:
            model = self.costTimeSortMethodRecord[indexPath.section];
            recordModel = [model getRecordModel:indexPath.row];
            isShowExpandBtn = indexPath.row == 0 && [model.subMethods isKindOfClass:NSArray.class] && model.subMethods.count > 0;
            cell.delegate = self;
            [cell bindRecordModel:recordModel isHiddenExpandBtn:!isShowExpandBtn isExpand:model.isExpand section:indexPath.section isCallCountType:NO];
            break;
        case tableTypeCallCount:
            recordModel = self.callCountSortMethodRecord[indexPath.row];
            [cell bindRecordModel:recordModel isHiddenExpandBtn:YES isExpand:YES section:indexPath.section isCallCountType:YES];
            break;
            
        default:
            break;
    }
    return cell;
}

#pragma mark - Btn click method

- (void)clickRecordBtn
{
    self.costTimeSortBtn.selected = NO;
    self.callCountSortBtn.selected = NO;
    if (!self.RecordBtn.selected) {
        self.RecordBtn.selected = YES;
        self.tpTableType = tableTypeSequential;
        [self.tpTableView reloadData];
    }
}

- (void)clickCostTimeSortBtn
{
    self.RecordBtn.selected = NO;
    self.callCountSortBtn.selected = NO;
    if (!self.costTimeSortBtn.selected) {
        self.costTimeSortBtn.selected = YES;
        self.tpTableType = tableTypecostTime;
        [self.tpTableView reloadData];
    }
}

- (void)clickCallCountSortBtn
{
    self.costTimeSortBtn.selected = NO;
    self.RecordBtn.selected = NO;
    if (!self.callCountSortBtn.selected) {
        self.callCountSortBtn.selected = YES;
        self.tpTableType = tableTypeCallCount;
        [self.tpTableView reloadData];
    }
}


#pragma mark - get&set method

- (UIScrollView *)tpScrollView
{
    if (!_tpScrollView) {
        _tpScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, TPHeaderHight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-TPHeaderHight)];
        _tpScrollView.showsHorizontalScrollIndicator = YES;
        _tpScrollView.alwaysBounceHorizontal = YES;
        _tpScrollView.contentSize = CGSizeMake(TPScrollWidth, 0);
    }
    return _tpScrollView;
}

- (UITableView *)tpTableView
{
    if (!_tpTableView) {
        _tpTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 30, TPScrollWidth, [UIScreen mainScreen].bounds.size.height-TPHeaderHight-30) style:UITableViewStylePlain];
        _tpTableView.bounces = NO;
        _tpTableView.dataSource = self;
        _tpTableView.rowHeight = 18;
        _tpTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tpTableView;
}

- (UIButton *)getTPBtnWithFrame:(CGRect)rect title:(NSString *)title sel:(SEL)sel
{
    UIButton *btn = [[UIButton alloc] initWithFrame:rect];
    btn.layer.cornerRadius = 2;
    btn.layer.borderWidth = 1;
    btn.layer.borderColor = [UIColor blackColor].CGColor;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setBackgroundImage:[self imageWithColor:[UIColor colorWithRed:127/255.0 green:179/255.0 blue:219/255.0 alpha:1]] forState:UIControlStateSelected];
    btn.titleLabel.font = [UIFont systemFontOfSize:10];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UIImage *)imageWithColor:(UIColor *)color{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

- (UIButton *)RecordBtn
{
    if (!_RecordBtn) {
        _RecordBtn = [self getTPBtnWithFrame:CGRectMake(5, 105, 60, 30) title:@"调用时间" sel:@selector(clickRecordBtn)];
    }
    return _RecordBtn;
}

- (UIButton *)costTimeSortBtn
{
    if (!_costTimeSortBtn) {
        _costTimeSortBtn = [self getTPBtnWithFrame:CGRectMake(70, 105, 60, 30) title:@"最耗时" sel:@selector(clickCostTimeSortBtn)];
    }
    return _costTimeSortBtn;
}

- (UIButton *)callCountSortBtn
{
    if (!_callCountSortBtn) {
        _callCountSortBtn = [self getTPBtnWithFrame:CGRectMake(135, 105, 60, 30) title:@"调用次数" sel:@selector(clickCallCountSortBtn)];
    }
    return _callCountSortBtn;
}

- (UIButton *)popVCBtn
{
    if (!_popVCBtn) {
        _popVCBtn = [self getTPBtnWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-50, 105, 40, 30) title:@"返回" sel:@selector(clickPopVCBtn:)];
    }
    return _popVCBtn;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, [UIScreen mainScreen].bounds.size.width, 50)];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:25];
    }
    return _titleLabel;
}

- (UILabel *)tableHeaderViewLabel
{
    if (!_tableHeaderViewLabel) {
        _tableHeaderViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, TPScrollWidth, 30)];
        _tableHeaderViewLabel.font = [UIFont systemFontOfSize:15];
        _tableHeaderViewLabel.backgroundColor = [UIColor colorWithRed:219.0/255 green:219.0/255 blue:219.0/255 alpha:1];
    }
    return _tableHeaderViewLabel;
}

- (void)setTpTableType:(TPTableType)tpTableType
{
    if (_tpTableType!=tpTableType) {
        if (tpTableType==tableTypeCallCount) {
            self.tableHeaderViewLabel.text = @"深度       耗时      次数            方法名";
        }
        else
        {
            self.tableHeaderViewLabel.text = @"深度       耗时                  方法名";
        }
        _tpTableType = tpTableType;
    }
}

@end
