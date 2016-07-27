//
//  KLSICalendarViewController.m
//  KLCalendar
//
//  Created by kai lee on 16/7/26.
//  Copyright © 2016年 kai lee. All rights reserved.
//

#import "KLSICalendarViewController.h"
#import "SignInview.h"
#import "ORSCalendarView.h"
#import "ORSSignInTool.h"

//屏幕宽高
#define kUISCREENWIDTH  [UIScreen mainScreen].bounds.size.width     //屏幕高度
#define kUISCREENHEIGHT [UIScreen mainScreen].bounds.size.height    //屏幕宽度

@interface KLSICalendarViewController ()

@end


@interface KLSICalendarViewController ()
@property (nonatomic, strong) SignInview *signInView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) ORSCalendarView *calendarView;
@property (nonatomic, strong) NSMutableArray *signedArray;
// 日历
@end

@implementation KLSICalendarViewController
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
        [_scrollView setContentSize:CGSizeMake(kUISCREENWIDTH, kUISCREENHEIGHT + 64 +50+20)];
        [_scrollView setContentInset:UIEdgeInsetsMake(0, 0, 1, 0)];
        _scrollView.showsVerticalScrollIndicator = NO;
        
        [self.view addSubview:_scrollView];
    }
    return _scrollView;
}
- (ORSCalendarView *)calendarView {
    if (!_calendarView) {
        _calendarView = [[ORSCalendarView alloc] init];
    }
    return _calendarView;
}
- (void)viewWillAppear:(BOOL)animated
{
    [self hideTabBar];
    
    
    //是否联网
    if (![self isConnectionAvailable]) {
        [self loadNetwork:self.view];
    }else{
        self.noWifyView.hidden = YES;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //标题
    [self loadTitleView:@"签到"];
    
    // 从xib加载视图
    NSArray *nibView = [[NSBundle mainBundle] loadNibNamed:@"SignInview" owner:nil options:nil];
    SignInview *signInView = [nibView firstObject];
    self.signInView = signInView;
    [self.scrollView addSubview:self.signInView];
    
    //返回
    [self.signInView loadUI];
    [self loadBackButton:self.signInView.backButton];
    
    // 日历
    [self loadCalendar];
    //网络请求数据
    [self requestData];
    WEAKSELF
    self.signInView.signInBlock = ^ {
        LHLog(@"提交签到数据");
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:KUSERID]) {
            @try {
                NSDictionary *dic1 = @{@"userId":[[NSUserDefaults standardUserDefaults] objectForKey:KUSERID]};
                NSDictionary *dic2 = @{@"token":[[NSUserDefaults standardUserDefaults] objectForKey:KTOKEN]};
                NSMutableArray *dicArr = [NSMutableArray arrayWithObjects:dic1,dic2,nil];
                NSDictionary *dic = [weakSelf exchangeArrToDic:dicArr];
                
                [weakSelf.networkRequest signInTodayWithParameter:dic completion:^(NSString *msg, BOOL is_error) {
                    if (is_error) {
                        LHLog(@"签到失败%@",msg);
                        
                        [SVProgressHUD showErrorWithStatus:msg];
                    } else {
                        LHLog(@"%@", msg);
                        [SVProgressHUD showSuccessWithStatus:@"签到成功"];
                        
                        //设置已经签到的天数日期
                        NSDate *currentDate = [NSDate date]; // 当前时间
                        NSTimeZone* GTMzone = [NSTimeZone timeZoneForSecondsFromGMT:0];
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setTimeZone:GTMzone];
                        [dateFormat setLocale:[NSLocale currentLocale]];
                        [dateFormat setDateFormat:@"yyyy-MM-d"];
                        NSString *currentDateStr = [dateFormat stringFromDate:currentDate];
                        int signedNum = [[currentDateStr substringFromIndex:8] intValue];
                        
                        [weakSelf.signedArray addObject:[NSNumber numberWithInt:signedNum]];
                        weakSelf.calendarView.signArray = weakSelf.signedArray;
                        weakSelf.calendarView.date = [NSDate date];
                    }
                }];
            } @catch (NSException *exception) {
                [SVProgressHUD showInfoWithStatus:@"签到失败"];
            } @finally {
                
            }
            
        }else{
            
            [weakSelf loginViewContrller];
        }
        
    };
    
    self.view.backgroundColor = KBACGROUDCOLOR;
}

- (void)loadCalendar {
    // 日历
    NSDate *currentDate = [NSDate date]; // 当前时间
    NSTimeZone* GTMzone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:GTMzone];
    [dateFormat setLocale:[NSLocale currentLocale]];
    [dateFormat setDateFormat:@"yyyy-MM-d"];
    //    NSString *currentDateStr = [dateFormat stringFromDate:currentDate];
    NSInteger firstWeekday = [ORSSignInTool firstWeekdayInThisMonth:currentDate];
    if (firstWeekday > 4) {
        self.calendarView.frame = CGRectMake(0, CGRectGetMaxY(self.signInView.frame), kUISCREENWIDTH, 414);
        [self.scrollView addSubview:self.calendarView];
    } else {
        self.calendarView.frame = CGRectMake(0, CGRectGetMaxY(self.signInView.frame), kUISCREENWIDTH, 356);
        [self.scrollView addSubview:self.calendarView];
    }
    
    
}
//网络请求数据
- (void)requestData
{
    [self setLoadingStyle];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:KUSERID]) {
        @try {
            NSDictionary *dic1 = @{@"userId":[[NSUserDefaults standardUserDefaults] objectForKey:KUSERID]};
            NSDictionary *dic2 = @{@"token":[[NSUserDefaults standardUserDefaults] objectForKey:KTOKEN]};
            NSMutableArray *dicArr = [NSMutableArray arrayWithObjects:dic1,dic2,nil];
            NSDictionary *dic = [self exchangeArrToDic:dicArr];
            WEAKSELF
            [self.networkRequest signInWithParameter:dic completion:^(ORSSignInModel *signInModel, BOOL is_error) {
                if (!is_error) {
                    [weakSelf dismissLoading];
                    // 上部
                    _signInView.signModel = signInModel;
                    weakSelf.signedArray = [NSMutableArray arrayWithCapacity:31];
                    // 日历
                    for (int i = 0; i<signInModel.monthSignArray.count; i++) {
                        ORSMonthSign *monthSignModel = signInModel.monthSignArray[i];
                        
                        NSString *numberStr = [monthSignModel.day substringFromIndex:8];
                        int signedNum = [numberStr intValue];
                        
                        if ([monthSignModel.sign isEqualToString:@"1"]) {
                            [weakSelf.signedArray addObject:[NSNumber numberWithInt:signedNum]];
                        }
                    }
                    //设置已经签到的天数日期
                    weakSelf.calendarView.signArray = weakSelf.signedArray;
                    weakSelf.calendarView.date = [NSDate date];
                    
                } else {
                    LHLog(@"获取签到数据失败");
                    weakSelf.calendarView.date = [NSDate date];
                    [SVProgressHUD showErrorWithStatus:@"签到数据加载失败"];
                }
            }];
        } @catch (NSException *exception) {
            [SVProgressHUD showInfoWithStatus:@"用户登录失效请重新登录"];
        } @finally {
            
        }
    }else{
        
        [self loginViewContrller];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
