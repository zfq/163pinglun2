//
//  LookAroundViewController.m
//  163评论
//
//  Created by zhaofuqiang on 14-8-31.
//  Copyright (c) 2014年 zhaofuqiang. All rights reserved.
//

#import "RandomPostViewController.h"
#import "RandomPostView.h"
#import "ItemStore.h"
#import "RandomPosts.h"
#import "RandomPost.h"
#import "CommViewController.h"

static NSString *randomCellIdentifier = @"randomCell";

@interface RandomPostViewController ()
{
    UIView *maskView;
    UITableView *postTableView;
    
    UIPanGestureRecognizer *panGesture;
    CGFloat marginLeft;
    CGFloat beginTapX;
    CGFloat originAlpha;
    
    CGPoint beginTapPoint;
    CGPoint currTapPoint;
    
    NSRegularExpression *reg;
}
@end

@implementation RandomPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{ 
    RandomPostView *view = [[RandomPostView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //添加maskView
    CGFloat navHeight = 64;
    originAlpha = 0.7;
    maskView = [[UIView alloc] initWithFrame:CGRectMake(0, navHeight, SCREEN_WIDTH, SCREEN_HEITHT-navHeight)];
    maskView.backgroundColor = [UIColor blackColor]; //blackColor
    maskView.alpha = 0;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [maskView addGestureRecognizer:tapGesture];
    [self.view addSubview:maskView];
    
    //添加tableView
    marginLeft = 55;
    
    postTableView = [[UITableView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH, navHeight, SCREEN_WIDTH-marginLeft, SCREEN_HEITHT-navHeight) style:UITableViewStylePlain];
    postTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    postTableView.dataSource = self;
    postTableView.delegate = self;
    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    panGesture.delegate = self;
    [postTableView addGestureRecognizer:panGesture];
    [self.view addSubview:postTableView];
    [postTableView addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionNew context:nil];
    
    //添加nav阴影
    UIImage *navImg = [UIImage imageNamed:@"navigationbar_background"];
    UIImageView *navImgView = [[UIImageView alloc] initWithImage:navImg];
    navImgView.frame = CGRectMake(0, 0, SCREEN_WIDTH, navImg.size.height);
    [self.view addSubview:navImgView];
    
    //设置maskView透明度渐变及tableView的滑入
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect rect = postTableView.frame;
        rect.origin.x = marginLeft;
        postTableView.frame = rect;
        maskView.alpha = originAlpha;
    } completion:nil];
    
    //加载数据
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[ItemStore sharedItemStore] fetchRandomPostsWithCompletion:^(RandomPosts *randomPosts, NSError *error) {
        _posts = randomPosts.randomPosts;
        [postTableView reloadData];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
   
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [postTableView deselectRowAtIndexPath:[postTableView indexPathForSelectedRow]  animated:YES];
}

- (void)showRandomPostView
{
    [self.parentViewController.view addSubview:self.view];
}

- (void)dismissRandomPostView
{
    [self removeFromParentViewController];
    [self.view removeFromSuperview];
    [postTableView removeGestureRecognizer:panGesture];
    self.posts = nil;
    self.view = nil;
    reg = nil;
}


#pragma mark - tableView datasource delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_posts == nil)
        return 0;
    else
        return _posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"randomCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"randomCell"];
        cell.textLabel.font = [UIFont systemFontOfSize:14.0];
        
        //添加分割线
        CGFloat height = cell.contentView.frame.size.height;
        CGFloat width = cell.contentView.frame.size.width;
        UILabel *separatorLine = [[UILabel alloc] initWithFrame:CGRectMake(15, height-1, width, 1)];
        separatorLine.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [cell.contentView addSubview:separatorLine];
    }
    RandomPost *post = [_posts objectAtIndex:indexPath.row];
    cell.textLabel.text = post.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RandomPost *post = [_posts objectAtIndex:indexPath.row];
    CommViewController *cVC = [[CommViewController alloc] init];
    NSString *postID = [self postIDFromURL:post.postURL];
    cVC.postID = [NSNumber numberWithInteger:[postID integerValue]];
    [self.parentViewController.navigationController pushViewController:cVC animated:YES];
}

