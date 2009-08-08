/* 
 * TTGraphics
 * Extension Class for TTBlue
 * Copyright © 2009, Timothy Place
 * 
 * License: This code is licensed under the terms of the GNU LGPL
 * http://www.gnu.org/licenses/lgpl.html 
 */

#include "TTFoundationAPI.h"
#include "TTGraphicsWindow.h"
#include "TTGraphicsContext.h"
#include "TTGraphicsSurface.h"


void TTGraphicsInit()
{
	TTFoundationInit();
	TTGraphicsWindow::registerClass();
	TTGraphicsContext::registerClass();
	TTGraphicsSurface::registerClass();	
}

