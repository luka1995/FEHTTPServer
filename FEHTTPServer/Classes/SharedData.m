//
//  SettingsData.m
//  IzziRent_Universal
//
//  Created by Luka Penger on 2/25/13.
//  Copyright (c) 2013 Izzivizzi. All rights reserved.
//

#import "SharedData.h"

static SharedData *sharedMyManager = nil;

@implementation SharedData

@synthesize httpServer;
@synthesize defaultPort;
@synthesize serverName;

#pragma mark Singleton Methods

+ (id)sharedManager {
    @synchronized(self) {
        if(sharedMyManager == nil)
        {
            sharedMyManager = [[super allocWithZone:NULL] init];
        }
    }
    return sharedMyManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedManager] retain];
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)retain {
    return self;
}
- (unsigned)retainCount {
    return UINT_MAX; //denotes an object that cannot be released
}
- (oneway void)release {
    // never release
}
- (id)autorelease {
    return self;
}

- (id)init {
    if (self = [super init])
    {
        if(!userDefaults)
            userDefaults = [NSUserDefaults standardUserDefaults];

        if(!self.httpServer)
            self.httpServer = [[HTTPServer alloc] init];

        [self.httpServer setConnectionClass:[MyHTTPConnection class]];
        
        /*
         // Serve files from the standard Sites folder
         NSString *docRoot = [[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"web"] stringByDeletingLastPathComponent];
         DDLogInfo(@"Setting document root: %@", docRoot);
         
         [httpServer setDocumentRoot:docRoot];
         */
        
        self.serverName=@"FLASH ELECTRONICS";
        self.defaultPort=10011;
    }
    return self;
}

- (NSString *)deviceIPaddress
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *wifiAddress = nil;
    NSString *cellAddress = nil;
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if(sa_type == AF_INET || sa_type == AF_INET6) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                NSLog(@"NAME: \"%@\" addr: %@", name, addr); // see for yourself
                
                if([name isEqualToString:@"en0"]) {
                    // Interface is the wifi connection on the iPhone
                    if(![addr isEqualToString:@"0.0.0.0"])
                    {
                        wifiAddress = addr;
                    }
                } else
                    if([name isEqualToString:@"pdp_ip0"]) {
                        // Interface is the cell connection on the iPhone
                        if(![addr isEqualToString:@"0.0.0.0"])
                        {
                            cellAddress = addr;
                        }
                    }
            }
            temp_addr = temp_addr->ifa_next;
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    
    NSString *addr = wifiAddress ? wifiAddress : cellAddress;
    return addr ? addr : @"0.0.0.0";
}

+ (NSString*)convertFileSize:(unsigned long long)theSize
{
	unsigned long long floatSize = theSize;
	if (theSize<1000)
		return([NSString stringWithFormat:@"%lli B",theSize]);
	floatSize = floatSize / 1000;
	if (floatSize<1000)
		return([NSString stringWithFormat:@"%1.1llu KB",floatSize]);
	floatSize = floatSize / 1000;
	if (floatSize<1000)
		return([NSString stringWithFormat:@"%1.1llu MB",floatSize]);
	floatSize = floatSize / 1000;
    
	return ([NSString stringWithFormat:@"%1.1llu GB",floatSize]);
}

- (void)dealloc
{
    [userDefaults release];
    [self.httpServer release];
    [self.serverName release];
    [self.displayText release];
    [super dealloc];
}

@end
