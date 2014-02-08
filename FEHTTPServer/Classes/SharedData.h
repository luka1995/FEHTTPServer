//
//  SettingsData.h
//  IzziRent_Universal
//
//  Created by Luka Penger on 2/25/13.
//  Copyright (c) 2013 Izzivizzi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

#import "HTTPServer.h"
#import "MyHTTPConnection.h"

@interface SharedData : NSObject
{
    NSUserDefaults *userDefaults;
}

+ (id)sharedManager;
- (NSString*)deviceIPaddress;
+ (NSString*)convertFileSize:(unsigned long long)theSize;

@property (nonatomic, retain) HTTPServer *httpServer;
@property (nonatomic, retain) NSString *serverName;
@property (nonatomic, retain) NSString *displayText;
@property (nonatomic, assign) int defaultPort;

@end

