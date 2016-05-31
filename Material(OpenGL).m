#import "Material(OpenGL).h"
#import <OpenGL/gl.h>

@implementation Material (OpenGL)

- (void)prepareInOpenGL
{
    NSColor *ac = [ambientColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    float ambient[4] = {
        [ac redComponent],
        [ac greenComponent],
        [ac blueComponent],
        1.0};
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, ambient);
    
    NSColor *dc = [diffuseColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    float diffuse[4] = {
        [dc redComponent],
        [dc greenComponent],
        [dc blueComponent],
        transparency};
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, diffuse);
    
    NSColor *sc = [specularColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    float specular[4] = {
        [sc redComponent],
        [sc greenComponent],
        [sc blueComponent],
        1.0};
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specular);
    
    glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, specularExponent);
}

@end
