//
//  OBJViewerAppController.m
//  OBJ_Viewer
//
//  Created by Tim Maxwell on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBJViewerAppController.h"


@implementation OBJViewerAppController

- (void)awakeFromNib
{
	[displayModeControl setTarget:nil];
	[displayModeControl setAction:@selector(takeDisplayModeFrom:)];
	
	[displayModeControl bind:@"value"
					toObject:NSApp
				 withKeyPath:@"mainWindow.windowController.document.meshView.displayMode"
					 options:nil
	 ];
	
	/* I tried to use NSConditionallySetsEnabledBindingOption, but I couldn't get
	 it to work, so we have this instead. It relies on the fact that the
	 OBJViewerDisplayModeController will not display its current state when disabled. */
	
	[displayModeControl bind:@"enabled"
					toObject:NSApp
				 withKeyPath:@"mainWindow"
					 options:[NSDictionary dictionaryWithObject:NSIsNotNilTransformerName
														 forKey:NSValueTransformerNameBindingOption]
	 ];
							  
}

@end
