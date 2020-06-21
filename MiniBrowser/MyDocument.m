/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "MyDocument.h"
#import <WebKit/WebKit.h>

@implementation MyDocument

- (void)dealloc
{
    [docTitle release];
    [frameStatus release];
    [resourceStatus release];
	[URLToLoad release];
    [url release];
    [window release];
    [super dealloc];
}

- (id)webView
{
    return webView;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)loadURL:(NSURL *)URL
{
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)setURLToLoad:(NSURL *)URL
{
	[URL retain];
	[URLToLoad release];
	URLToLoad = URL;
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

    // Add any code here that need to be executed once the windowController has loaded the document's window.

    // Set the WebView delegates
    [webView setFrameLoadDelegate:self];
    [webView setUIDelegate:self];
    [webView setResourceLoadDelegate:self];
	
	NSString *resourcesPath = [[NSBundle mainBundle] resourcePath];
	NSString *htmlPath = [resourcesPath stringByAppendingString:@"/htdocs/index.html"];
	
    // Load a default URL
	NSURL *URL = URLToLoad != nil ? URLToLoad : [NSURL fileURLWithPath:htmlPath];
	[self loadURL:URL];
	[self setURLToLoad:nil];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    return [[[webView mainFrame] dataSource] data];
}

- (BOOL)readFromURL:(NSURL *)URL ofType:(NSString *)type error:(NSError **)error
{
	// If the WebView hasn't been created, load the URL in  windowControllerDidLoadNib:.
	if (webView != nil) {
		[self loadURL:URL];
	} else {
		[self setURLToLoad:URL];
	}
	*error = nil;
	return YES;
}

- (BOOL)readFromFile:(NSString *)path ofType:(NSString *)type
{
	// This method is called on Panther and is deprecated on Tiger. 
	// On Tiger, readFromURL:ofType:error is called instead.
	NSError *error;
	return [self readFromURL:[NSURL fileURLWithPath:path] ofType:type error:&error];
}

// URL TextField Acton Methods

// Action method invoked when the user enters a new URL
- (IBAction)connectURL:(id)sender
{
	[self loadURL:[NSURL URLWithString:[sender stringValue]]];
}

// Methods used to update the load status

// Updates the status and error messages
- (void)updateWindow
{
    if (resourceStatus != nil)
        [[webView window] setTitle: [NSString stringWithFormat: @"%@:  %@", docTitle, resourceStatus]];
    else if (frameStatus != nil)
        [[webView window] setTitle: [NSString stringWithFormat: @"%@:  %@", docTitle, frameStatus]];
    else if (docTitle != nil)
        [[webView window] setTitle: [NSString stringWithFormat: @"%@", docTitle]];
    else
        [[webView window] setTitle: @""];
    if (url != nil)
        [textField setStringValue:url];
}

// Updates the resource status and error messages
- (void)updateResourceStatus
{
    if (resourceFailedCount)
        [self setResourceStatus: [NSString stringWithFormat: @"Loaded %d of %d, %d resource errors", resourceCompletedCount, resourceCount - resourceFailedCount, resourceFailedCount]];
    else
        [self setResourceStatus: [NSString stringWithFormat: @"Loaded %d of %d", resourceCompletedCount, resourceCount]];
    [[webView window] setTitle: [NSString stringWithFormat: @"%@:  %@", docTitle, resourceStatus]];
}


// Accessor methods for instance variables

- (NSString *)docTitle
{
    return docTitle;
}

- (void)setDocTitle: (NSString *)t
{
    [docTitle release];
    docTitle = [t retain];
}

- (NSString *)frameStatus
{
    return frameStatus;
}

- (void)setFrameStatus: (NSString *)s
{
    [frameStatus release];
    frameStatus = [s retain];
}

- (NSString *)resourceStatus
{
    return resourceStatus;
}

- (void)setResourceStatus: (NSString *)s
{
    [resourceStatus release];
    resourceStatus = [s retain];
}

- (NSString *)url
{
    return url;
}

- (void)setURL: (NSString *)u
{
    [url release];
    url = [u retain];
}


// WebFrameLoadDelegate Methods

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]) {
        // Reset resource status variables
        resourceCount = 0;    
        resourceCompletedCount = 0;
        resourceFailedCount = 0;
    

        [self setFrameStatus:@"Loading..."];
        [self setURL:[[[[frame provisionalDataSource] request] URL] absoluteString]];
        [self updateWindow];
    }
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]) {
        [self setDocTitle:title];
        [self updateWindow];
    }
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]) {
        [self setFrameStatus: nil];
        [self updateWindow];
		[backButton setEnabled:[sender canGoBack]];
		[forwardButton setEnabled:[sender canGoForward]];
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]) {
        [self setDocTitle: @""];
        [self setFrameStatus:[error description]];
        [self updateWindow];
    }
}


// WebUIDelegate Methods

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    MyDocument *myDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"HTML Document" display:YES];
    [[[myDocument webView] mainFrame] loadRequest:request];
    
    return [myDocument webView];
}

- (void)webViewShow:(WebView *)sender
{
    id myDocument = [[NSDocumentController sharedDocumentController] documentForWindow:[sender window]];
    [myDocument showWindows];
}


// WebResourceLoadDelegate Methods

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
    // Return some object that can be used to identify this resource
    return [NSNumber numberWithInt: resourceCount++];    
}

-(NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponsefromDataSource:(WebDataSource *)dataSource
{
    // Update the status message
    [self updateResourceStatus];
    return request;
}

-(void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
{
    // Increment the failed count and update the status message
    resourceFailedCount++;
    [self updateResourceStatus];
}

-(void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
    // Increment the success count and pdate the status message
    resourceCompletedCount++;
    [self updateResourceStatus];    
}


// History Methods

- (void)goToHistoryItem:(id)historyItem
{
    // Load the history item in the main frame
	[self loadURL:[NSURL URLWithString:[historyItem URLString]]];
}

@end


