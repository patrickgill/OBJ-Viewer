#import <Cocoa/Cocoa.h>

#import "Mesh.h"
#import "Mesh(Wavefront).h"
#import "MeshView.h"
#import "OBJViewerDisplayModeControl.h"


@interface OBJViewerDocument : NSDocument
{
    Mesh *mesh;
    
    IBOutlet MeshView *meshView;
    IBOutlet NSWindow *errorSheet;
    IBOutlet NSTextView *errorText;
    
    NSArray *savedErrors;
}

@property(retain) Mesh *mesh;

- (void)presentSavedErrors;
- (IBAction)dismissSavedErrors:(id)sender;

- (IBAction)takeDisplayModeFrom:(OBJViewerDisplayModeControl *)sender;

@end
