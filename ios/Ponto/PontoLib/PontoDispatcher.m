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


@interface PontoDispatcher() <UIWebViewDelegate, WKNavigationDelegate>

@property (nonatomic, strong) NSMutableArray *callbacksQueue;
@property (nonatomic, assign) id originalWebViewDelegate;

@property (nonatomic, assign, getter=isWebKitEnabled) BOOL webKitEnabled;
@property (nonatomic, assign) id <WKNavigationDelegate>originalWebKitViewNavigationDelegate;

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

    NSDictionary *methodInvokeDict = @{
            @"target" : target,
            @"method" : methodName,
            @"callbackId" : callbackId,
            @"params" : params
    };

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:methodInvokeDict options:NSJSONWritingPrettyPrinted error:nil];
    NSString *methodInvokeString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *jsString = [[NSString stringWithFormat:kPontoMethodInvokeJSString, methodInvokeString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    if (self.isWebKitEnabled) {
        [self.webKitView evaluateJavaScript:jsString completionHandler:^(id o, NSError *error) {
            NSLog(@"JS Completion Handler with o: %@", o);
        }];
    }
    else {
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    }
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

    return [params dictionaryWithValuesForKeys:@[
            kPontoTargetParamName,
            kPontoMethodParamName,
            kPontoParamsParamName,
            kPontoCallbackIdParamName
    ]];
}

- (NSDictionary *)extractResponseParams:(NSURL *)responseUrl {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self extractParamsFromUrl:responseUrl]];

    return [params dictionaryWithValuesForKeys:@[kPontoCallbackIdParamName,
            kPontoParamsParamName
    ]];
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
    if (requestParams && requestParams[kPontoTargetParamName] && requestParams[kPontoMethodParamName]) {
        Class targetClassName = [self classNameFromString:requestParams[kPontoTargetParamName]];
        NSString *callbackId = requestParams[kPontoCallbackIdParamName];

        NSString *paramsString = requestParams[kPontoParamsParamName];
        id paramsObject = nil;

        if (paramsString && ![paramsString isEqual:[NSNull null]]) {
            paramsObject = [self paramsObjectFromString:[paramsString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }

        SEL methodSelector = [self methodSelectorFromString:requestParams[kPontoMethodParamName] withParams:(paramsObject != nil)];

        if (targetClassName && [targetClassName isSubclassOfClass:[PontoBaseHandler class]]) {
            id handlerObject;
            handlerObject = [targetClassName instance];

            if (handlerObject && [handlerObject respondsToSelector:methodSelector]) {
                id response = [self callMethod:methodSelector inHandlerObject:handlerObject withParams:paramsObject];
                [self runJSCallback:callbackId withParams:response andType:RESPONSE_COMPLETE];
            }
            else {
                NSDictionary *infoDict = @{@"message" : @"Handler object dont have method.", @"methodName" : requestParams[kPontoMethodParamName]};
                [self runJSCallback:callbackId withParams:infoDict andType:RESPONSE_ERROR];
            }
        }
        else {
            NSLog(@"Class %@ is not valid Ponto Request Handler", requestParams[kPontoTargetParamName]);

            NSDictionary *infoDict = @{@"message" : @"Class is not valid request handler.", @"className" : requestParams[kPontoTargetParamName]};
            [self runJSCallback:callbackId withParams:infoDict andType:RESPONSE_ERROR];
        }
    }
}

- (void)dispatchResponse:(NSDictionary *)responseParams {
    if (responseParams && responseParams[kPontoCallbackIdParamName]) {
        NSString *responseType = responseParams[@"type"];
        NSString *callbackIdString = responseParams[kPontoCallbackIdParamName];
        NSUInteger callbackId = (NSUInteger)[callbackIdString integerValue];
        NSString *jsonString = [NSString stringWithFormat:@"[%@]", responseParams[@"params"]];
        NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        id responseObject = responseArray[0];

        NSDictionary *responseCallbackDict = (self.callbacksQueue)[callbackId];

        if (responseCallbackDict != nil) {
            PontoSuccessCallback successCallback = responseCallbackDict[kPontoSuccessCallbackBlockKey];
            PontoErrorCallback errorCallback = responseCallbackDict[kPontoErrorCallbackBlockKey];

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
        NSDictionary *callbackDict = @{
                @"callbackId" : callbackId,
                @"type" : @(type),
                @"params" : params
        };

        NSString *jSCallbackString = [NSString stringWithFormat:kPontoCallbackJSString, [self serializeObjectToJSONString:callbackDict]];

        NSLog(@"try to call callback: %@", jSCallbackString);

        if (self.isWebKitEnabled) {
            [self.webKitView evaluateJavaScript:[jSCallbackString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] completionHandler:^(id o, NSError *error) {
                NSLog(@"JS Completion handler with o: %@", o);
            }];
        }
        else {
            [self.webView stringByEvaluatingJavaScriptFromString:[jSCallbackString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
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
    _webKitView = webKitView;
    self.originalWebKitViewNavigationDelegate = _webKitView.navigationDelegate;
    _webKitView.navigationDelegate = self;
    self.webKitEnabled = YES;
}

#pragma mark -

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if ([[url scheme] isEqualToString:kPontoUrlScheme]) {
        if ([[url path] isEqualToString:kPontoRequestUrlPath]) {
            decisionHandler(WKNavigationActionPolicyCancel);

            NSDictionary *requestParams = [self extractRequestParams:url];

            if (requestParams) {
                [self dispatchRequest:requestParams];
            }
        }
        else if ([[url path] isEqualToString:kPontoResponseUrlPath]) {
            decisionHandler(WKNavigationActionPolicyCancel);

            NSDictionary *responseParams = [self extractResponseParams:url];

            if (responseParams) {
                [self dispatchResponse:responseParams];
            }
        }
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [self.originalWebKitViewNavigationDelegate webView:webView didCommitNavigation:navigation];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.originalWebKitViewNavigationDelegate webView:webView didFinishNavigation:navigation];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self.originalWebKitViewNavigationDelegate webView:webView didFailNavigation:navigation withError:error];
}

@end
