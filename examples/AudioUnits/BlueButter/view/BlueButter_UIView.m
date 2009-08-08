#import "BlueButter_UIView.h"

enum {
	kFilterParam_CutoffFrequency = 0,
	kFilterParam_Resonance = 1
};


//extern NSString *kGraphViewDataChangedNotification;	// notification broadcast by the view when the user has changed the resonance 
													// or cutoff values via directly mousing in the graph view
//extern NSString *kGraphViewBeginGestureNotification;// notification broadcast by the view when the user has started a gesture
//extern NSString *kGraphViewEndGestureNotification;	// notification broadcast by the view when the user has finished a gesture



// This listener responds to parameter changes, gestures, and property notifications
void EventListenerDispatcher (void *inRefCon, void *inObject, const AudioUnitEvent *inEvent, UInt64 inHostTime, Float32 inValue)
{
	BlueButter_UIView *SELF = (BlueButter_UIView *)inRefCon;
	[SELF priv_eventListener:inObject event: inEvent value: inValue];
}



@implementation BlueButter_UIView

-(void) awakeFromNib {
	NSRect rect = [imageView bounds];
	TTValue v(rect.size.width, rect.size.height);
	
	myAUPainter = NULL;
	TTObjectInstantiate(TT("MyAUPainter"), &myAUPainter, v);
}


/**********/

- (void)dealloc 
{
    [self priv_removeListeners];
		
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	// [mImageView release];
	TTObjectRelease(&myAUPainter);
    [super dealloc];
}


/**********/

#pragma mark ____ PUBLIC FUNCTIONS ____
- (void)setAU:(AudioUnit)inAU 
{
	// remove previous listeners
	if (mAU) 
		[self priv_removeListeners];
	
//	if (!mData)											// only allocate the data once
//		mData = malloc(kNumberOfResponseFrequencies * sizeof(FrequencyResponse));
	
//	mData = [graphView prepareDataForDrawing: mData];	// fill out the initial frequency values for the data displayed by the graph

	// register for resize notification and data changes for the graph view
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleGraphDataChanged:) name: @"fe" object: self];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleGraphSizeChanged:) name: NSViewFrameDidChangeNotification  object: self];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(beginGesture:) name: @"fi" object: self];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(endGesture:) name: @"fo" object: self];

	mAU = inAU;
    
	// add new listeners
	[self priv_addListeners];
	
	// initial setup
	[self priv_synchronizeUIWithParameterValues];
	
	// request a draw?
	[self setNeedsDisplay: YES];
}


// draw
- (void) makeButter
{
	TTValue				v;
	TTErr				err;
	NSBitmapImageRep*	bitmap = NULL;
	unsigned char*		bytes = NULL;
	int					width;
	int					height;
	int					stride;
	
	if (!myAUPainter)
		return;
	
	if (mImage) {
		[mImage release];
		mImage = NULL;
	}
		
	
	myAUPainter->setAttributeValue(TT("mode"), TT("arc"));
	
	err = myAUPainter->sendMessage(TT("paint"));
	err = myAUPainter->sendMessage(TT("getData"), v);
	if (!err) {
		bytes = (unsigned char*)TTPtr(v);
		v.get(1, width);
		v.get(2, height);
		v.get(3, stride);
		
		bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL 
														 pixelsWide:width 
														 pixelsHigh:height 
													  bitsPerSample:8 
													samplesPerPixel:4 
														   hasAlpha:YES 
														   isPlanar:NO 
													 colorSpaceName:NSDeviceRGBColorSpace
													   bitmapFormat:NSAlphaNonpremultipliedBitmapFormat
														bytesPerRow:stride 
													   bitsPerPixel:32];

		// NOW: WE COULD DO THIS:
		// Create an NSGraphicsContext that draws into the NSBitmapImageRep.  
		//(This capability is new in Tiger.)
		//NSGraphicsContext *nsContext = [NSGraphicsContext  
		//								graphicsContextWithBitmapImageRep:theBitMapToBeSaved];
		//
		// more on http://www.cocoabuilder.com/archive/message/cocoa/2005/5/18/136311
		
		// That might be better than what I'm about to do, which kinda sucks:
		for (int y=0; y<height; y++) {
			for (int x=0; x<width; x++) {
				int offset = (y * stride) + (x * 4);
				NSUInteger d[5];
								
				d[2] = bytes[offset+0];
				d[1] = bytes[offset+1];
				d[0] = bytes[offset+2];
				d[3] = bytes[offset+3];
				d[4] = 0;
				
				[bitmap setPixel:(NSUInteger*)d atX:x y:y];
			}
		}
		
		// USE THE FOLLOWING FOR DEBUGGING:
		{
			// NSData* data = [bitmap TIFFRepresentation];
			// [data writeToFile:@"/test.tiff" atomically:NO];
		}
		
		mImage = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
		[mImage addRepresentation:bitmap];
		
		[imageView setImage:mImage];
		[imageView setNeedsDisplay:YES];
	}
	[self setNeedsDisplay: YES];
}








