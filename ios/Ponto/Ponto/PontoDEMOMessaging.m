//
//  PontoDEMOMessaging
//  Ponto 
//
//  Created by Grzegorz Nowicki <grzegorz@wikia-inc.com> on 24.09.2012.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import "PontoDEMOMessaging.h"
#import "PontoDEMOAppDelegate.h"

@implementation PontoDEMOMessaging {

}

+ (id)instance {
    return [[self alloc] init];
}

- (void)sendMessage:(id)params {
    if ([params isKindOfClass:[NSDictionary class]]) {
        PontoDEMOAppDelegate *app = (PontoDEMOAppDelegate*)[[UIApplication sharedApplication] delegate];

        NSString *subject = [(NSDictionary *)params objectForKey:@"subject"];
        NSString *body = [(NSDictionary *)params objectForKey:@"body"];
        id recipients = [(NSDictionary *)params objectForKey:@"to"];

        if ([recipients isKindOfClass:[NSArray class]]) {
            [app displaySendEmailMessagePickerWithRecipients:(NSArray *)recipients andSubject:subject andBody:body];
        }
        else if ([recipients isKindOfClass:[NSString class]]) {
            [app displaySendEmailMessagePickerWithRecipients:[NSArray arrayWithObject:(NSString *)recipients] andSubject:subject andBody:body];
        }
        else{
            [app displaySendEmailMessagePickerWithRecipients:nil andSubject:subject andBody:body];
        }
    }
}

- (NSDictionary *)getSomeDataFromHandler {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"wikia.com", @"url",
            @"iOS", @"current_platform",
            @"0.1", @"ponto_version",
            nil
    ];
}

- (void)webViewAlertCallback {
    
    // try to call JS method
    [[PontoDEMOViewController getPontoDispatcher] invokeMethod:@"show" onTarget:@"Alert" withParams:[NSDictionary dictionaryWithObjectsAndKeys: @"this is callback text",@"text",nil] successBlock:^(id params) {
        NSLog(@"success block with params: %@", params);
    } errorBlock:^(id params) {
        NSLog(@"error block with params: %@", params);
    }];
}

@end