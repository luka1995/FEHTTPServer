//
//  HTTPServerViewController.m
//  FEWEBServer
//
//  Created by Luka Penger on 4/6/13.
//  Copyright (c) 2013 LukaPenger. All rights reserved.
//

#import "HTTPServerViewController.h"

@interface HTTPServerViewController ()

@end

@implementation HTTPServerViewController

@synthesize portTextField;
@synthesize buttonStartStop;
@synthesize serverNameTextField;
@synthesize logLabel,displayLabel,imageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.portTextField.text=[NSString stringWithFormat:@"%d",[[SharedData sharedManager] defaultPort]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDisplayText) name:@"showDisplayText" object:nil];
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonStartStopClicked:(id)sender
{
    [self startStopServer];
}

- (void)startStopServer
{
    [ALToastView removeToastFromView];
    
    [[SharedData sharedManager] setServerName:self.serverNameTextField.text];
    
    self.logLabel.text=@"";
    
    int port = [[self.portTextField text] intValue];
    if(port==0)
    {
        port=[[SharedData sharedManager] defaultPort];
        NSString *error = @"PORT error";
        [ALToastView toastInView:self.view withText:error withPaddingBottom:0];
    }

    if(![[SharedData sharedManager] httpServer].isRunning)
    {
        [[[SharedData sharedManager] httpServer] setPort:port];
        [[[SharedData sharedManager] httpServer] setType:@"_http._tcp."];
        // Serve files from our embedded Web folder

        NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];

        [[[SharedData sharedManager] httpServer] setDocumentRoot:webPath];
        
        // Start the server (and check for problems)
        
        NSError *errorr;
        if([[[SharedData sharedManager] httpServer] start:&errorr])
        {
            [self.buttonStartStop setTitle:@"STOP WEB Server" forState:UIControlStateNormal];

            NSString *error = [NSString stringWithFormat:@"Started HTTP Server on port %hu",[[[SharedData sharedManager] httpServer] listeningPort]];
            [ALToastView toastInView:self.view withText:error withPaddingBottom:0];
            
            self.logLabel.text=[NSString stringWithFormat:@"http://%@:%d",[[SharedData sharedManager] deviceIPaddress],[[[SharedData sharedManager] httpServer] listeningPort]];
        }
        else
        {
            NSString *error = [NSString stringWithFormat:@"Error starting HTTP Server: %@",errorr];
            [ALToastView toastInView:self.view withText:error withPaddingBottom:0];
        }
    } else {
        [[[SharedData sharedManager] httpServer] stop];
        
        [self.buttonStartStop setTitle:@"START WEB Server" forState:UIControlStateNormal];

        NSString *error = @"HTTP Server stoped";
        [ALToastView toastInView:self.view withText:error withPaddingBottom:0];
    }
}

- (void)showDisplayText
{
    self.displayLabel.text=[NSString stringWithFormat:@"DISPLAY TEXT: %@",[[SharedData sharedManager] displayText]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)dealloc
{
    [self.portTextField release];
    [self.buttonStartStop release];
    [self.serverNameTextField release];
    [self.logLabel release];
    [self.displayLabel release];
    [self.imageView release];
    [super dealloc];
}

@end