#pragma mark ____ INTERFACE ACTIONS ____

//- (IBAction) cutoffFrequencyChanged:(id)sender 
//{
//	float floatValue = [sender floatValue];
//	AudioUnitParameter cutoffParameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
//	
//	NSAssert(	AUParameterSet(mAUEventListener, sender, &cutoffParameter, (Float32)floatValue, 0) == noErr,
//                @"[AppleDemoFilter_UIView cutoffFrequencyChanged:] AUParameterSet()");
//}


//- (IBAction) resonanceChanged:(id)sender 
//{
//	float floatValue = [sender floatValue];
//	AudioUnitParameter resonanceParameter = {mAU, kFilterParam_Resonance, kAudioUnitScope_Global, 0 };
//
//	NSAssert(	AUParameterSet(mAUEventListener, sender, &resonanceParameter, (Float32)floatValue, 0) == noErr,
//                @"[AppleDemoFilter_UIView resonanceChanged:] AUParameterSet()");
//}


- (void) handleGraphDataChanged:(NSNotification *) aNotification 
{
//	float resonance = [graphView getRes];
//	float cutoff	= [graphView getFreq];
	
//	AudioUnitParameter cutoffParameter		= {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
//	AudioUnitParameter resonanceParameter	= {mAU, kFilterParam_Resonance, kAudioUnitScope_Global, 0 };
	
//	NSAssert(	AUParameterSet(mAUEventListener, cutoffFrequencyField, &cutoffParameter, (Float32)cutoff, 0) == noErr,
  //              @"[AppleDemoFilter_UIView cutoffFrequencyChanged:] AUParameterSet()");
//
//	NSAssert(	AUParameterSet(mAUEventListener, resonanceField, &resonanceParameter, (Float32)resonance, 0) == noErr,
  //              @"[AppleDemoFilter_UIView resonanceChanged:] AUParameterSet()");
	// request a draw?
//	[self setNeedsDisplay: YES];
	[self makeButter];
}


- (void) handleGraphSizeChanged:(NSNotification *) aNotification 
{
//	mData = [graphView prepareDataForDrawing: mData];	// the size of the graph has changed so we need the graph to reconfigure the data frequencies that it needs to draw
	
	// get the curve data from the audio unit
//	UInt32 dataSize = kNumberOfResponseFrequencies * sizeof(FrequencyResponse);
//	ComponentResult result = AudioUnitGetProperty(	mAU,
//													kAudioUnitCustomProperty_FilterFrequencyResponse,
//													kAudioUnitScope_Global,
//													0,
//													mData,
//													&dataSize);

//	if (result == noErr)
//		[graphView plotData: mData];	// ask the graph view to plot the new data
//	else if (result == kAudioUnitErr_Uninitialized)
//		[graphView disableGraphCurve];
	// request a draw?
//	[self drawRect:mRect];
	[self makeButter];
}


