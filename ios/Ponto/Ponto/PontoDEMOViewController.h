//
//  PontoDEMOViewController.h
//  Ponto
//
//  Created by Gregor <grzegorz@wikia-inc.com> on 21.09.2012.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PontoDispatcher.h"

@interface PontoDEMOViewController : UIViewController <PontoDispatcherCallbackDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;

+ (PontoDispatcher *)getPontoDispatcher;
@end
