#import "PowerStatusParser.h"

BOOL LSTIsSleepDisabled(NSString *output) {
    __block BOOL sleepDisabled = NO;
    [output enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if ([line rangeOfString:@"SleepDisabled"].location == NSNotFound) {
            return;
        }

        NSArray<NSString *> *parts = [line componentsSeparatedByCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]];
        for (NSString *part in [parts reverseObjectEnumerator]) {
            if (part.length == 0) {
                continue;
            }
            sleepDisabled = [part isEqualToString:@"1"];
            *stop = YES;
            break;
        }
    }];
    return sleepDisabled;
}
