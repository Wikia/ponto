//
//  PontoDispatcher
//  Ponto
//
//  Created by Grzegorz Nowicki <grzegorz@wikia-inc.com> on 21.09.2012.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import "PontoDispatcher.h"
#include <objc/objc-runtime.h>

#define RESPONSE_COMPLETE 0
#define RESPONSE_ERROR 1

#define kPontoUrlScheme @"ponto"
#define kPontoTargetParamName @"target"
#define kPontoMethodParamName @"method"
#define kPontoParamsParamName @"params"
#define kPontoCallbackIdParamName @"callbackId"
#define kPontoCallbackJSString @"Ponto.response(decodeURIComponent('%@'));"
#define kPontoHandlerMethodReturnTypeStringBufferLenght 128

typedef enum {
    PontoHandlerMethodReturnTypeVoid,
    PontoHandlerMethodReturnTypeObject,
    PontoHandlerMethodReturnTypeInteger,
    PontoHandlerMethodReturnTypeDouble,
    PontoHandlerMethodReturnTypeUnknown
} PontoHandlerMethodReturnType;

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
// TODO: make PontoDispatcher smoething like proxy dispatcher if one dispatcher is already set
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

    return [params dictionaryWithValuesForKeys:[NSArray arrayWithObjects:kPontoTargetParamName,
                                                                         kPontoMethodParamName,
                                                                         kPontoParamsParamName,
                                                                         kPontoCallbackIdParamName,
                                                                         nil]];
}

// Add prefix to class name and return as Class
- (Class)classNameFromString:(NSString *)className {
    NSString *prefixedClassName = [NSString stringWithFormat:@"%@%@", self.handlerClassesPrefix, className, nil];
    return NSClassFromString(prefixedClassName);
}

- (SEL)methodSelectorFromString:(NSString *)methodName withParams:(BOOL)withParams {
    if (withParams == YES) {
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
    if (objectToSerialize == nil) {
        return @"";
    }

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
        NSString *callbackId = [requestParams objectForKey:kPontoCallbackIdParamName];

        NSString *paramsString = [requestParams objectForKey:kPontoParamsParamName];
        id paramsObject = nil;

        if (paramsString && ![paramsString isEqual:[NSNull null]]) {
            paramsObject = [self paramsObjectFromString:[paramsString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }

        SEL methodSelector = [self methodSelectorFromString:[requestParams objectForKey:kPontoMethodParamName] withParams:(paramsObject!=nil)?YES:NO];

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

- (void)runJSCallback:(NSString *)callbackId withParams:(id)params andType:(int)type {
    if (callbackId && ![callbackId isEqual:[NSNull null]]) {
        NSDictionary *callbackDict = [NSDictionary dictionaryWithObjectsAndKeys:
                callbackId, @"callbackId",
                [NSNumber numberWithInt:type], @"type",
                params, @"params",
                nil
        ];

        NSString *jSCallbackString = [NSString stringWithFormat:kPontoCallbackJSString, [self serializeObjectToJSONString:callbackDict]];
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

    char methodReturnTypeDescriptionBuffer[kPontoHandlerMethodReturnTypeStringBufferLenght];
    Method instanceMethod = class_getInstanceMethod([handlerObject class], methodSelector);
    method_getReturnType(instanceMethod, methodReturnTypeDescriptionBuffer, kPontoHandlerMethodReturnTypeStringBufferLenght);

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

@end