#import "PowerSleepController.h"
#import "PowerStatusParser.h"

NSString *const LSTPowerSleepErrorDomain = @"io.github.lidsleeptoggle.PowerSleep";

@implementation PowerSleepController

- (void)fetchSleepDisabledWithCompletion:(void (^)(NSNumber *, NSError *))completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *output = nil;
        NSString *errorOutput = nil;
        NSError *launchError = nil;
        int status = [self runExecutable:@"/usr/bin/pmset"
                               arguments:@[@"-g"]
                                  output:&output
                             errorOutput:&errorOutput
                                   error:&launchError];

        if (launchError != nil) {
            completion(nil, launchError);
            return;
        }
        if (status != 0) {
            completion(nil, [self commandErrorWithMessage:errorOutput]);
            return;
        }
        completion(@(LSTIsSleepDisabled(output ?: @"")), nil);
    });
}

- (void)setSleepDisabled:(BOOL)disabled
              completion:(void (^)(NSError *))completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *value = disabled ? @"1" : @"0";
        NSString *command = [NSString stringWithFormat:@"/usr/bin/pmset -a disablesleep %@", value];
        NSString *script = [NSString stringWithFormat:
            @"do shell script \"%@\" with administrator privileges", command];

        NSString *output = nil;
        NSString *errorOutput = nil;
        NSError *launchError = nil;
        int status = [self runExecutable:@"/usr/bin/osascript"
                               arguments:@[@"-e", script]
                                  output:&output
                             errorOutput:&errorOutput
                                   error:&launchError];

        if (launchError != nil) {
            completion(launchError);
            return;
        }
        if (status == 0) {
            completion(nil);
            return;
        }

        BOOL cancelled = [errorOutput containsString:@"(-128)"] ||
            [errorOutput rangeOfString:@"cancel" options:NSCaseInsensitiveSearch].location != NSNotFound;
        if (cancelled) {
            NSError *error = [NSError errorWithDomain:LSTPowerSleepErrorDomain
                                                  code:LSTPowerSleepErrorCancelled
                                              userInfo:@{NSLocalizedDescriptionKey: @"操作已取消。"}];
            completion(error);
            return;
        }
        completion([self commandErrorWithMessage:errorOutput]);
    });
}

- (int)runExecutable:(NSString *)executable
            arguments:(NSArray<NSString *> *)arguments
               output:(NSString **)output
          errorOutput:(NSString **)errorOutput
                error:(NSError **)error {
    NSTask *task = [[NSTask alloc] init];
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];

    task.executableURL = [NSURL fileURLWithPath:executable];
    task.arguments = arguments;
    task.standardOutput = outputPipe;
    task.standardError = errorPipe;

    if (![task launchAndReturnError:error]) {
        return -1;
    }
    [task waitUntilExit];

    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
    if (output != NULL) {
        *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] ?: @"";
    }
    if (errorOutput != NULL) {
        NSString *message = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] ?: @"";
        *errorOutput = [message stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return task.terminationStatus;
}

- (NSError *)commandErrorWithMessage:(NSString *)message {
    NSString *description = message.length > 0 ? message : @"无法修改系统休眠设置。";
    return [NSError errorWithDomain:LSTPowerSleepErrorDomain
                               code:LSTPowerSleepErrorCommandFailed
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

@end
