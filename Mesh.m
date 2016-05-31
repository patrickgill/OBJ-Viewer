#import "Mesh.h"


@implementation Mesh

- (id)init
{
    self = [super init];
    if (self) {
        faces = [[NSMutableData data] retain];
    }
    return self;
}

- (id)initWithMesh:(Mesh *)mesh
{
    self = [super init];
    if (self) {
        faces = [[NSMutableData dataWithCapacity:sizeof(Face)*[mesh numFaces]] retain];
        for (int i=0; i<[mesh numFaces]; i++) {
            Face *face = [mesh faceAtIndex:i];
            [self addFaceWithVertices:face->vertices material:face->material];
        }
    }
    return self;
}

- (Mesh *)copy
{
    return [[Mesh alloc] initWithMesh:self];
}

- (void)dealloc
{
    for (int i=0; i<[self numFaces]; i++) {
        [([self faceAtIndex:i]->material) release];
    }
    [faces release];
    
    [super dealloc];
}

- (Face*)addFaceWithVertices:(Vertex*)vertices material:(Material*)material
{
    Face face;
    face.vertices[0] = vertices[0];
    face.vertices[1] = vertices[1];
    face.vertices[2] = vertices[2];
    face.material = [material retain];
    
    [faces appendBytes:&face length:sizeof(Face)];
    
    return [self faceAtIndex:[self numFaces]-1];
}

- (int)numFaces
{
    return [faces length]/sizeof(Face);
}

- (Face*)faceAtIndex:(int)i
{
    Face *faceBuffer = (Face*)[faces bytes];
    return &faceBuffer[i];
}

@end

void ComputeFlatNormals(Face *face)
{
    Vector3D side1 = {
        face->vertices[1].point.x - face->vertices[0].point.x,
        face->vertices[1].point.y - face->vertices[0].point.y,
        face->vertices[1].point.z - face->vertices[0].point.z
    };
    Vector3D side2 = {
        face->vertices[2].point.x - face->vertices[0].point.x,
        face->vertices[2].point.y - face->vertices[0].point.y,
        face->vertices[2].point.z - face->vertices[0].point.z
    };
    Vector3D norm = {
        side1.y*side2.z - side2.y*side1.z,
        side1.z*side2.x - side2.z*side1.x,
        side1.x*side2.y - side2.x*side1.y
    };
    for (int j=0; j<3; j++) {
        face->vertices[j].normal = norm;
    }
}
