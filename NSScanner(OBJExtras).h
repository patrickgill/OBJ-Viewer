#import <Cocoa/Cocoa.h>

@interface NSScanner (OBJExtras)

- (BOOL)scanOnOrOff:(BOOL*)answer;
- (NSString*)remainderOfString;
- (BOOL)scanWord:(NSString **)word;

@end