- (NSString *)postIDFromURL:(NSString *)postURL
{
    if (reg == nil) {
        NSString *regularStr = @"(\\d+?)$";
        NSError *error = nil;
        reg = [NSRegularExpression regularExpressionWithPattern:regularStr options:NSRegularExpressionCaseInsensitive error:&error];
        if (error != nil) {
            DNSLog(@"正则表达式出错:%@",NSStringFromSelector(_cmd));
            return nil;
        }
    }
    
    NSArray *results = [reg matchesInString:postURL options:NSMatchingReportCompletion range:NSMakeRange(0, postURL.length)];
    NSTextCheckingResult *checkResult = [results firstObject];
    
    return [postURL substringWithRange:[checkResult range]];
}

#pragma mark - tap gesture
- (void)tapGestureAction:(UITapGestureRecognizer *)gesture
{
    [UIView animateWithDuration:0.3 animations:^{
        [self moveView:postTableView toX:SCREEN_WIDTH];
        maskView.alpha = 0;
    } completion:^(BOOL finished) {
        [gesture.view removeGestureRecognizer:gesture];
        [self dismissRandomPostView];
        [[ItemStore sharedItemStore] cancelCurrentRequtest];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];

    gesture = nil;
}

#pragma mark - pan gesture
- (void)panGestureAction:(UIPanGestureRecognizer *)gesture
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    currTapPoint = [gesture locationInView:keyWindow];
    CGFloat x = currTapPoint.x;
    UIView *gestureView = gesture.view;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        beginTapX = x;
        beginTapPoint = currTapPoint;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        postTableView.userInteractionEnabled = NO;
        currTapPoint = [gesture locationInView:keyWindow];
        CGFloat temp = (x-beginTapX+marginLeft);
        [self moveView:gestureView toX:temp];
        if (temp <marginLeft) {
            maskView.alpha = originAlpha;
        } else {
            maskView.alpha = originAlpha - originAlpha*(x-beginTapX)/temp;
        }
        
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        
        if (x - beginTapX > 100) {  //移除marskView
            
            [UIView animateWithDuration:0.3 animations:^{
                [self moveView:gestureView toX:SCREEN_WIDTH];
                maskView.alpha = 0;
            } completion:^(BOOL finished) {
                [self dismissRandomPostView];
                //取消当前请求
                [[ItemStore sharedItemStore] cancelCurrentRequtest];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }];
            //移除pan手势
            [gesture.view removeGestureRecognizer:gesture];
            gesture = nil;
            
        } else {
            
            [UIView animateWithDuration:0.3 animations:^{
                [self moveView:gestureView toX:marginLeft];
                maskView.alpha = originAlpha;
            } completion:^(BOOL finished) {
                if (finished) {
                    postTableView.userInteractionEnabled = YES;
                }
            }];
            
        }
        
    }
}

- (void)moveView:(UIView *)view toX:(CGFloat)x
{
    CGFloat width = SCREEN_WIDTH;
    x = (x > width ? width : x);
    x = (x < marginLeft ? marginLeft : x);

    CGRect originFrame = view.frame;
    originFrame.origin.x = x;
    view.frame = originFrame;
}

#pragma mark - UIGestureRecognizer delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    switch (postTableView.panGestureRecognizer.state) {
        case UIGestureRecognizerStateChanged:{
            panGesture.enabled = NO;
        }break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:{
            panGesture.enabled = YES;
        }break;
        default:
            break;
    }
    
}

- (void)dealloc
{
    [postTableView removeGestureRecognizer:panGesture];
    [postTableView removeObserver:self forKeyPath:@"panGestureRecognizer.state" context:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if (self.parentViewController == nil) {
        [postTableView removeGestureRecognizer:panGesture];
        [self.view removeFromSuperview];
        self.view = nil;
    }
    reg = nil;
}
@end
