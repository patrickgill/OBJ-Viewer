#import "Mesh(OpenGL).h"
#import "Material(OpenGL).h"
#import <OpenGL/gl.h>

@implementation Mesh (OpenGL)

- (void)renderInOpenGL
{
    Material *lastMaterial = nil;

    for (int i=0; i<[self numFaces]; i++) {
        Face *face = [self faceAtIndex:i];
        
        if (face->material != lastMaterial || i==0) {
            if (face->material) {
                [(face->material) prepareInOpenGL];
            } else {
                Material *defaultMaterial = [[Material alloc] initWithName:@"Default"];
                [defaultMaterial prepareInOpenGL];
                [defaultMaterial release];
            }
            lastMaterial = face->material;
        }
        
        glBegin(GL_TRIANGLES);
        for (int j=0; j<3; j++) {
            Vertex *vert = &face->vertices[j];
            glTexCoord2d(vert->texcoord.x, vert->texcoord.y);
            glNormal3d(vert->normal.x, vert->normal.y, vert->normal.z);
            glVertex3d(vert->point.x, vert->point.y, vert->point.z);
        }
        glEnd();
    }
}

- (void)renderInOpenGLWithNormalsFacing:(Point3D)cameraLoc
{
    Material *lastMaterial = nil;
        
    for (int i=0; i<[self numFaces]; i++) {
        Face *face = [self faceAtIndex:i];
        
        if (face->material != lastMaterial || i==0) {
            if (face->material) {
                [(face->material) prepareInOpenGL];
            } else {
                Material *defaultMaterial = [[Material alloc] initWithName:@"Default"];
                [defaultMaterial prepareInOpenGL];
                [defaultMaterial release];
            }
            lastMaterial = face->material;
        }
              
        glBegin(GL_TRIANGLES);
        for (int j=0; j<3; j++) {
            
            Vertex *vert = &face->vertices[j];
            
            glTexCoord2d(vert->texcoord.x, vert->texcoord.y);
            
            Vector3D cameraDir = {
                cameraLoc.x - vert->point.x,
                cameraLoc.y - vert->point.y,
                cameraLoc.z - vert->point.z
            };
            double dot =
                vert->normal.x*cameraDir.x +
                vert->normal.y*cameraDir.y +
                vert->normal.z*cameraDir.z;
            if (dot > 0) {
                glNormal3d(vert->normal.x, vert->normal.y, vert->normal.z);
            } else {
                glNormal3d(-vert->normal.x, -vert->normal.y, -vert->normal.z);
            }
            
            glVertex3d(vert->point.x, vert->point.y, vert->point.z);
        }
        glEnd();
    }
}

@end
