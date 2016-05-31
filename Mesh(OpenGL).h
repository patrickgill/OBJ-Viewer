#import <Cocoa/Cocoa.h>
#import "Mesh.h"


@interface Mesh (OpenGL)

/* Generate the appropriate OpenGL commands to render the mesh. */
- (void)renderInOpenGL;

/* Same as -renderInOpenGL, except that normals are flipped if necessary so that
 the given point is always on the same side of the face as the normal. This mode
 is useful if the normals from the mesh may be pointing in the wrong direction
 for some reason. If the mesh is closed and its normals always face outwards,
 this mode should not be necessary. */
- (void)renderInOpenGLWithNormalsFacing:(Point3D)cameraLoc;

@end
