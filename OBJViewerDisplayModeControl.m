//
//  OBJViewerDisplayModeControl.m
//  OBJ_Viewer
//
//  Created by Tim Maxwell on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBJViewerDisplayModeControl.h"
#import "MeshView.h"


@implementation OBJViewerDisplayModeControl

@synthesize value;

- (IBAction)makeDisplayModeWireframe:(id)sender
{
	[self setValue:MeshWireframe];
	[NSApp sendAction:action to:target from:self];
}

- (IBAction)makeDisplayModeFlatNormals:(id)sender
{
	[self setValue:MeshFlatNormals];
	[NSApp sendAction:action to:target from:self];
}

- (IBAction)makeDisplayModeShaded:(id)sender
{
	[self setValue:MeshShaded];
	[NSApp sendAction:action to:target from:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(makeDisplayModeWireframe:) ||
		[menuItem action] == @selector(makeDisplayModeFlatNormals:) ||
		[menuItem action] == @selector(makeDisplayModeShaded:)) {
		
		int menuItemMode;
		if ([menuItem action] == @selector(makeDisplayModeWireframe:)) {
			menuItemMode = MeshWireframe;
		} else if ([menuItem action] == @selector(makeDisplayModeFlatNormals:)) {
			menuItemMode = MeshFlatNormals;
		} else if ([menuItem action] == @selector(makeDisplayModeShaded:)) {
			menuItemMode = MeshShaded;
		}
		
		if (enabled) {
			if (menuItemMode == value) {
				[menuItem setState:NSOnState];
			} else {
				[menuItem setState:NSOffState];
			}
			return YES;
		}
		else {
			[menuItem setState:NSOffState];
			return NO;
		}
	}
	
	else {
		return YES;
	}
}

@synthesize enabled;
- (BOOL)isEnabled
{
	return [self enabled];
}

@synthesize target;
@synthesize action;

@end
