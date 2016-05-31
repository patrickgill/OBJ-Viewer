//
//  OBJViewerAppController.h
//  OBJ_Viewer
//
//  Created by Tim Maxwell on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OBJViewerDisplayModeControl.h"


/* One of these is instantiated in MainMenu.nib. It mostly exists to hook up
 the OBJViewerDisplayModeControl properly. */

@interface OBJViewerAppController : NSObject {
	IBOutlet OBJViewerDisplayModeControl *displayModeControl;
}

@end
