#import <Foundation/Foundation.h>
#import "PowerStatusParser.h"

static void assertCondition(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message.UTF8String);
        exit(1);
    }
}

int main(void) {
    @autoreleasepool {
        assertCondition(
            LSTIsSleepDisabled(@"System-wide power settings:\n SleepDisabled  1\n"),
            @"SleepDisabled 1 should parse as enabled"
        );
        assertCondition(
            !LSTIsSleepDisabled(@"System-wide power settings:\n SleepDisabled  0\n"),
            @"SleepDisabled 0 should parse as disabled"
        );
        assertCondition(
            !LSTIsSleepDisabled(@"System-wide power settings:\n"),
            @"A missing setting should default to normal sleep"
        );
        puts("All parser tests passed.");
    }
    return 0;
}
