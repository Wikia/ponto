//
//  PontoDEMOViewController.m
//  Ponto
//
//  Created by Gregor <grzegorz@wikia-inc.com> on 21.09.2012.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import "PontoDEMOViewController.h"

@interface PontoDEMOViewController ()

@property (nonatomic, strong) PontoDispatcher *pontoDispatcher;

@end

static PontoDispatcher *_tempPontoDispatcher = nil;

@implementation PontoDEMOViewController


+ (PontoDispatcher *)getPontoDispatcher
{
    return _tempPontoDispatcher;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create Ponto Dispatcher
    self.title = @"Ponto DEMO WebView";
    self.pontoDispatcher = [[PontoDispatcher alloc] initWithHandlerClassesPrefix:@"PontoDEMO" andWebView:self.webView];

    // try to call JS method
    [self.pontoDispatcher invokeMethod:@"testMethod" onTarget:@"TODO_target" withParams:nil successBlock:^(id params) {
        NSLog(@"success block with params: %@", params);
    } errorBlock:^(id params) {
        NSLog(@"error block with params: %@", params);
    }];

    // Load local HTML file
    NSString *pathToLocalFile = [[NSBundle mainBundle] pathForResource:@"pontoDemo" ofType:@"html"];
    NSURL *localFileURL = [[NSURL alloc] initFileURLWithPath:pathToLocalFile];
    NSURLRequest *localFileRequest = [[NSURLRequest alloc] initWithURL:localFileURL];
    [self.webView loadRequest:localFileRequest];
    
    _tempPontoDispatcher = self.pontoDispatcher;
}


#pragma mark - PontoDispatcherCallbackDelegate methods

- (void)successCallbackWithParams:(id)params {
    NSLog(@"success callback with params: %@", params);
}

- (void)errorCallbackWithParams:(id)params {
    NSLog(@"error callback with params: %@", params);
}

@end
