#import <Cocoa/Cocoa.h>


@interface Material : NSObject {
    NSString *name;
    NSColor *ambientColor;
    NSColor *diffuseColor;
    NSColor *specularColor;
    float specularExponent;
    float transparency;
}

- (id)initWithName:(NSString *)name;

@property(retain,readonly) NSString *name;
@property(retain) NSColor *ambientColor;
@property(retain) NSColor *diffuseColor;
@property(retain) NSColor *specularColor;
@property float specularExponent;
@property float transparency;

@end
