#import "MyHTTPConnection.h"


// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;

@implementation MyHTTPConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	if ([method isEqualToString:@"POST"])
	{
		if ([path isEqualToString:@"/index.html"])
		{
			return YES;
		}
        
        if ([path isEqualToString:@"/upload.html"])
		{
			return YES;
		}
	}
	
	return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    if([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.html"])
    {
        NSLog(@"%@",[[NSString alloc] initWithData:request.messageData encoding:NSUTF8StringEncoding]);
        
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if( NSNotFound == paramsSeparator ) {
            return NO;
        }
        if( paramsSeparator >= contentType.length - 1 ) {
            return NO;
        }
        NSString* type = [contentType substringToIndex:paramsSeparator];
        if(![type isEqualToString:@"multipart/form-data"] )
        {
            return NO;
        }
        
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for( NSString* param in params ) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if( (NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1 ) {
                continue;
            }
            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];
            
            if( [paramName isEqualToString: @"boundary"] ) {
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
            }
        }
        // check if boundary specified
        if( nil == [request headerField:@"boundary"] )  {
            return NO;
        }
        return YES;
    }
    
    if([method isEqualToString:@"POST"] && [path isEqualToString:@"/index.html"])
    {
        return YES;
    }
    
    return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	NSString *filePath = [self filePathForURI:path];

	// Convert to relative path
	
	NSString *documentRoot = [config documentRoot];
	
	if (![filePath hasPrefix:documentRoot])
	{
		// Uh oh.
		// HTTPConnection's filePathForURI was supposed to take care of this for us.
		return nil;
	}

    NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
	
    if([method isEqualToString:@"GET"] && [relativePath hasPrefix:@"/files/"] ) {
		// let download the uploaded files
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        
		return [[HTTPFileResponse alloc] initWithFilePath: [documentsDirectory stringByAppendingString:path] forConnection:self];
	}
    
    if ([relativePath isEqualToString:@"/index.html"])
	{
        if([method isEqualToString:@"POST"])
        {
            NSLog(@"%@[%p]: postContentLength: %qu", THIS_FILE, self, requestContentLength);
            
            NSString *postStr = nil;
            
            NSData *postData = [request body];
 
            if (postData)
            {
                postStr = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];

                NSRange range = [postStr rangeOfString:@"="];
                if([[postStr substringToIndex:range.location] isEqualToString:@"DELETE_FILE"])
                {
                    NSString *filename = [postStr substringFromIndex:range.location+1];
                    
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *filePath=[[[paths objectAtIndex:0] stringByAppendingPathComponent:@"files"] stringByAppendingPathComponent:filename];
                    
                    NSError *error = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                    if(error)
                    {
                        NSLog(@"%@",error.description);
                    }
                }
            }
        }
        
		// this method will generate response with links to uploaded file
		NSMutableString* filesStr = [[NSMutableString alloc] init];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        NSString *documentsDirectoryFiles=[documentsDirectory stringByAppendingPathComponent:@"files"];
        
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryFiles error:nil];
        
        [filesStr appendString:@"<tr><th>Name</th><th>Size</th><th>Delete</th></tr>"];
        NSLog(@"count %d",dirContents.count);
        
        //file name, file path,
		for(NSString *fileName in dirContents)
        {
            NSString *filePath = [NSString stringWithFormat:@"%@/%@",documentsDirectoryFiles,fileName];
            
            unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
            
            NSString *filePathDirectory = [filePath stringByReplacingOccurrencesOfString:documentsDirectory withString:@""];
            
            [filesStr appendFormat:@"<tr><td><a href=\"%@\">%@</a></td><td>%@</td><form action=\"index.html\" method=\"POST\"><td><input type=\"hidden\" value=\"%@\" name=\"DELETE_FILE\"><input type=\"submit\" value=\"Delete\"></td></form></tr>",filePathDirectory, fileName,[SharedData convertFileSize:fileSize],fileName];
		}
        
		NSString* templatePath = [[config documentRoot] stringByAppendingPathComponent:@"index.html"];
        
        NSMutableDictionary *replacementDict = [NSMutableDictionary dictionary];
        [replacementDict setObject:filesStr forKey:@"UPLOADED_FILES"];
        [replacementDict setObject:[NSString stringWithFormat:@"%d",dirContents.count] forKey:@"NUMBER_OF_FILES"];
        
		return [[HTTPDynamicFileResponse alloc] initWithFilePath:templatePath forConnection:self separator:@"%%" replacementDictionary:replacementDict];
	}
    
    return [super httpResponseForMethod:method URI:path];
}


- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	// If we supported large uploads,
	// we might use this method to create/open files, allocate memory, etc.

    // set up mime parser
    NSString* boundary = [request headerField:@"boundary"];
    parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    parser.delegate = self;
}

- (void)processBodyData:(NSData *)postDataChunk
{
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
    [parser appendData:postDataChunk];
    
    BOOL result = [request appendData:postDataChunk];
    if (!result)
    {
        HTTPLogError(@"%@[%p]: %@ - Couldn't append bytes!", THIS_FILE, self, THIS_METHOD);
    }
}

- (void) processStartOfPartWithHeader:(MultipartMessageHeader*) header
{
	// in this sample, we are not interested in parts, other then file parts.
	// check content disposition to find out filename
    
    MultipartMessageHeaderField* disposition = [header.fields objectForKey:@"Content-Disposition"];
	NSString* filename = [[disposition.params objectForKey:@"filename"] lastPathComponent];

    if ( (nil == filename) || [filename isEqualToString: @""] ) {
        // it's either not a file part, or
		// an empty form sent. we won't handle it.
		return;
	}

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
	NSString* uploadDirPath = [documentsDirectory stringByAppendingPathComponent:@"files"];
    
    NSString* filePath = [uploadDirPath stringByAppendingPathComponent:filename];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        storeFile = nil;
    }
    else
    {
		if(![[NSFileManager defaultManager] createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil])
        {
			NSLog(@"Could not create directory at path: %@", uploadDirPath);
		}
		if(![[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]) {
			NSLog(@"Could not create file at path: %@", filePath);
		}
		storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
}


- (void) processContent:(NSData*) data WithHeader:(MultipartMessageHeader*) header
{
	// here we just write the output from parser to the file.
	if( storeFile && storeFile.fileDescriptor!=0) {
		[storeFile writeData:data];
	}
}

- (void) processEndOfPartWithHeader:(MultipartMessageHeader*) header
{
	// as the file part is over, we close the file.
	[storeFile closeFile];
	storeFile = nil;
}

- (void) processPreambleData:(NSData*) data
{
    // if we are interested in preamble data, we could process it here.
    
}

- (void) processEpilogueData:(NSData*) data
{
    // if we are interested in epilogue data, we could process it here.
    
}






- (BOOL)isPasswordProtected:(NSString *)path
{
    return NO;
}

- (NSString *)passwordForUser:(NSString *)username
{
	// You can do all kinds of cool stuff here.
	// For simplicity, we're not going to check the username, only the password.
	
    if([username isEqualToString:@"admin"])
    {
        return @"admin";
    } else {
        return [NSString stringWithFormat:@"%d",INT_MAX];
    }
}

- (BOOL)useDigestAccessAuthentication
{
	// Digest access authentication is the default setting.
	// Notice in Safari that when you're prompted for your password,
	// Safari tells you "Your login information will be sent securely."
	//
	// If you return NO in this method, the HTTP server will use
	// basic authentication. Try it and you'll see that Safari
	// will tell you "Your password will be sent unencrypted",
	// which is strongly discouraged.
	
	return YES;
}

- (BOOL)isBrowseable:(NSString *)path
{
	// Override me to provide custom configuration...
	// You can configure it for the entire server, or based on the current request
	
	return YES;
}

- (void)dealloc
{
    [storeFile release];
    [parser release];
    [super dealloc];
}

@end
