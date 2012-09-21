//
//  PontoDispatcher
//  Game Guides
//
//  Created by Grzegorz Nowicki on 21.09.2012.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import "PontoDispatcher.h"

#define RESPONSE_COMPLETE 0
#define RESPONSE_ERROR 1

#define kPontoUrlScheme @"ponto"
#define kPontoTargetParamName @"target"
#define kPontoMethodParamName @"method"
#define kPontoParamsParamName @"params"
#define kPontoCallbackIdParamName @"callbackId"

@implementation PontoDispatcher {

}

#pragma mark - Initialization

// Init with handler classes prefix
- (id)initWithHandlerClassesPrefix:(NSString *)classesPrefix {
    self = [super init];
    if (self) {
        _handlerClassesPrefix = classesPrefix;
    }

    return self;
}


/**
 * Init with handler classes prefix and webViewObject
 * @param NSString* classesPrefix
 * @param UIWebView webView
 * @return instance of PontoDispatcher
 */
- (id)initWithHandlerClassesPrefix:(NSString *)classesPrefix andWebView:(UIWebView *)webView {
    self = [self initWithHandlerClassesPrefix:classesPrefix];
    if (self) {
        self.webView = webView;
    }

    return self;
}

#pragma mark - WebView Setter

// WebView setter - set PontoDispatcher as delegate of webView
- (void)setWebView:(UIWebView *)webView {
    _webView = webView;
    _webView.delegate = self;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];

    if ([[url scheme] isEqualToString:kPontoUrlScheme]) {
        NSDictionary *requestParams = [self extractRequestParams:url];

        if (requestParams) {
            [self dispatch:requestParams];
        }

        return NO;
    }

    return YES;
}

#pragma mark - Private methods

- (NSDictionary *)extractRequestParams:(NSURL *)requestUrl {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    for (NSString *param in [[requestUrl query] componentsSeparatedByString:@"&"]) {
        NSArray *element = [param componentsSeparatedByString:@"="];

        if([element count] < 2) {
            continue;
        }

        [params setObject:[element objectAtIndex:1] forKey:[element objectAtIndex:0]];
    }

    return [NSDictionary dictionaryWithObjectsAndKeys:
            [params objectForKey:kPontoTargetParamName], kPontoTargetParamName,
            [params objectForKey:kPontoMethodParamName], kPontoMethodParamName,
            [params objectForKey:kPontoParamsParamName], kPontoParamsParamName,
            [params objectForKey:kPontoCallbackIdParamName], kPontoCallbackIdParamName,
            nil
    ];
}

// Add prefix to class name and return as Class
- (Class)classNameFromString:(NSString *)className {
    NSString *prefixedClassName = [NSString stringWithFormat:@"%@%@", self.handlerClassesPrefix, className, nil];
    return NSClassFromString(prefixedClassName);
}

- (SEL)methodSelectorFromString:(NSString *)methodName withParams:(BOOL)withParams {
    if (withParams) {
        return NSSelectorFromString([NSString stringWithFormat:@"%@:", methodName]);
    }

    return NSSelectorFromString([NSString stringWithFormat:@"%@", methodName]);
}

- (id)paramsObjectFromString:(NSString *)paramsString {
    id paramsObject = [self deserializeObjectFromJSONString:paramsString];
    return paramsObject;
}

- (id)deserializeObjectFromJSONString:(NSString *)jsonString {
    if (self.delegate && [self.delegate respondsToSelector:@selector(deserializeJSONString:)]) {
        return [self.delegate deserializeJSONString:jsonString];
    }

    // TODO: iOS < 5.0 support!
    return [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
}

- (NSString *)serializeObjectToJSONString:(id)objectToSerialize {
    if (self.delegate && [self.delegate respondsToSelector:@selector(serializeObjectToJSON:)]) {
        return [self.delegate serializeObjectToJSON:objectToSerialize];
    }

    // TODO: iOS < 5.0 support!
    NSData *json = [NSJSONSerialization dataWithJSONObject:objectToSerialize options:kNilOptions error:nil];
    return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
}

- (void)dispatch:(NSDictionary *)requestParams {
    if (requestParams && [requestParams objectForKey:kPontoTargetParamName] && [requestParams objectForKey:kPontoMethodParamName]) {
        Class targetClassName = [self classNameFromString:[requestParams objectForKey:kPontoTargetParamName]];
        id paramsObject = [self paramsObjectFromString:[requestParams objectForKey:kPontoParamsParamName]];
        SEL methodSelector = [self methodSelectorFromString:[requestParams objectForKey:kPontoMethodParamName] withParams:(paramsObject==nil)?YES:NO];
        NSString *callbackId = [requestParams objectForKey:kPontoCallbackIdParamName];

        if (targetClassName && [targetClassName isSubclassOfClass:[PontoBaseHandler class]]) {
            id handlerObject = [[targetClassName alloc] instance];

            if (handlerObject && [handlerObject respondsToSelector:methodSelector]) {
                id methodResponse;

                if (paramsObject) {
                    methodResponse = [handlerObject performSelector:methodSelector withObject:paramsObject];
                }
                else {
                    methodResponse = [handlerObject performSelector:methodSelector];
                }

                if (callbackId && ![callbackId isEqualToString:@""]) {
                    // TODO: Call JS callback (with id) in webView with 'methodResponse'
                }
            }
        }
        else {
            // TODO: change this!
            NSLog(@"Class %@ is not valid Ponto Request Handler", targetClassName);
        }
    }
}

@end