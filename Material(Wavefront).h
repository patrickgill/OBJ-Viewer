//
//  Material(Wavefront).h
//  OBJ_Viewer
//
//  Created by Tim Maxwell on 4/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Material.h"


@interface Material (Wavefront)

+ (NSDictionary*)materialsWithMTLData:(NSData*)data errors:(NSMutableArray*)errors;
+ (NSDictionary*)materialsWithMTLURL:(NSURL*)url errors:(NSMutableArray*)errors;

@end
