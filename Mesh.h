#import <Cocoa/Cocoa.h>
#import "Material.h"

typedef struct {
    double x;
    double y;
    double z;
} Point3D;

typedef struct {
    double x;
    double y;
} Point2D;

typedef struct {
    double x;
    double y;
    double z;
} Vector3D;

typedef struct {
	Point3D point;
	Point2D texcoord;
	Vector3D normal;
} Vertex;

typedef struct {
	Vertex vertices[3];
	Material *material;
} Face;

@interface Mesh : NSObject {
    /* 'faces' is a buffer which holds an array of Face structures. Basically,
     NSMutableData is being used as a convenient way to hold a resizeable
     buffer. */
    NSMutableData *faces;
}

- (id)init;
- (id)initWithMesh:(Mesh *)mesh;
- (Mesh *)copy;

- (Face*)addFaceWithVertices:(Vertex*)vertices material:(Material*)material;
- (int)numFaces;
- (Face*)faceAtIndex:(int)i;

@end

/* ComputeFlatNormals() re-computes the given face's normals, setting them to be
 perpendicular to the face itself. */
void ComputeFlatNormals(Face *f);