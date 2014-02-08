//
//  HTTPServerViewController.h
//  FEWEBServer
//
//  Created by Luka Penger on 4/6/13.
//  Copyright (c) 2013 LukaPenger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SharedData.h"
#import "ALToastView.h"

#import "MyHTTPConnection.h"

@interface HTTPServerViewController : UIViewController
{
    
}

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UILabel *displayLabel;
@property (nonatomic, retain) IBOutlet UILabel *logLabel;
@property (nonatomic, retain) IBOutlet UITextField *serverNameTextField;
@property (nonatomic, retain) IBOutlet UIButton *buttonStartStop;
@property (nonatomic, retain) IBOutlet UITextField *portTextField;

- (IBAction)buttonStartStopClicked:(id)sender;

- (void)showDisplayText;

@end
