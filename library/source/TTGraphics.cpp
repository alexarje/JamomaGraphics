/* 
 * TTGraphics
 * Extension Class for TTBlue
 * Copyright © 2009, Timothy Place
 * 
 * License: This code is licensed under the terms of the GNU LGPL
 * http://www.gnu.org/licenses/lgpl.html 
 */

#include "TTFoundationAPI.h"
#include "TTGraphics.h"
#include "TTGraphicsWindow.h"
#include "TTGraphicsContext.h"
#include "TTGraphicsSurface.h"


static bool TTGraphicsHasInitialized = false;


void TTGraphicsInit()
{
	if(!TTGraphicsHasInitialized){
		TTGraphicsHasInitialized = true;

		TTFoundationInit();
		TTGraphicsWindow::registerClass();
		TTGraphicsContext::registerClass();
		TTGraphicsSurface::registerClass();	
		
#ifdef TT_DEBUG
		TTLogMessage("JamomaGraphics -- Version %s -- Debugging Enabled\n", TTGRAPHICS_VERSION_STRING);
#else
		TTLogMessage("JamomaGraphics -- Version %s\n", TTGRAPHICS_VERSION_STRING);
#endif
		
	}
}

