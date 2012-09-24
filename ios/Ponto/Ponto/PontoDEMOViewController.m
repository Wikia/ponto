//
//  PontoDEMOViewController.m
//  Ponto
//
//  Created by Gregor <grzegorz@wikia-inc.com> on 21.09.2012.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import "PontoDEMOViewController.h"
#import "PontoDispatcher.h"

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

    // Load local HTML file
    NSString *pathToLocalFile = [[NSBundle mainBundle] pathForResource:@"pontoDemo" ofType:@"html"];
    NSURL *localFileURL = [[NSURL alloc] initFileURLWithPath:pathToLocalFile];
    NSURLRequest *localFileRequest = [[NSURLRequest alloc] initWithURL:localFileURL];
    [self.webView loadRequest:localFileRequest];
}

@end
