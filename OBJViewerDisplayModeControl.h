//
//  OBJViewerDisplayModeControl.h
//  OBJ_Viewer
//
//  Created by Tim Maxwell on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/* OBJViewerDisplayModeControl provides an NSControl-like interface to a
 group of mutually exclusive menu items. Its `value` property is one of
 MeshWireframe, MeshFlatNormals, and MeshShaded. Create one in your
 MainMenu.nib and make it the target of the menu items.
 
 In theory it should be possible to bind its `value` to the thing you want
 to change, but in practice I couldn't get this to work. The `value`
 binding successfully reads from the object, but changes don't propagate
 back to the object. I worked around this by using a target/action
 mechanism instead. */

@interface OBJViewerDisplayModeControl : NSObject {

	int value;
	BOOL enabled;
	id target;
	SEL action;
}

@property int value;
- (IBAction)makeDisplayModeWireframe:(id)sender;
- (IBAction)makeDisplayModeFlatNormals:(id)sender;
- (IBAction)makeDisplayModeShaded:(id)sender;
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

/* When disabled, the OBJViewerDisplayModeControl will not display a check
 mark next to any menu item at all. This is kind of inconsistent. */
@property BOOL enabled;
- (BOOL)isEnabled;

@property(assign) id target;
@property SEL action;

@end
