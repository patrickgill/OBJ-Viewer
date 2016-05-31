#import "OBJViewerDocument.h"


@implementation OBJViewerDocument

- (void)dealloc
{
    [mesh release];
    [savedErrors release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    return @"OBJViewerDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    [super windowControllerDidLoadNib:windowController];
    
    [meshView bind:@"mesh" toObject:self withKeyPath:@"mesh" options:nil];
	
    [self presentSavedErrors];
}

- (BOOL)readFromURL:(NSURL*)URL ofType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableArray *errors = [NSMutableArray array];
    Mesh *newMesh = [[Mesh alloc] initWithOBJURL:URL errors:errors];
    
    if (newMesh) {
        self.mesh = [newMesh autorelease];
        
        if ([errors count] > 0) {
            [savedErrors release];
            savedErrors = [errors retain];
            if (meshView) [self presentSavedErrors];
        }
        
        return YES;
    }
    else {
        if (outError != NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"The given file could not be loaded.", NSLocalizedDescriptionKey,
                                      nil];
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:userInfo];
        }
        return NO;
    }
}

- (void)presentSavedErrors
{
    if (savedErrors) {
        
        if (!errorSheet) {
            [NSBundle loadNibNamed:@"ErrorSheet" owner:self];
        }
        
        [errorText setString:[savedErrors componentsJoinedByString:@"\n"]];
        [savedErrors release];
        savedErrors = nil;
        
        [[self windowForSheet] makeKeyAndOrderFront:self];
        
        [NSApp beginSheet:errorSheet
           modalForWindow:[self windowForSheet]
            modalDelegate:self
           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
              contextInfo:NULL];
    }
}

- (IBAction)dismissSavedErrors:(id)sender
{
    [NSApp endSheet:errorSheet];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

@synthesize mesh;

- (IBAction)takeDisplayModeFrom:(OBJViewerDisplayModeControl *)sender
{
	[meshView setDisplayMode:[sender value]];
}

@end
