//
//  Material(Wavefront).m
//  OBJ_Viewer
//
//  Created by Tim Maxwell on 4/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Material(Wavefront).h"
#import "NSScanner(OBJExtras).h"


@implementation Material (Wavefront)

+ (NSDictionary*)materialsWithMTLData:(NSData *)data errors:(NSMutableArray*)errors
{
    /* Allocate space to hold the materials as we make them */
    
    NSMutableDictionary *materials = [NSMutableDictionary dictionary];
    Material *currentMaterial = nil;
    
    /* Break the data block into lines */
    
    NSString *wholeString = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
    NSScanner *fileScanner = [NSScanner scannerWithString:wholeString];
    __block int lineNumber = 0; // Declared as __block so that when lineNumber changes, ReportError sees the change
    
    /* ReportError() and ReportIncompatibility() are closures that are used for
     reporting errors in the .OBJ file, and for reporting if the .OBJ file uses
     features of the .OBJ standard that this code does not support. */
    
    void (^ReportError)(NSString *) = ^(NSString *msg) {
        if (errors) {
            [errors addObject:[NSString stringWithFormat:@"Line %d: %@", lineNumber, msg]];
        }
    };
    
    void (^ReportIncompatibility)(NSString *, BOOL) = ^(NSString *msg, BOOL allowDups) {
        if (errors) {
            NSString *msg2 = [NSString stringWithFormat:@"Warning: %@", msg];
            if (allowDups || ![errors containsObject:msg2]) {
                [errors addObject:msg2];
            }
        }
    };
    
    /* ScanColorOrOther() is a closure that reads an RGB color from a NSScanner
     object. If it encounters "spectral ..." or "xyz ...", then it generates
     appropriate calls to ReportIncompatibility(). It also generates calls to
     ReportError() when necessary. */
    BOOL (^ScanColorOrOther)(NSScanner *, NSColor **) = ^(NSScanner *scanner, NSColor **color) {
                
        if ([scanner scanString:@"spectral" intoString:NULL]) {
            
            ReportIncompatibility(@"This .MTL file uses spectral curves, which "
                                  @"this program does not support. They will "
                                  @"be ignored, but the materials may not be "
                                  @"displayed correctly.", FALSE);
            return NO;
            
        } else if ([scanner scanString:@"xyz" intoString:NULL]) {
            
            ReportIncompatibility(@"This .MTL file specifies a color in the "
                                  @"XYZ color space, and I'm too lazy to add "
                                  @"color conversion routines. The commands "
                                  @"which use the XYZ color space will be "
                                  @"ignored.", FALSE);
            return NO;
            
        } else {
            
            double r,g,b;
            if ([scanner scanDouble:&r] &&
                [scanner scanDouble:&g] &&
                [scanner scanDouble:&b] &&
                [scanner isAtEnd]) {
                
                *color = [NSColor colorWithCalibratedRed:r
                                                   green:g
                                                    blue:b
                                                   alpha:1.0];
                return YES;
                
            } else {
                
                ReportError(@"Colors should be specified as three numbers.");
                return NO;
            }
        }
    };
    
    NSString *line;
    while ([fileScanner scanUpToString:@"\n" intoString:&line])
    {
        lineNumber ++;
                
        /* Strip out comments */
        line = [[line componentsSeparatedByString:@"#"] objectAtIndex:0];
        
        NSScanner *lineScanner = [NSScanner scannerWithString:line];
        
        NSString *directive;
        if (![lineScanner scanWord:&directive]) {
            continue;
        }
        
        if ([directive isEqualToString:@"newmtl"]) {
            
            NSString *name;
            
            if (![lineScanner scanWord:&name]) {
                ReportError(@"'newmtl' directive needs a name");
                currentMaterial = nil;
                continue;
            }
            
            if ([materials objectForKey:name]) {
                ReportError([NSString stringWithFormat:@"There is already a material called '%@'", name]);
            }
            
            currentMaterial = [[Material alloc] initWithName:name];
            [materials setObject:[currentMaterial autorelease] forKey:name];
        
        } else {
            
            if (!currentMaterial) {
                ReportError(@"All directives except for 'newmtl' must come "
                            @"after a valid 'newmtl' directive.");
                continue;
            }
            
            if ([directive isEqualToString:@"Ka"]) {
            
                NSColor *color;
                if (!ScanColorOrOther(lineScanner, &color)) continue;
                [currentMaterial setAmbientColor:color];
        
            } else if ([directive isEqualToString:@"Kd"]) {
                
                NSColor *color;
                if (!ScanColorOrOther(lineScanner, &color)) continue;
                [currentMaterial setDiffuseColor:color];
            
            } else if ([directive isEqualToString:@"Ks"]) {
                
                NSColor *color;
                if (!ScanColorOrOther(lineScanner, &color)) continue;
                [currentMaterial setSpecularColor:color];
            
            } else if ([directive isEqualToString:@"Tf"]) {
                
                ReportIncompatibility(@"This .MTL file uses the 'Tf' directive "
                                      @"to specify a transmission filter. This "
                                      @"program doesn't support transmission "
                                      @"filters, so it will be ignored.", FALSE);
            
            } else if ([directive isEqualToString:@"illum"]) {
                
                int illum;
                if (![lineScanner scanInt:&illum] || ![lineScanner isAtEnd]) {
                    ReportError(@"'illum' directive expets 1 integer");
                    continue;
                }
                
                switch(illum) {
                        
                    case 1:
                        /* This is hacky, because if the 'illum' directive
                         precedes an 'Ks' directive, the 'Ks' directive will
                         overwrite the 'illum' directive. That behavior is not
                         what is specified by the .MTL standard. Still, I think
                         that is acceptable because it's not a very common use
                         case. */
                        [currentMaterial setSpecularColor:[NSColor blackColor]];
                        break;
                        
                    case 2: case 3:
                        /* There are subtle differences between illumination
                         model 2 and illumination model 3. I'm too lazy to
                         figure out which one OpenGL is using. For now, just
                         treat them as the same. */
                        break;
                        
                    default:
                        ReportIncompatibility([NSString stringWithFormat:
                                               @"Illumination model #%d is not "
                                               @"supported by this program.",
                                               illum], FALSE);
                        break;
                }
            
            } else if ([directive isEqualToString:@"Tr"] || [directive isEqualToString:@"d"]) {
                
                /* The .MTL standard uses the keyword 'd', but some other
                 programs use 'Tr'. We support both. */
                
                if ([lineScanner scanString:@"-halo" intoString:NULL]) {
                    ReportIncompatibility(@"The 'd -halo' directive is not "
                                          @"supported.", FALSE);
                }
                    
                double alpha;
                if (![lineScanner scanDouble:&alpha] || ![lineScanner isAtEnd]) {
                    ReportError(@"'Tr'/'d' directive expects 1 number");
                    continue;
                }
                
                [currentMaterial setTransparency:alpha];
                
            } else if ([directive isEqualToString:@"Ns"]) {
                
                double specularExponent;
                if (![lineScanner scanDouble:&specularExponent] || ![lineScanner isAtEnd]) {
                    ReportError(@"'Ns' directive expects 1 number");
                    continue;
                }
                
                [currentMaterial setSpecularExponent:specularExponent];
            
            } else if ([directive isEqualToString:@"Ni"]) {
                
                /* This is supposed to specify optical density. We don't support
                 refraction, so I guess it's safe to ignore this. */
                
            } else if ([directive isEqualToString:@"map_Ka"]) {
                
                ReportIncompatibility(@"Sorry, no texture support yet.", FALSE);
                
            } else if ([directive isEqualToString:@"map_Kd"]) {
            
                ReportIncompatibility(@"Sorry, no texture support yet.", FALSE);
            
            } else if ([directive isEqualToString:@"map_Ks"]) {
            
                ReportIncompatibility(@"Sorry, no texture support yet.", FALSE);
            
            } else if ([directive isEqualToString:@"map_d"]) {
            
                ReportIncompatibility(@"Sorry, no texture support yet.", FALSE);
            
            } else if ([directive isEqualToString:@"map_bump"] || [directive isEqualToString:@"bump"]) {
            
                ReportIncompatibility(@"Sorry, no bump map support yet.", FALSE);
            
            /* TODO: Provide plausible handlers for all of the other material
             commands. See <http://www.fileformat.info/format/material/>. */
                
            } else {
                
                ReportError([NSString stringWithFormat:@"Unknown directive '%@'", directive]);
            }
        }
    }
    
    return materials;
}

+ (NSDictionary*)materialsWithMTLURL:(NSURL*)url errors:(NSMutableArray*)errors
{
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (!data) {
        if (error) [errors addObject:[error localizedDescription]];
        else [errors addObject:[NSString stringWithFormat:@"Could not open '%@'", url]];
        return nil;
    }
    
    return [Material materialsWithMTLData:data errors:errors];
}

@end
