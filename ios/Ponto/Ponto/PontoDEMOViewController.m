//
//  PontoDEMOViewController.m
//  Ponto
//
//  Created by Gregor on 21.09.2012.
//
//

#import "PontoDEMOViewController.h"
#import "PontoDispatcher.h"

@interface PontoDEMOViewController ()

@property (nonatomic, strong) PontoDispatcher *pontoDispatcher;

@end

@implementation PontoDEMOViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Create Ponto Dispatcher
        _pontoDispatcher = [[PontoDispatcher alloc] initWithHandlerClassesPrefix:@"" andWebView:self.webView];

        // Load local HTML file
        NSString *pathToLocalFile = [[NSBundle mainBundle] pathForResource:@"pontoDemo" ofType:@"html"];
        NSURL *localFileURL = [[NSURL alloc] initFileURLWithPath:pathToLocalFile];
        NSURLRequest *localFileRequest = [[NSURLRequest alloc] initWithURL:localFileURL];
        [self.webView loadRequest:localFileRequest];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
