//
//  Mesh(Wavefront).h
//  OBJ_Viewer
//
//  Created by Tim Maxwell on 4/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Mesh.h"


@interface Mesh (Wavefront)

/* initWithOBJData:materialSearchDir:errors: tries to parse the given data block
 as a .OBJ file and initializes the mesh based on that.
 
 The second argument is the directory in which to search for .MTL files that are
 referred to via 'mtllib' directives in the .OBJ file.
 
 If any errors are encountered, they are appended to the given mutable array in
 the form of NSString objects. The parser is very tolerant; if you give it
 complete garbage, it will put a lot of error messages into 'errors' but still
 return a valid Mesh object. */
- (id)initWithOBJData:(NSData*)data materialSearchDir:(NSURL*)dir errors:(NSMutableArray*)errors;

/* initWithOBJFilename:errors: tries to open the given file path as a .OBJ file
 and initializes the mesh based on that. If the file does not exist, it will
 return nil.
 
 It is defined in terms of initWithOBJData:materialSearchDir:errors:, and its
 behavior is very similar. It chooses the directory that the .OBJ file is
 located as the material search dir to use. */
- (id)initWithOBJURL:(NSURL*)url errors:(NSMutableArray*) errors;

@end
