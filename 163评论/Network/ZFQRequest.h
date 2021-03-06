//
//  ZFQRequest.h
//  163pinglun
//
//  Created by _ on 16/9/8.
//  Copyright © 2016年 zhaofuqiang. All rights reserved.
//

#import "ZFQBaseRequest.h"
#import "Post.h"
#import "RandomPost.h"
#import "Content.h"
#import "Tag.h"

#pragma mark 帖子
@interface ZFQPostRequest : ZFQBaseRequest

//辅助参数
@property (nonatomic,assign) NSInteger tagPageIndex;
@property (nonatomic,assign) NSInteger homePageIndex;
@property (nonatomic,assign) BOOL headRefreshing;
@property (nonatomic,copy) NSString *tagName;

//返回结果
@property (nonatomic,copy) NSArray<Post *> *postItems;

@end

#pragma mark 跟帖
@interface ZFQCommentRequest : ZFQBaseRequest

//请求参数
@property (nonatomic,copy) NSString *postID;

//返回结果
@property (nonatomic,copy) NSArray<NSArray *> *contentsItems;

@end

#pragma mark 标签
@interface PLTagRequest : ZFQBaseRequest

//返回结果
@property (nonatomic,copy) NSArray<Tag *> *tags;

@end

#pragma mark 随便看看
@interface PLRandomPostRequest : ZFQBaseRequest

//返回结果
@property (nonatomic,copy) NSArray<RandomPost *> *randomPosts;

@end
