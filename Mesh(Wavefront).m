//
//  Mesh(Wavefront).m
//  OBJ_Viewer
//
//  Created by Tim Maxwell on 4/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Mesh(Wavefront).h"
#import "Material(Wavefront).h"
#import "NSScanner(OBJExtras).h"



/* PerformLookup() is a convenience function for working with the .OBJ file
 format. In the .OBJ file format, vertices, texture coordinates, and surface
 normals are referred to as indices into buffers. The PerformLookup() function
 checks the validity of the given index and tries to extract the appropriate
 information from a buffer.
 
 'array' is a NSData block of some number of objects of size 'size'. 'index' is
 the index to extract. If the index is valid, then a pointer to somewhere in
 'array' is returned. If the index is not valid, then NULL is returned. */
static void *PerformLookup(NSMutableData *array, int size, int index)
{
    int realIndex;
    
    if (index > 0) realIndex = index - 1; // .OBJ indices start from 1
    else if (index < 0) realIndex = [array length]/size + index; // Negative indices mean 'count backwards'
    else if (index == 0) return NULL; // 0 is never a valid index
    
    if (realIndex < 0 || realIndex >= [array length]/size) return NULL;
    return (void*)((unsigned char*)[array bytes] + realIndex*size);
}

@implementation Mesh (Wavefront)