- (void) beginGesture:(NSNotification *) aNotification 
{
	AudioUnitEvent event;
	AudioUnitParameter parameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
	event.mArgument.mParameter = parameter;
	event.mEventType = kAudioUnitEvent_BeginParameterChangeGesture;
	
	AUEventListenerNotify (mAUEventListener, self, &event);
		
	event.mArgument.mParameter.mParameterID = kFilterParam_Resonance;
	AUEventListenerNotify (mAUEventListener, self, &event);
}


- (void) endGesture:(NSNotification *) aNotification 
{
	AudioUnitEvent event;
	AudioUnitParameter parameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
	event.mArgument.mParameter = parameter;
	event.mEventType = kAudioUnitEvent_EndParameterChangeGesture;
	
	AUEventListenerNotify (mAUEventListener, self, &event);
	
	event.mArgument.mParameter.mParameterID = kFilterParam_Resonance;
	AUEventListenerNotify (mAUEventListener, self, &event);	
}


void addParamListener (AUEventListenerRef listener, void* refCon, AudioUnitEvent *inEvent)
{
	inEvent->mEventType = kAudioUnitEvent_BeginParameterChangeGesture;
	verify_noerr ( AUEventListenerAddEventType(	listener, refCon, inEvent));
	
	inEvent->mEventType = kAudioUnitEvent_EndParameterChangeGesture;
	verify_noerr ( AUEventListenerAddEventType(	listener, refCon, inEvent));
	
	inEvent->mEventType = kAudioUnitEvent_ParameterValueChange;
	verify_noerr ( AUEventListenerAddEventType(	listener, refCon, inEvent));	
}


#pragma mark ____ PRIVATE FUNCTIONS ____
- (void)priv_addListeners 
{
	if (mAU) {
		verify_noerr( AUEventListenerCreate(EventListenerDispatcher, self,
											CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 0.05, 0.05, 
											&mAUEventListener));
		
		AudioUnitEvent auEvent;
		AudioUnitParameter parameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
		auEvent.mArgument.mParameter = parameter;		
			
		addParamListener (mAUEventListener, self, &auEvent);
		
		auEvent.mArgument.mParameter.mParameterID = kFilterParam_Resonance;
		addParamListener (mAUEventListener, self, &auEvent);
		
		/* Add a listener for the changes in our custom property */
		/* The Audio unit will send a property change when the unit is intialized */		
		auEvent.mEventType = kAudioUnitEvent_PropertyChange;
		auEvent.mArgument.mProperty.mAudioUnit = mAU;
		auEvent.mArgument.mProperty.mPropertyID = kAudioUnitCustomProperty_FilterFrequencyResponse;
		auEvent.mArgument.mProperty.mScope = kAudioUnitScope_Global;
		auEvent.mArgument.mProperty.mElement = 0;		
		verify_noerr (AUEventListenerAddEventType (mAUEventListener, self, &auEvent));
	}
}

- (void)priv_removeListeners 
{
	if (mAUEventListener) verify_noerr (AUListenerDispose(mAUEventListener));
	mAUEventListener = NULL;
	mAU = NULL;
}


- (void) updateCurve 
{
	[self makeButter];
}


- (void)priv_synchronizeUIWithParameterValues 
{
	Float32 freqValue = 1234;
	//AudioUnitParameter parameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
	
	AudioUnitGetParameter(mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0, &freqValue);
	
	myAUPainter->setAttributeValue(TT("position"), freqValue/20000.0);
	[self updateCurve];
}


