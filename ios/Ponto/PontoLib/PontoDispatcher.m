//
//  PontoDispatcher
//  Ponto
//
//  Created by Grzegorz Nowicki <grzegorz@wikia-inc.com> on 21.09.2012.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import "PontoDispatcher.h"
#import <objc/message.h>
#import "NSURL+QueryDictionary.h"

#define RESPONSE_COMPLETE 0
#define RESPONSE_ERROR 1

NSString *const kPontoUrlScheme = @"ponto";
NSString *const kPontoTargetParamName = @"target";
NSString *const kPontoMethodParamName = @"method";
NSString *const kPontoParamsParamName = @"params";
NSString *const kPontoCallbackIdParamName = @"callbackId";
NSString *const kPontoCallbackJSString = @"Ponto.response(decodeURIComponent('%@'));";
NSString *const kPontoMethodInvokeJSString = @"Ponto.request(decodeURIComponent('%@'));";
NSString *const kPontoRequestUrlPath = @"/request";
NSString *const kPontoResponseUrlPath = @"/response";

NSInteger const kPontoHandlerMethodReturnTypeStringBufferLength = 128;

NSString *const kPontoSuccessCallbackBlockKey = @"successBlock";
NSString *const kPontoErrorCallbackBlockKey = @"errorBlock";

typedef void (^PontoSuccessCallback)(id responseObject);
typedef void (^PontoErrorCallback)(id responseObject);

static dispatch_queue_t ponto_dispatcher_concurrent_queue;
static dispatch_queue_t getPontoQueue() {
    if (ponto_dispatcher_concurrent_queue == nil) {
        ponto_dispatcher_concurrent_queue = dispatch_queue_create("com.wikia.ponto.queue", DISPATCH_QUEUE_CONCURRENT);
    }

    return ponto_dispatcher_concurrent_queue;
}

typedef enum {
    PontoHandlerMethodReturnTypeVoid,
    PontoHandlerMethodReturnTypeObject,
    PontoHandlerMethodReturnTypeInteger,
    PontoHandlerMethodReturnTypeDouble,
    PontoHandlerMethodReturnTypeUnknown
} PontoHandlerMethodReturnType;


@interface PontoDispatcher()
    @property (nonatomic, strong) NSMutableArray *callbacksQueue;
    @property (nonatomic, assign) id originalWebViewDelegate;

    @property (nonatomic, assign, getter=isWebKitEnabled) BOOL webKitEnabled;
@end


@implementation PontoDispatcher {

}

#pragma mark - Initialization

