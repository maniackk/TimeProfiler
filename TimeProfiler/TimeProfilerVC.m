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
#import <objc/runtime.h>

static CGFloat TPScrollWidth = 600;
static CGFloat TPHeaderHight = 60;

@interface TimeProfilerVC () <UITableViewDataSource, UITableViewDelegate>

//@property (nonatomic, strong)UIButton *RecordBtn;
@property (nonatomic, strong)UIButton *popVCBtn;
@property (nonatomic, strong)UITableView *tpTableView;
@property (nonatomic, strong)UIScrollView *tpScrollView;
@property (nonatomic, copy)NSArray *sequentialMethodRecord;

@end

@implementation TimeProfilerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _sequentialMethodRecord = [NSArray array];
    self.view.backgroundColor = [UIColor whiteColor];
//    [self.view addSubview:self.RecordBtn];
    [self.view addSubview:self.popVCBtn];
    [self.view addSubview:self.tpScrollView];
    [self.tpScrollView addSubview:self.tpTableView];
    // Do any additional setup after loading the view.
    [self stopAndGetCallRecord];
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
        
        TPRecordModel *model = [[TPRecordModel alloc] initWithCls:record->cls sel:record->sel time:record->costTime depth:record->depth total:total];
        [arr insertObject:model atIndex:0];
    }
}

- (void)stopAndGetCallRecord
{
    stopTrace();
    TPMainThreadCallRecord *mainThreadCallRecord = getMainThreadCallRecord();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableString *textM = [[NSMutableString alloc] init];
        NSMutableArray *allMethodRecord = [NSMutableArray array];
        int i = 0, j;
        while (i <= mainThreadCallRecord->index) {
            NSMutableArray *methodRecord = [NSMutableArray array];
            for (j = i; j <= mainThreadCallRecord->index;j++)
            {
                TPCallRecord *callRecord = &mainThreadCallRecord->record[j];
                NSString *str = [self debug_getMethodCallStr:callRecord];
                [textM appendString:str];
                [textM appendString:@"\r"];
                [self setRecordDic:methodRecord record:callRecord];
                if (callRecord->depth==0)
                {
                    [allMethodRecord addObjectsFromArray:[self recursive_getRecord:methodRecord]];
                    //退出循环
                    break;
                }
            }
            
            i = j+1;
        }
        [self debug_printMethodRecord:textM];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sequentialMethodRecord = allMethodRecord;
            [self.tpTableView reloadData];
        });
    });
}

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
    [str appendString:[NSString stringWithFormat:@"[%@　　%@]", NSStringFromClass(callRecord->cls), NSStringFromSelector(callRecord->sel)]];
    return str.copy;
}

- (void)clickPopVCBtn:(UIButton *)btn
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sequentialMethodRecord.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *TPRecordCell_reuseIdentifier = @"TPRecordCell_reuseIdentifier";
    TPRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:TPRecordCell_reuseIdentifier];
    if (!cell) {
        cell = [[TPRecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TPRecordCell_reuseIdentifier];
    }
    TPRecordModel *model = self.sequentialMethodRecord[indexPath.row];
    [cell bindRecordModel:model];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 18;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [UIView new];
    headerView.backgroundColor = [UIColor colorWithRed:219.0/255 green:219.0/255 blue:219.0/255 alpha:1];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 30)];
    [headerView addSubview:label];
    label.text = @"深度       耗时                  方法名";
    label.font = [UIFont systemFontOfSize:15];
    return headerView;
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
        _tpTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, TPScrollWidth, [UIScreen mainScreen].bounds.size.height-TPHeaderHight) style:UITableViewStylePlain];
        _tpTableView.bounces = NO;
        _tpTableView.delegate = self;
        _tpTableView.dataSource = self;
        _tpTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tpTableView;
}

//- (UIButton *)RecordBtn
//{
//    if (!_RecordBtn) {
//        _RecordBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 120, 30)];
//        _RecordBtn.layer.cornerRadius = 2;
//        _RecordBtn.layer.borderWidth = 1;
//        _RecordBtn.layer.borderColor = [UIColor blackColor].CGColor;
//        [_RecordBtn setTitle:@"调用时间排序" forState:UIControlStateNormal];
//        [_RecordBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [_RecordBtn addTarget:self action:@selector(clickRecordBtn:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _RecordBtn;
//}

- (UIButton *)popVCBtn
{
    if (!_popVCBtn) {
        _popVCBtn = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-50, 20, 40, 30)];
        [_popVCBtn setTitle:@"关闭" forState:UIControlStateNormal];
        [_popVCBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_popVCBtn addTarget:self action:@selector(clickPopVCBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _popVCBtn;
}

@end
