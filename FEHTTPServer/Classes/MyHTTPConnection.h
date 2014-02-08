#import <Foundation/Foundation.h>
#import "HTTPConnection.h"

#import "MyHTTPConnection.h"
#import "HTTPMessage.h"
#import "DDNumber.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPLogging.h"
#import "HTTPDataResponse.h"
#import "MultipartFormDataParser.h"
#import "MultipartMessageHeaderField.h"
#import "HTTPFileResponse.h"

#import "SharedData.h"
#import "HTTPServerViewController.h"

@class MultipartFormDataParser;

@interface MyHTTPConnection : HTTPConnection
{
    MultipartFormDataParser*        parser;
	NSFileHandle*					storeFile;
}

@end

