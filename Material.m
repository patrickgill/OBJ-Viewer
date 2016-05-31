#import "Material.h"


@implementation Material

- (id)initWithName:(NSString *)_name
{
    self = [super init];
    if (self) {
        name = _name;
        [name retain];
        self.ambientColor = [NSColor grayColor];
        self.diffuseColor = [NSColor grayColor];
        self.specularColor = [NSColor blackColor];
        self.specularExponent = 50.0;
        self.transparency = 1.0;
    }
    return self;
}

@synthesize name;
@synthesize ambientColor, diffuseColor, specularColor;
@synthesize specularExponent, transparency;

@end
