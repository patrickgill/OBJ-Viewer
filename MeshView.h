#import <Cocoa/Cocoa.h>
#import "Mesh.h"

enum MeshDisplayMode {
	MeshWireframe,
	MeshFlatNormals,
	MeshShaded
};

@interface MeshView : NSOpenGLView {
    
    /* 'mesh' is the mesh that we have been assigned to display. 'displayedMesh'
     is a modified version of it that may have normals flattened if the user
     requests it. 'displayedMesh' is derived from 'mesh'. */
    Mesh *mesh, *displayedMesh;
    
    float pitch, yaw, zoom;
    int displayMode;
}

- (void)setupCameraAngle;
- (void)setupViewport;
- (void)setupDrawMode;

/* invalidateDisplayedMesh is sent when 'displayMode' changes, so
 'displayedMesh' needs to be re-computed. Its effect is to free 'displayedMesh'
 and set it to nil. readyDisplayedMesh re-computes 'displayedMesh'. */
- (void)invalidateDisplayedMesh;
- (void)readyDisplayedMesh;

@property(retain) Mesh *mesh;
@property int displayMode;

@end
