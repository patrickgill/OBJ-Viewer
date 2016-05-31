#import "MeshView.h"
#import "Mesh(OpenGL).h"

#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@implementation MeshView

- (id)initWithFrame:(NSRect)frameRect
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 32,
        0
    };
    
    NSOpenGLPixelFormat* pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    
    self = [super initWithFrame:frameRect pixelFormat:[pixFmt autorelease]];
    
    if (self) {
        yaw = -30;
        pitch = 30;
		displayMode = MeshShaded;
    }
    
    return self;
}

- (void)dealloc
{
    [mesh release];
    [displayedMesh release];
    [super dealloc];
}

- (void)prepareOpenGL
{
    [self setupCameraAngle];
    [self setupViewport];
	[self setupDrawMode];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self readyDisplayedMesh];
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
    if (displayMode == MeshFlatNormals) {
        
        Point3D cameraLoc;
        cameraLoc.x = - zoom * sin(yaw*M_PI/180) * cos(pitch*M_PI/180);
        cameraLoc.y = zoom * sin(pitch*M_PI/180);
        cameraLoc.z = zoom * cos(yaw*M_PI/180) * cos(pitch*M_PI/180);
        
        [displayedMesh renderInOpenGLWithNormalsFacing: cameraLoc];
    }
    
    else {
        [displayedMesh renderInOpenGL];
    }
    
    [[self openGLContext] flushBuffer];
}

- (void)setupCameraAngle
{
    [[self openGLContext] makeCurrentContext];
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslated(0.0, 0.0, -zoom);
    glRotated(pitch, 1.0, 0.0, 0.0);
    glRotated(yaw, 0.0, 1.0, 0.0);
}

- (void)setupViewport
{
    [[self openGLContext] makeCurrentContext];
    [[self openGLContext] update];
    
    NSSize boundsSize = [self frame].size;
    glViewport(0, 0, boundsSize.width, boundsSize.height);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45, boundsSize.width/boundsSize.height, 1.0, zoom * 3);
}

- (void)setupDrawMode
{
	[[self openGLContext] makeCurrentContext];
	
	if (displayMode == MeshWireframe) {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        glEnable( GL_LINE_SMOOTH );
        glEnable( GL_POLYGON_SMOOTH );
        glHint( GL_LINE_SMOOTH_HINT, GL_NICEST );
        glHint( GL_POLYGON_SMOOTH_HINT, GL_NICEST );
		
        //glLineWidth(0.7);
        //glLineWidth(1.3);
        glLineWidth(1);
        
		//glClearColor(0.6, 0.6, 0.6, 1.0);
        glClearColor(1.0, 1.0, 1.0, 1.0); // white bg
		
		glDisable(GL_DEPTH_TEST);
		
		glDisable(GL_NORMALIZE);
		
		glDisable(GL_LIGHTING);
		
		glPolygonMode(GL_FRONT, GL_LINE);
		glPolygonMode(GL_BACK, GL_LINE);
		
		glColor3f(0.0, 0.0, 0.0);
    }
    else
    {
		glClearColor(0.2, 0.2, 0.2, 1.0);
		
		glEnable(GL_DEPTH_TEST);
		
		glEnable(GL_NORMALIZE);
		
		glEnable(GL_LIGHTING);
		glEnable(GL_LIGHT0);
		float position[4] = {0.2, 0.4, 0.4, 0.0};
		glLightfv(GL_LIGHT0, GL_POSITION, position);
		float lightcolor[4] = {1.0, 1.0, 1.0, 1.0};
		glLightfv(GL_LIGHT0, GL_AMBIENT_AND_DIFFUSE, lightcolor);
		glLightfv(GL_LIGHT0, GL_SPECULAR, lightcolor);
		
		glPolygonMode(GL_FRONT, GL_FILL);
		glPolygonMode(GL_BACK, GL_FILL);
		
		glColor3f(1.0, 1.0, 1.0);
	}
}

- (void)invalidateDisplayedMesh
{
    [displayedMesh release];
    displayedMesh = nil;
}

- (void)readyDisplayedMesh
{
    if (!displayedMesh) {
        if (displayMode == MeshFlatNormals) {
            displayedMesh = [mesh copy];
            for (int i=0; i<[displayedMesh numFaces]; i++) {
                Face *face = [displayedMesh faceAtIndex:i];
                ComputeFlatNormals(face);
            }
        } else {
            displayedMesh = [mesh retain];
        }
    }
}

- (void)mouseDragged:(NSEvent *)event
{
    if (([event modifierFlags] & NSControlKeyMask) || [event buttonNumber]==2) {
        zoom *= exp([event deltaY] / 50.0);
    }
    else {
        yaw += [event deltaX];
        pitch += [event deltaY];
        if (pitch < -90) pitch = -90;
        if (pitch > 90) pitch = 90;
    }
        
    [self setupCameraAngle];
    [self setupViewport];
    [self setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)event
{
    zoom *= exp(- [event deltaY] / 50.0);
    [self setupCameraAngle];
    [self setupViewport];
    [self setNeedsDisplay:YES];
}

- (void)reshape
{
    [self setupViewport];
    [super reshape];
}

- (void)update
{
    [self setupViewport];
    [super reshape];
}

- (void)setMesh:(Mesh *)newMesh
{
    [newMesh retain];
    [mesh release];
    mesh = newMesh;
    
    double maxRadius = 0.0;
    for (int i = 0; i < [mesh numFaces]; i++) {
        Face *f = [mesh faceAtIndex:i];
        for (int j = 0; j < 3; j++) {
            Vertex v = f->vertices[j];
            double radius = sqrt(v.point.x*v.point.x + v.point.y*v.point.y + v.point.z*v.point.z);
            if (radius > maxRadius) maxRadius = radius;
        }
    }
    
    zoom = maxRadius * 3;
    [self setupCameraAngle];

    [self invalidateDisplayedMesh];
    [self setNeedsDisplay:YES];
}

- (Mesh*)mesh {
    return mesh;
}

- (void)setDisplayMode:(int)dm
{
	displayMode = dm;
	[self invalidateDisplayedMesh];
	[self setupDrawMode];
	[self setNeedsDisplay:YES];
}

- (int)displayMode
{
    return displayMode;
}

@end
