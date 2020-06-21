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

#import "AppController.h"

@implementation AppController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Create a shared WebHistory object
    WebHistory *myHistory = [[WebHistory alloc] init];
    [WebHistory setOptionalSharedHistory:myHistory];

    // Observe WebHistory notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(historyDidLoad:) 
               name:WebHistoryLoadedNotification object:myHistory];
    [nc addObserver:self selector:@selector(historyDidRemoveAllItems:) 
               name:WebHistoryAllItemsRemovedNotification object:myHistory];
    [nc addObserver:self selector:@selector(historyDidAddItems:) 
               name:WebHistoryItemsAddedNotification object:myHistory];
    [nc addObserver:self selector:@selector(historyDidRemoveItems:) 
               name:WebHistoryItemsRemovedNotification object:myHistory];
}


// WebHistory Notification Messages

- (void)historyDidLoad:(NSNotification *)aNotification
{
    // Delete the old menu items
    [self removeAllHistoryMenuItems];

    // Get the new history items
    NSArray *items = [[WebHistory optionalSharedHistory] orderedItemsLastVisitedOnDay:[NSCalendarDate calendarDate]];
    NSEnumerator *enumerator = [items objectEnumerator];
    id historyItem;

    // For each item, create a menu item with the history item as the represented object
    while (historyItem = [enumerator nextObject])
	[self addNewMenuItemForHistoryItem:historyItem];
}

- (void)historyDidAddItems:(NSNotification *)aNotification
{
    // Get the new history items
    NSArray *items = [[aNotification userInfo] objectForKey:WebHistoryItemsKey];
    NSEnumerator *enumerator = [items objectEnumerator];
    id historyItem;

    // For each item, create a menu item with the history item as the represented object
    while (historyItem = [enumerator nextObject])
	[self addNewMenuItemForHistoryItem:historyItem];
}

- (void)historyDidRemoveItems:(NSNotification *)aNotification
{
    // Get the removed history items
    NSArray *items = [[aNotification userInfo] objectForKey:WebHistoryItemsKey];
    NSEnumerator *enumerator = [items objectEnumerator];
    id historyItem;

    // For each item, remove the corresponding menu item
    while (historyItem = [enumerator nextObject]) {
		[self removeMenuItemForHistoryItem:historyItem];
    }
}

- (void)historyDidRemoveAllItems:(NSNotification *)aNotification
{
    [self removeAllHistoryMenuItems];
}


// Methods in support of adding and removing menu items

// This method leaves the first menu item which is the Clear action
- (void)removeAllHistoryMenuItems{
    int count;
    while ((count = [historyMenu numberOfItems]) != 1)
	[historyMenu removeItemAtIndex:count-1];
}

- (void)addNewMenuItemForHistoryItem:(WebHistoryItem *)historyItem
{
    // Create a new menu item, and set its  action and target to invoke goToHistoryItem:
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[historyItem URLString] action:@selector(goToHistoryItem:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:historyItem];

    // Add it to the menu
    [historyMenu addItem:menuItem];
}

- (void)removeMenuItemForHistoryItem:(WebHistoryItem *)historyItem
{
    // Get the menu item corresponsing to historyItem
    // *** Should really check for the represented object, not the title because itemWithTitle: will return the first match
    // *** unless history items are guarantted not to have the same title?
    NSMenuItem *menuItem = [historyMenu itemWithTitle:[historyItem originalURLString]];
    if ([menuItem representedObject] == historyItem)
	[historyMenu removeItem:menuItem];
    else
	NSLog(@"Opps, multiple menu items with the same title, can't remove the right one!");
}


// History Action Methods

// Removes all the history items
- (IBAction)clearHistory:(id)sender
{
    [[WebHistory optionalSharedHistory] removeAllItems];
}

// This method will be invoked by the menu item whose represented object is the selected history item
- (IBAction)goToHistoryItem:(id)sender
{
    // Ask the key window's delegate to load the history item
    NSWindow *keyWindow = [[NSApplication sharedApplication] keyWindow];
    if (keyWindow != nil) {
		[[keyWindow delegate] goToHistoryItem:[sender representedObject]];
    } else {
	    // If there is no key window, create a new window to load the history item
		id aDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"HTML Document" display:YES];
		NSString *urlString = [[sender representedObject] URLString];
		[[[aDocument webView] mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    }
}

@end