#pragma mark ____ LISTENER CALLBACK DISPATCHEE ____
// Handle kAudioUnitProperty_PresentPreset event
- (void)priv_eventListener:(void *) inObject event:(const AudioUnitEvent *)inEvent value:(Float32)inValue 
{
	[self setNeedsDisplay: YES];

	switch (inEvent->mEventType) {
		case kAudioUnitEvent_ParameterValueChange:					// Parameter Changes
			switch (inEvent->mArgument.mParameter.mParameterID) {
				case kFilterParam_CutoffFrequency:					// handle cutoff frequency parameter
					// kFilterParam_CutoffFrequency == kParam_One == 0
					myAUPainter->setAttributeValue(TT("position"), inValue/20000.0);					
					break;
				case kFilterParam_Resonance:						// handle resonance parameter
//					[resonanceField setFloatValue: inValue];		// update the resonance text field
//					[graphView setRes: inValue];					// update the graph's gain visual state
					break;					
			}
			// get the curve data from the audio unit
			[self updateCurve];
			break;
		case kAudioUnitEvent_BeginParameterChangeGesture:			// Begin gesture
//			[graphView handleBeginGesture];							// notify graph view to update visual state
			break;
		case kAudioUnitEvent_EndParameterChangeGesture:				// End gesture
//			[graphView handleEndGesture];							// notify graph view to update visual state
			break;
		case kAudioUnitEvent_PropertyChange:						// custom property changed
			if (inEvent->mArgument.mProperty.mPropertyID == kAudioUnitCustomProperty_FilterFrequencyResponse)
				[self updateCurve];
			break;
	}
}



#pragma mark -
#pragma mark mouse interaction

/* If we get a mouseDown, that means it was not in the graph view, or one of the text fields. 
   In this case, we should make the window the first responder. This will deselect our text fields if they are active. */
- (void) mouseDown: (NSEvent *) theEvent 
{
	NSPoint eventLocation = [theEvent locationInWindow];
	TTValue v(eventLocation.x, eventLocation.y);
	
	if (myAUPainter->sendMessage(TT("mouseDown"), v))
		[super mouseDown: theEvent];
	
	[[self window] makeFirstResponder: self];
}


- (void) mouseDragged: (NSEvent*) theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	TTValue v(eventLocation.x, eventLocation.y);
	Float32 freqValue;
	
	if (myAUPainter->sendMessage(TT("mouseDragged"), v))
		[super mouseDragged: theEvent];
	else{
		myAUPainter->getAttributeValue(TT("position"), v);
		freqValue = TTFloat32(v) * 20000.0;
		AudioUnitSetParameter(mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0, freqValue, 0);
		[self makeButter];
	}
}


- (void) mouseUp: (NSEvent*) theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	TTValue v(eventLocation.x, eventLocation.y);
	
	if (myAUPainter->sendMessage(TT("mouseUp"), v))
		[super mouseUp: theEvent];

	[[self window] makeFirstResponder: self];
}


- (void) mouseEntered: (NSEvent*) theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	TTValue v(eventLocation.x, eventLocation.y);
	
	if (myAUPainter->sendMessage(TT("mouseEntered"), v))
		[super mouseEntered: theEvent];

	[[self window] makeFirstResponder: self];
}


- (void) mouseExited: (NSEvent*) theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	TTValue v(eventLocation.x, eventLocation.y);
	
	if (myAUPainter->sendMessage(TT("mouseExited"), v))
		[super mouseExited: theEvent];

	[[self window] makeFirstResponder: self];
}


- (void) mouseMoved: (NSEvent*) theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	TTValue v(eventLocation.x, eventLocation.y);
	
	if (myAUPainter->sendMessage(TT("mouseMoved"), v))
		[super mouseMoved: theEvent];

	[[self window] makeFirstResponder: self];
}




#pragma mark -
#pragma mark flags

- (BOOL) acceptsFirstResponder 
{
	return YES;
}

- (BOOL) becomeFirstResponder 
{	
	return YES;
}

- (BOOL) isOpaque 
{
	return YES;
}

// inherited:
//- (BOOL) isFlipped
//{
//	return YES;
//}


// TODO: we might need to do this...
// setAcceptsMouseMovedEvents:


@end
