//
//  PontoDispatcher
//  Game Guides
//
//  Created by Grzegorz Nowicki on 21.09.2012.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PontoBaseHandler.h"

@protocol PontoDispatcherDelegate <NSObject>
@required
- (id)deserializeJSONString:(NSString *)JSON;
- (NSString *)serializeObjectToJSON:(id)someObject;

@end


@interface PontoDispatcher : NSObject <UIWebViewDelegate>

@property (nonatomic, strong) NSString *handlerClassesPrefix;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, assign) id <PontoDispatcherDelegate>delegate;

- (id)initWithHandlerClassesPrefix:(NSString *)classesPrefix;
- (id)initWithHandlerClassesPrefix:(NSString *)classesPrefix andWebView:(UIWebView *)webView;

@end