- (id)initWithOBJData:(NSData *)data materialSearchDir:(NSURL *)materialSearchDir errors:(NSMutableArray*)errors
{
    self = [self init];
    if (!self) return nil;
    
    /* Allocate buffers to hold the points, texcoords, and normals */
    
    NSMutableData *points = [NSMutableData data]; // buffer of Point3D
    NSMutableData *texcoords = [NSMutableData data]; // buffer of Point2D
    NSMutableData *normals = [NSMutableData data]; // buffer of Vector3D
    
    /* Holds all the materials that we know about at the moment */
    NSMutableDictionary *materials = [NSMutableDictionary dictionary];
    
    /* Holds the material currently in use */
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
    
    /* Process the lines one by one */
    
    NSString *line;
    while ([fileScanner scanUpToString:@"\n" intoString:&line]) {
        lineNumber ++;
        
        /* Strip out comments */
        line = [[line componentsSeparatedByString:@"#"] objectAtIndex:0];
        
        NSScanner *lineScanner = [NSScanner scannerWithString:line];
        
        NSString *directive;
        if (![lineScanner scanWord:&directive]) {
            continue;
        }
        
        if ([directive isEqualToString:@"v"]) {
            
            Point3D pt;
            
            BOOL xyzOk = ([lineScanner scanDouble:&pt.x] && 
                          [lineScanner scanDouble:&pt.y] &&
                          [lineScanner scanDouble:&pt.z]);
            
            /* The .OBJ standard allows a 'w' coordinate in the vertex. It's
             only used for free-form geometry, which we don't support, so we can
             safely ignore it. If no 'w' coordinate is present, this command
             will harmlessly return NO. */
            [lineScanner scanDouble:NULL];
            
            if (!xyzOk || ![lineScanner isAtEnd]) {
                ReportError(@"The 'v' directive should be followed by 3 "
                            @"numbers.");
                continue;
            }
            
            [points appendBytes:&pt length:sizeof(Point3D)];
        
        } else if ([directive isEqualToString:@"vt"]) {
            
            /* This is complicated because the .OBJ standard permits three-
             dimensional and one-dimensional textures. To keep it (relatively)
             simple, we don't support them, but we can still parse the file. */
            
            Point2D tc;
            if ([lineScanner scanDouble:&tc.x]) {
                
                if ([lineScanner scanDouble:&tc.y]) {
                    
                    if ([lineScanner scanDouble:NULL]) {
                        
                        NSString *msg = (@"This OBJ file specifies texture "
                                         @"coordinates in 3 dimensions. Since "
                                         @"this program does not support 3D "
                                         @"textures, the 3rd coordinate will "
                                         @"be ignored.");
                        ReportIncompatibility(msg, FALSE);
                        
                        [texcoords appendBytes:&tc length:sizeof(Point2D)];
                    
                    } else if ([lineScanner isAtEnd]) {
                        
                        [texcoords appendBytes:&tc length:sizeof(Point2D)];
                    
                    } else {
                        
                        ReportError(@"The 'vt' directive expects 2 numbers.");
                    }
                
                } else if ([lineScanner isAtEnd]) {
                    
                    tc.y = 0.0;
                    [texcoords appendBytes:&tc length:sizeof(Point2D)];
                
                } else {
                    
                    ReportError(@"The 'vt' directive expects 2 numbers.");
                }
            
            } else {
                
                ReportError(@"The 'vt' directive expects 2 numbers.");
            }
        
        } else if ([directive isEqualToString:@"vn"]) {
            
            Vector3D n;
            if (![lineScanner scanDouble:&n.x] ||
                ![lineScanner scanDouble:&n.y] ||
                ![lineScanner scanDouble:&n.z] ||
                ![lineScanner isAtEnd]) {
                ReportError(@"'vn' directive requires 3 numbers");
                continue;
            }
            [normals appendBytes:&n length:sizeof(Vector3D)];
        
        } else if ([directive isEqualToString:@"vp"] ||
                   [directive isEqualToString:@"cstype"] ||
                   [directive isEqualToString:@"deg"] ||
                   [directive isEqualToString:@"bmat"] ||
                   [directive isEqualToString:@"step"]) {
            
            /* Do nothing.
             
             These directives are related to displaying curved surfaces, but
             they don't do anything on their own, so we can safely ignore them.
             If we encounter a directive that actually creates a curve, we will
             call ReportIncompatibility(). */
        
        } else if ([directive isEqualToString:@"p"] ||
                   [directive isEqualToString:@"l"]) {
            
            /* We don't (and probably never will) support individual points
             and lines that are visible not as part of a face. */
            ReportIncompatibility(@"This .OBJ file contains 'p' and/or 'l' "
                                  @"directives, which create points and lines "
                                  @"independent of faces. This program has no "
                                  @"support for independent points and lines, "
                                  @"so they will be ignored.", FALSE);
            
        } else if ([directive isEqualToString:@"f"]) {
            
            NSMutableData *vertices = [NSMutableData data];
            
            /* Keep track of whether normals have been specified for every
             vertex of the face.
             
             According to the .OBJ standard, normals must be
             specified for either none of the vertices or all of them, but there
             is no point in enforcing this. */
            BOOL haveNormals = TRUE;
            
            NSString *vertexStr;
            while ([lineScanner scanWord:&vertexStr]) {
                
                NSScanner *vertexScanner  = [NSScanner scannerWithString:vertexStr];
                int index;
                Vertex vertex;
                
                /* The vertex descriptions that we are now scanning can take a
                 number of different forms:
                    "pointIndex/texcoordIndex/normalIndex"
                    "pointIndex/texcoordIndex/"
                    "pointIndex/texcoordIndex"
                    "pointIndex//normalIndex"
                    "pointIndex//"
                    "pointIndex/"
                    "pointIndex"
                 The parser must handle all of them. The official .OBJ format
                 standard does not permit all of these forms, but many programs
                 go beyond the official standard, so we must support them. */
                
                if ([vertexScanner  scanInt:&index]) {
                    
                    Point3D *pointPtr = PerformLookup(points, sizeof(Point3D), index);
                    if (!pointPtr) {
                        ReportError(@"Point reference number is invalid.");
                        continue; // Impossible to recover
                    }
                    vertex.point = *pointPtr;
                    
                    if ([vertexScanner  scanString:@"/" intoString:NULL]) {
                        
                        if ([vertexScanner scanInt:&index]) {
                            
                            Point2D *texcoordPtr = PerformLookup(texcoords, sizeof(Point2D), index);
                            
                            if (!texcoordPtr) {
                                
                                ReportError(@"Tex-coord reference number is invalid.");
                                
                                // This is illegal, but nonfatal.
                                vertex.texcoord.x = vertex.texcoord.y = 0.0;
                                
                            } else {
                                vertex.texcoord = *texcoordPtr;
                            }
                            
                        } else {
                            // Texcoords are optional
                            vertex.texcoord.x = vertex.texcoord.y = 0.0;
                        }

                        if ([vertexScanner  scanString:@"/" intoString:NULL]) {
                            
                            if ([vertexScanner  scanInt:&index]) {
                                
                                Vector3D *normalPtr = PerformLookup(normals, sizeof(Vector3D), index);
                                
                                if (!normalPtr) {
                                    
                                    ReportError(@"Normal reference number is invalid.");
                                    
                                    // This is illegal, but nonfatal.
                                    vertex.normal.x = vertex.normal.y = vertex.normal.z = 0.0;
                                    haveNormals = NO;
                                    
                                } else {
                                    vertex.normal = *normalPtr;
                                }
                            
                            } else {
                                // Normals are optional
                                vertex.normal.x = vertex.normal.y = vertex.normal.z = 0.0;
                                haveNormals = NO;
                            }
                            
                        } else {
                            // Normals are optional
                            vertex.normal.x = vertex.normal.y = vertex.normal.z = 0.0;
                            haveNormals = NO;
                        }

                    } else {
                        // Here we have just a bare point index, with no texture
                        // or normal information.
                        vertex.texcoord.x = vertex.texcoord.y = 0.0;
                        vertex.normal.x = vertex.normal.y = vertex.normal.z = 0.0;
                        haveNormals = NO;
                    }
                    
                } else {
                    ReportError(@"Parse error in vertex.");
                    continue;
                }
                
                if (![vertexScanner isAtEnd]) {
                    ReportError(@"Parse error in vertex.");
                    continue;
                }
                
                [vertices appendBytes:&vertex length:sizeof(Vertex)];
            }
            
            if ([vertices length]/sizeof(Vertex) < 3) {
                ReportError(@"Face needs at least 3 vertices.");
                continue;
            }
            
            /* The Mesh type only holds faces with three vertices, but the .OBJ
             file format allows any number of vertices, so we tesselate. */
            const Vertex *verticesBuffer = [vertices bytes];
            int i;
            for (i = 1; i+1 < [vertices length]/sizeof(Vertex); i++)
            {
                Vertex vertices[3] = {
                    verticesBuffer[0],
                    verticesBuffer[i],
                    verticesBuffer[i+1]
                };
                Face *face = [self addFaceWithVertices:vertices material:currentMaterial];
                
                /* If normals were not specified for the face, then we compute
                 plausible ones. */
                if (!haveNormals)
                    ComputeFlatNormals(face);
            }
        
        } else if ([directive isEqualToString:@"curv"] ||
                   [directive isEqualToString:@"curv2"] ||
                   [directive isEqualToString:@"surf"]) {
            
            ReportIncompatibility(@"This .OBJ file includes free-form "
                                  @"geometry object(s) of the type 'curv', "
                                  @"'curv2', or 'surf'. Since this program "
                                  @"does not support free-form geometry, the "
                                  @"instruction will be ignored. The file may "
                                  @"not be displayed correctly.", FALSE);
            
        } else if ([directive isEqualToString:@"parm"] ||
                   [directive isEqualToString:@"trim"] ||
                   [directive isEqualToString:@"hole"] ||
                   [directive isEqualToString:@"scrv"] ||
                   [directive isEqualToString:@"sp"] ||
                   [directive isEqualToString:@"end"] ||
                   [directive isEqualToString:@"con"]) {
            
            /* These directives are used to extend or modify curved objects
             created with 'curv', 'curv2', or 'surf'. Since we already displayed
             a warning when the free-form geometry was first encountered, we
             can safely ignore these commands. */
        
        } else if ([directive isEqualToString:@"g"]) {
            
            /* Ignore group names */
            
        } else if ([directive isEqualToString:@"s"]) {
            
            BOOL doSmooth;
            if ([lineScanner scanString:@"off" intoString:NULL]) {
                doSmooth = NO;
            } else {
                int smoothingGroup;
                if ([lineScanner scanInt:&smoothingGroup]) {
                    doSmooth = (smoothingGroup != 0);
                } else {
                    ReportError(@"'s' directive expects 'off' or one integer");
                    continue;
                }
                
            }
            if (![lineScanner isAtEnd]) {
                ReportError(@"'s' directive expects 'off' or one integer");
                continue;
            }
            
            if (doSmooth) {
                ReportIncompatibility(@"This .OBJ file contains 's' "
                                      @"directives for generating smooth "
                                      @"normals. This software doesn't support "
                                      @"the 's' directive, so flat normals "
                                      @"will be used instead.", FALSE);
            } 
        
        } else if ([directive isEqualToString:@"mg"]) {
            
            /* Merging groups are only valid for curved objects, which we don't
             care about anyway. So, ignore them. */
            
        } else if ([directive isEqualToString:@"o"]) {
            
            /* Ignore object names */
        
        } else if ([directive isEqualToString:@"bevel"]) {
            
            /* We don't support bevel interpolation. Interpret it as a command
             to enable flat-shading. */
            BOOL bevelInterpolation;
            if (![lineScanner scanOnOrOff:&bevelInterpolation] || ![lineScanner isAtEnd]) {
                ReportError(@"'bevel' expects 'on' or 'off'");
                continue;
            }
            if (bevelInterpolation) {
                ReportIncompatibility(@"This .OBJ file uses bevel shading via "
                                      @"the 'bevel' directive. This program "
                                      @"does not support the 'bevel' "
                                      @"directive, so it will be ignored.",
                                      FALSE);
            }
        
        } else if ([directive isEqualToString:@"c_interp"]) {
            
            /* We don't support color interpolation. */
            BOOL colorInterpolation;
            if (![lineScanner scanOnOrOff:&colorInterpolation] || ![lineScanner isAtEnd]) {
                ReportError(@"'c_interp' expects 'on' or 'off'");
                continue;
            }
            if (colorInterpolation) {
                ReportIncompatibility(@"This .OBJ file uses color "
                                      @"interpolation via the 'c_interp' "
                                      @"directive. This program does not "
                                      @"support the 'c_interp' directive, so "
                                      @"it will be ignored.", FALSE);
            }
        
        } else if ([directive isEqualToString:@"d_interp"]) {
            
            /* We don't support dissolve interpolation. */
            BOOL dissolveInterpolation;
            if (![lineScanner scanOnOrOff:&dissolveInterpolation] || ![lineScanner isAtEnd]) {
                ReportError(@"'d_interp' expects 'on' or 'off'");
                continue;
            }
            if (dissolveInterpolation) {
                ReportIncompatibility(@"This .OBJ file uses transparency "
                                      @"interpolation via the 'd_interp' "
                                      @"directive. This program does not "
                                      @"support the 'd_interp' directive, so "
                                      @"it will be ignored.", FALSE);
            }
        
        } else if ([directive isEqualToString:@"lod"]) {

            int levelOfDetail;
            if (![lineScanner scanInt:&levelOfDetail] || ![lineScanner isAtEnd]) {
                ReportError(@"'lod' expects an integer");
                continue;
            }
            /* I don't know exactly what the 'lod' directive does, but I think
             it can be safely ignored. */
            
        } else if ([directive isEqualToString:@"maplib"]) {
            
            /* There's no support for 'maplib' at the moment, because every user
             I've ever seen used 'mtllib' instead. It seems pretty easy to add,
             though, so maybe I should add support later.
             
             As of 2010-04-13, there's no support for textures via 'mtllib'
             either, so we just display that message. */
            ReportIncompatibility(@"There's no support for textures.", FALSE);
        
        } else if ([directive isEqualToString:@"usemap"]) {
            
            ReportIncompatibility(@"There's no support for textures.", FALSE);
            
        } else if ([directive isEqualToString:@"usemtl"]) {
            
            NSString *name;
            if (![lineScanner scanWord:&name]) {
                ReportError(@"The 'usemtl' directive expects a name");
                currentMaterial = nil;
                continue;
            }
            
            currentMaterial = [materials objectForKey:name];
            
            if (!currentMaterial) {
                ReportError([NSString stringWithFormat:@"Undefined material '%@'", name]);
            }
            
        } else if ([directive isEqualToString:@"mtllib"]) {
            
            NSString *filename;
            while ([lineScanner scanWord:&filename]) {
            
                NSURL *fullPath = [NSURL URLWithString:filename relativeToURL:materialSearchDir];
                if (!fullPath) {
                    ReportError(@"material filename is malformed");
                    continue;
                }
                
                // Collect errors from the material file in a new array
                NSMutableArray *materialErrors = [NSMutableArray array];
                
                NSDictionary *newMaterials = [Material materialsWithMTLURL:fullPath errors:materialErrors];
                
                if (newMaterials) {
                    /* The .OBJ standard specifies that libraries must be
                     searched for materials in the same order that they are
                     specified. The easiest way to do this is to just merge the
                     dictionaries, preferring entries from the existing
                     dictionaries when there is a name conflict. */
                    NSMutableDictionary *combination = [NSMutableDictionary dictionaryWithDictionary:newMaterials];
                    [combination addEntriesFromDictionary:materials];
                    materials = combination;
                }
                
                /* Report the errors from the material file, attaching the name
                 of the material file to the beginning of each one. We don't
                 use ReportError or ReportIncompatibility because we don't want
                 to stick the 'Line %d:' or 'Warning:' label onto the beginning;
                 the MTL file parser has already added those. */
                if (errors) {
                    for (int i=0; i<[materialErrors count]; i++) {
                        NSString *msg = [NSString stringWithFormat:@"%@: %@",
                                         [fullPath absoluteString],
                                         [materialErrors objectAtIndex:i]];
                        [errors addObject:msg];
                    }
                }
            }
        
        } else if ([directive isEqualToString:@"shadow_obj"]) {
            
            /* Ignore this but don't show a warning. */
        
        } else if ([directive isEqualToString:@"trace_obj"]) {
            
            /* This is only used if we're ray-tracing. Which we aren't. */
            
        } else if ([directive isEqualToString:@"ctech"] ||
                   [directive isEqualToString:@"stech"]) {
            
            /* These affect how free-form geometry is rendered, so we can
             ignore them. */
            
        } else if ([directive isEqualToString:@"call"]) {
            
            NSString *targetFile;
            if ([lineScanner scanWord:&targetFile]) {
                ReportIncompatibility([NSString stringWithFormat: @"On line "
                                       @"%d, this OBJ file invokes the file "
                                       @"'%@' via the 'call' directive. This "
                                       @"program does not support the 'call' "
                                       @"directive, so the file may not be "
                                       @"displayed properly.", lineNumber,
                                       targetFile], TRUE);
            } else {
                ReportError(@"The 'call' directive must be followed by a "
                            @"filename.");
            }
            
        } else if ([directive isEqualToString:@"csh"]) {
            
            /* Skip whitespace and skip a possible '-' prefix */
            [lineScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
            [lineScanner scanString:@"-" intoString:NULL];
            
            NSString *cmd = [lineScanner remainderOfString];
            
            ReportError([NSString stringWithFormat:@"The OBJ file tried to "
                         @"perform the shell command \"%@\"; this directive "
                         @"was ignored.", cmd]);
            
        } else {
            
            ReportError([NSString stringWithFormat:@"Unknown command '%@'", directive]);
            
        }
    }
        
    return self;
}

- (id)initWithOBJURL:(NSURL*)url errors:(NSMutableArray*) errors
{
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (!data) {
        if (error) [errors addObject:[error localizedDescription]];
        else [errors addObject:[NSString stringWithFormat:@"Could not open '%@'", url]];
        [self release];
        return nil;
    }
    
    NSURL *materialSearchDir = [url URLByDeletingLastPathComponent];
    
    return [self initWithOBJData:data materialSearchDir:materialSearchDir errors:errors];
}

@end
