/* 
 * TTGraphicsWindow Object for Jamoma
 * Copyright © 2009 by Timothy Place
 * 
 * License: This code is licensed under the terms of the GNU LGPL
 * http://www.gnu.org/licenses/lgpl.html 
 */

#include "TTGraphicsWindow.h"

#define thisTTClass			TTGraphicsWindow
#define thisTTClassName		"TTGraphicsWindow"
#define thisTTClassTags		"graphics"


// http://developer.apple.com/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-CJBDCHAC


#pragma mark -
#pragma mark ObjC Code for custom NSView

#import <Cocoa/Cocoa.h>


@implementation TTGraphicsContentView


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        ownsWindow = NO;
		x = NULL;
    }
    return self;
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)rect 
{ 
	cairo_surface_t*	surface = NULL;
	CGContext*			context = NULL;
	
	if (ownsWindow) {
		context = (CGContext*)[[NSGraphicsContext currentContext] graphicsPort]; 
	}
	else {
		NSWindow*	window = [self window];

		context = (CGContext*)[window context];
	}
	surface = cairo_quartz_surface_create_for_cg_context(context, (int)rect.size.width, (int)rect.size.height); 
	//    cairo_t *cairoContext = cairo_create(surface); 
	
	x->context->cairoContext = cairo_create(surface);
	x->draw();
		
    cairo_destroy(x->context->cairoContext);
	x->context->cairoContext = NULL;
    cairo_surface_destroy(surface);
} 

@end





#pragma mark -
#pragma mark ObjC Code for receiving delegated window events

@implementation TTCocoaWindowDelegate
- (BOOL)windowWillClose:(NSNotification *)notification
{
	NSWindow*	windowAboutToClose = [notification object];
	BOOL		shouldClose = YES;
	
	if(windowAboutToClose == x->theWindow){
		x->theWindow = NULL;
		// what about the content view?
	}
	
	return shouldClose;
}
@end





#pragma mark -
#pragma mark C++ Code


TT_OBJECT_CONSTRUCTOR,
	theWindow(NULL),
	context(NULL)
{
	registerAttributeWithSetter(title, kTypeSymbol);
	registerMessageSimple(front);
	registerMessageSimple(refresh);

	TTObjectInstantiate(TT("TTGraphicsContext"), (TTObjectPtr*)&context, arguments);
	
	// TODO: make bounds an attribute
	bounds.origin.x = 200;
	bounds.origin.y = 200;
	bounds.size.width = 600;
	bounds.size.height = 400;
	
	setAttributeValue(TT("title"), TT("Jamoma Graphics"));
}


TTGraphicsWindow::~TTGraphicsWindow()
{
	dispose();
	TTObjectRelease((TTObjectPtr*)&context);
}


TTErr TTGraphicsWindow::dispose()
{
	if (theWindow)
		[theWindow release];	
	return kTTErrNone;
}


TTErr TTGraphicsWindow::front()
{
	if (!theWindow) {		
		theWindow = [[NSWindow alloc] initWithContentRect:bounds 
												styleMask:NSTitledWindowMask|NSClosableWindowMask 
												  backing:NSBackingStoreBuffered 
													defer:NO];

		theContentView = [[TTGraphicsContentView alloc] initWithFrame:bounds];
		theContentView->x = this;
		theContentView->ownsWindow = YES;
		[theWindow setContentView:theContentView];
		
		windowDelegate = [[TTCocoaWindowDelegate alloc] init];
		windowDelegate->x = this;
		[theWindow setDelegate:windowDelegate];
		
		updateTitle();	
	}

	[theWindow orderFrontRegardless];
	[theWindow makeKeyWindow];

	return kTTErrNone;
}


TTErr TTGraphicsWindow::refresh()
{
	if (theWindow)
		[theWindow display];
	return kTTErrNone;
}


TTErr TTGraphicsWindow::updateTitle()
{
	NSString*	nsTitle = [[NSString alloc] initWithCString:title->getCString()];

	if (theWindow)
		[theWindow setTitle:nsTitle];
	// TODO: are we leaking an NSString here?
	return kTTErrNone;
}


TTErr TTGraphicsWindow::settitle(const TTValue& v)
{
	title = v;
	return updateTitle();
}


TTErr TTGraphicsWindow::draw()
{
	// when we are told to draw, that means that we need to tell all observers to send their drawing code
	// and we need to provide them with a context to which they can draw
	TTValue v = (TTObjectPtr)context;
	
	return observers->iterateObjectsSendingMessage(TT("draw"), v);
}