// Init with handler classes prefix
- (id)initWithHandlerClassesPrefix:(NSString *)classesPrefix {
    self = [super init];
    if (self) {
        _handlerClassesPrefix = classesPrefix;
        _callbacksQueue = [NSMutableArray array];
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

#pragma mark - JS method invoking

/**
 * Invoke JS method with success and error blocks
 */
- (void)invokeMethod:(NSString *)methodName onTarget:(NSString *)target withParams:(id)params successBlock:(PontoSuccessCallback)successBlock errorBlock:(PontoErrorCallback)errorBlock {
    NSMutableDictionary *callbacksDict = [NSMutableDictionary dictionary];
    __block NSString *callbackId = nil;

    if (successBlock) {
        [callbacksDict setObject:successBlock forKey:kPontoSuccessCallbackBlockKey];
    }

    if (errorBlock) {
        [callbacksDict setObject:errorBlock forKey:kPontoErrorCallbackBlockKey];
    }

    dispatch_barrier_sync(getPontoQueue(), ^{
        [self.callbacksQueue addObject:callbacksDict];
        callbackId = [NSString stringWithFormat:@"%d", [self.callbacksQueue count] - 1];
    });

    NSDictionary *methodInvokeDict = [[NSDictionary alloc] initWithObjectsAndKeys:
            target, @"target",
            methodName, @"method",
            callbackId, @"callbackId",
            params, @"params",
            nil
    ];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:methodInvokeDict options:NSJSONWritingPrettyPrinted error:nil];
    NSString *methodInvokeString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *jsString = [[NSString stringWithFormat:kPontoMethodInvokeJSString, methodInvokeString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
}


#pragma mark - WebView Setter

// WebView setter - set PontoDispatcher as delegate of webView
- (void)setWebView:(UIWebView *)webView {
    _webView = webView;
    _originalWebViewDelegate = _webView.delegate;
    _webView.delegate = self;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];

    NSLog(@"Should response to: %@", [url absoluteString]);

    if ([[url scheme] isEqualToString:kPontoUrlScheme]) {
        NSLog(@"host: %@", [url path]);

        if ([[url path] isEqualToString:kPontoRequestUrlPath]) {
            NSDictionary *requestParams = [self extractRequestParams:url];

            if (requestParams) {
                [self dispatchRequest:requestParams];
            }

            return NO;
        }
        else if ([[url path] isEqualToString:kPontoResponseUrlPath]) {
            NSDictionary *responseParams = [self extractResponseParams:url];

            if (responseParams) {
                [self dispatchResponse:responseParams];
            }

            return NO;
        }
    }

    if (self.originalWebViewDelegate != nil && [self.originalWebViewDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.originalWebViewDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if ([self.originalWebViewDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.originalWebViewDelegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([self.originalWebViewDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.originalWebViewDelegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if ([self.originalWebViewDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.originalWebViewDelegate webView:webView didFailLoadWithError:error];
    }
}

#pragma mark - Private methods

- (NSDictionary *)extractParamsFromUrl:(NSURL *)url {
    NSMutableDictionary *params = [[url uq_queryDictionary] mutableCopy];
    return params;
}

- (NSDictionary *)extractRequestParams:(NSURL *)requestUrl {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self extractParamsFromUrl:requestUrl]];

    return [params dictionaryWithValuesForKeys:[NSArray arrayWithObjects:kPontoTargetParamName,
                                                                         kPontoMethodParamName,
                                                                         kPontoParamsParamName,
                                                                         kPontoCallbackIdParamName,
                                                                         nil]];
}

- (NSDictionary *)extractResponseParams:(NSURL *)responseUrl {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self extractParamsFromUrl:responseUrl]];

    return [params dictionaryWithValuesForKeys:[NSArray arrayWithObjects:kPontoCallbackIdParamName,
                                                                         kPontoParamsParamName,
                                                                         nil]];
}

// Add prefix to class name and return as Class
- (Class)classNameFromString:(NSString *)className {
    NSString *prefixedClassName = [NSString stringWithFormat:@"%@%@", self.handlerClassesPrefix, className];
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

    return [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
}

- (NSString *)serializeObjectToJSONString:(id)objectToSerialize {
    if (objectToSerialize == nil) {
        return @"";
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(serializeObjectToJSON:)]) {
        return [self.delegate serializeObjectToJSON:objectToSerialize];
    }

    NSData *json = [NSJSONSerialization dataWithJSONObject:objectToSerialize options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
}

- (void)dispatchRequest:(NSDictionary *)requestParams {
    if (requestParams && [requestParams objectForKey:kPontoTargetParamName] && [requestParams objectForKey:kPontoMethodParamName]) {
        Class targetClassName = [self classNameFromString:[requestParams objectForKey:kPontoTargetParamName]];
        NSString *callbackId = [requestParams objectForKey:kPontoCallbackIdParamName];

        NSString *paramsString = [requestParams objectForKey:kPontoParamsParamName];
        id paramsObject = nil;

        if (paramsString && ![paramsString isEqual:[NSNull null]]) {
            paramsObject = [self paramsObjectFromString:[paramsString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }

        SEL methodSelector = [self methodSelectorFromString:[requestParams objectForKey:kPontoMethodParamName] withParams:(paramsObject!=nil)];

        if (targetClassName && [targetClassName isSubclassOfClass:[PontoBaseHandler class]]) {
            id handlerObject;
            handlerObject = [targetClassName instance];

            if (handlerObject && [handlerObject respondsToSelector:methodSelector]) {
                id response = [self callMethod:methodSelector inHandlerObject:handlerObject withParams:paramsObject];
                [self runJSCallback:callbackId withParams:response andType:RESPONSE_COMPLETE];
            }
            else {
                NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Handler object dont have method.", @"message", [requestParams objectForKey:kPontoMethodParamName], @"methodName", nil];
                [self runJSCallback:callbackId withParams:infoDict andType:RESPONSE_ERROR];
            }
        }
        else {
            NSLog(@"Class %@ is not valid Ponto Request Handler", [requestParams objectForKey:kPontoTargetParamName]);

            NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Class is not valid request handler.", @"message", [requestParams objectForKey:kPontoTargetParamName], @"className", nil];
            [self runJSCallback:callbackId withParams:infoDict andType:RESPONSE_ERROR];
        }
    }
}

- (void)dispatchResponse:(NSDictionary *)responseParams {
    if (responseParams && [responseParams objectForKey:kPontoCallbackIdParamName]) {
        NSString *responseType = [responseParams objectForKey:@"type"];
        NSString *callbackIdString = [responseParams objectForKey:kPontoCallbackIdParamName];
        NSUInteger callbackId = (NSUInteger)[callbackIdString integerValue];
        NSString *jsonString = [NSString stringWithFormat:@"[%@]", [responseParams objectForKey:@"params"]];
        NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        id responseObject = [responseArray objectAtIndex:0];

        NSDictionary *responseCallbackDict = [self.callbacksQueue objectAtIndex:callbackId];

        if (responseCallbackDict != nil) {
            PontoSuccessCallback successCallback = [responseCallbackDict objectForKey:kPontoSuccessCallbackBlockKey];
            PontoErrorCallback errorCallback = [responseCallbackDict objectForKey:kPontoErrorCallbackBlockKey];

            if (successCallback && (responseType == nil || [responseType isEqualToString:@"0"])) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(responseObject);
                });
            }

            if (errorCallback && (responseType != nil && [responseType isEqualToString:@"1"])) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorCallback(responseObject);
                });
            }
        }

        [self.callbacksQueue removeObjectAtIndex:callbackId];
    }
}

- (void)runJSCallback:(NSString *)callbackId withParams:(id)params andType:(int)type {
    if (callbackId && ![callbackId isEqual:[NSNull null]]) {
        NSDictionary *callbackDict = [NSDictionary dictionaryWithObjectsAndKeys:
                callbackId, @"callbackId",
                [NSNumber numberWithInt:type], @"type",
                params, @"params",
                nil
        ];

        NSString *jSCallbackString = [NSString stringWithFormat:kPontoCallbackJSString, [self serializeObjectToJSONString:callbackDict]];

        NSLog(@"try to call callback: %@", jSCallbackString);
        [self.webView stringByEvaluatingJavaScriptFromString:[jSCallbackString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (PontoHandlerMethodReturnType)convertEncodedTypeString:(char*) stringType {
    if (strcmp(stringType, @encode(void)) == 0) {
        return PontoHandlerMethodReturnTypeVoid;
    }

    if (strcmp(stringType, @encode(id)) == 0) {
        return PontoHandlerMethodReturnTypeObject;
    }

    return PontoHandlerMethodReturnTypeUnknown;
}

- (id)callMethod:(SEL)methodSelector inHandlerObject:(id)handlerObject withParams:(id)params {
    id response = nil;

    char methodReturnTypeDescriptionBuffer[kPontoHandlerMethodReturnTypeStringBufferLength];
    Method instanceMethod = class_getInstanceMethod([handlerObject class], methodSelector);
    method_getReturnType(instanceMethod, methodReturnTypeDescriptionBuffer, kPontoHandlerMethodReturnTypeStringBufferLength);

    PontoHandlerMethodReturnType methodReturnType = [self convertEncodedTypeString:methodReturnTypeDescriptionBuffer];

    switch (methodReturnType) {
        case PontoHandlerMethodReturnTypeObject:
            if (params) {
                response = [handlerObject performSelector:methodSelector withObject:params];
            }
            else {
                response = [handlerObject performSelector:methodSelector];
            }
            break;

        case PontoHandlerMethodReturnTypeUnknown:
        case PontoHandlerMethodReturnTypeVoid:
        default:
            if (params) {
                [handlerObject performSelector:methodSelector withObject:params];
            }
            else {
                [handlerObject performSelector:methodSelector];
            }
            break;
    }

    return response;
}

#pragma mark - iOS8 WKWebKitView stuff

- (void)setWebKitView:(id)webKitView {
    Class webKitViewClass = NSClassFromString(@"WKWebView");
    if (webKitViewClass && [webKitView isKindOfClass:webKitViewClass]) {
        _webKitView = webKitView;
        self.webKitEnabled = YES;
    }
}

@end
