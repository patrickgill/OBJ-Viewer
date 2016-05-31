#import "NSScanner(OBJExtras).h"


@implementation NSScanner(OBJExtras)

- (BOOL)scanOnOrOff:(BOOL*)answer
{
    if ([self scanString:@"on" intoString:NULL]) {
        *answer = YES;
        return YES;
    } else if ([self scanString:@"off" intoString:NULL]) {
        *answer = NO;
        return YES;
    } else {
        return NO;
    }
}

- (NSString*)remainderOfString
{
    return [[self string] substringFromIndex:[self scanLocation]];
}

- (BOOL)scanWord:(NSString **)word
{
    return [self scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:word];
}

@end
