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

@implementation PontoDEMOViewController

- (void)viewDidLoad
{


    [super viewDidLoad];


    // Create Ponto Dispatcher
    self.title = @"Ponto DEMO WebView";
    self.pontoDispatcher = [[PontoDispatcher alloc] initWithHandlerClassesPrefix:@"PontoDEMO" andWebView:self.webView];

    // try to call JS method
    [self.pontoDispatcher invokeMethod:@"testMethod" onTarget:@"TODO_target" withParams:nil andCallbackDelegate:self];

    // Load local HTML file
    NSString *pathToLocalFile = [[NSBundle mainBundle] pathForResource:@"pontoDemo" ofType:@"html"];
    NSURL *localFileURL = [[NSURL alloc] initFileURLWithPath:pathToLocalFile];
    NSURLRequest *localFileRequest = [[NSURLRequest alloc] initWithURL:localFileURL];
    [self.webView loadRequest:localFileRequest];
}


#pragma mark - PontoDispatcherCallbackDelegate methods

- (void)successCallbackWithParams:(id)params {
    NSLog(@"success callback with params: %@", params);
}

- (void)errorCallbackWithParams:(id)params {
    NSLog(@"error callback with params: %@", params);
}

@end
