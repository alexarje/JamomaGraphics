/* 
 * TTGraphicsContext Object for Jamoma
 * Copyright © 2009 by Timothy Place
 * 
 * License: This code is licensed under the terms of the GNU LGPL
 * http://www.gnu.org/licenses/lgpl.html 
 */

#include "TTGraphicsContext.h"

#define thisTTClass			TTGraphicsContext
#define thisTTClassName		"TTGraphicsContext"
#define thisTTClassTags		"graphics"


TT_OBJECT_CONSTRUCTOR
{
	//	TTPtr surface = v;
	//	cairoRenderSurface = (cairo_surface_t*)TTPtr(v);
	//	cairoRenderSurface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 240, 80);
	//	cairoContext = cairo_create(cairoRenderSurface);
}


TTGraphicsContext::~TTGraphicsContext()
{
	// 1. Free the context
//	cairo_destroy (cairoContext);
	// we don't own the cairoContext, it is given to us by a higher power (e.g. the GraphicsWindow or some other entity)
	
	// 2. Free the surface
	// TODO: the TTGraphicsWindow owns the surface, so it should free it (or at least comment on why it isn't freeing it)
//	cairo_surface_destroy (cairoRenderSurface);
}





void TTGraphicsContext::selectFontFace(TTCString family, TTGraphicsFontSlant slant, TTGraphicsFontWeight weight)
{
	cairo_select_font_face(cairoContext, family, (cairo_font_slant_t)slant, (cairo_font_weight_t)weight);
}

void TTGraphicsContext::setFontSize(double size)
{
	cairo_set_font_size(cairoContext, size);
}

void TTGraphicsContext::setSourceRGB(double r, double g, double b)
{
	cairo_set_source_rgb(cairoContext, r, g, b);
}

void TTGraphicsContext::setSourceRGBA(double r, double g, double b, double a)
{
	cairo_set_source_rgba(cairoContext, r, g, b, a);
}

void TTGraphicsContext::moveTo(double x, double y)
{
	cairo_move_to(cairoContext, x, y);
}

void TTGraphicsContext::lineTo(double x, double y)
{
	cairo_line_to(cairoContext, x, y);
}

void TTGraphicsContext::showText(TTCString text)
{
	cairo_show_text(cairoContext, text);
}


void TTGraphicsContext::setLineWidth(double width)
{
	cairo_set_line_width(cairoContext, width);
}

void TTGraphicsContext::arc(double xc, double yc, double radius, double angle1, double angle2)
{
	cairo_arc(cairoContext, xc, yc, radius, angle1, angle2);
}

void TTGraphicsContext::stroke()
{
	cairo_stroke(cairoContext);
}

void TTGraphicsContext::fill()
{
	cairo_fill(cairoContext);
}

void TTGraphicsContext::clip()
{
	cairo_clip(cairoContext);
}

void TTGraphicsContext::newPath()
{
	cairo_new_path(cairoContext);
}

void TTGraphicsContext::rectangle(double x, double y, double width, double height)
{
	cairo_rectangle(cairoContext, x, y, width, height);
}





#pragma mark -
#pragma mark convenience functions


void TTGraphicsContext::setColor(TTGraphicsColor& color)
{
	setSourceRGBA(color.red, color.green, color.blue, color.alpha);
}


void TTGraphicsContext::filledCircle(TTFloat64 xc, TTFloat64 yc, TTFloat64 radius, TTFloat64 borderThickness, TTGraphicsColor& fillColor, TTGraphicsColor& borderColor)
{
	moveTo(xc, yc);
	setColor(borderColor);
	setLineWidth(borderThickness);
	arc(xc, yc, radius, 0, 2.0 * kTTPi);
	stroke();
	
	setColor(fillColor);
	arc(xc, yc, radius-(borderThickness*0.5), 0, 2.0 * kTTPi);
	fill();
}


void TTGraphicsContext::lineSegment(TTFloat64 x1, TTFloat64 y1, TTFloat64 x2, TTFloat64 y2, TTFloat64 width, TTGraphicsColor& color)
{
	setColor(color);
	setLineWidth(width);
	moveTo(x1, y1);
	lineTo(x2, y2);
	stroke();
}


