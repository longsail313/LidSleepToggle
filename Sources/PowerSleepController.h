#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const LSTPowerSleepErrorDomain;

typedef NS_ENUM(NSInteger, LSTPowerSleepErrorCode) {
    LSTPowerSleepErrorCommandFailed = 1,
    LSTPowerSleepErrorCancelled = 2,
};

@interface PowerSleepController : NSObject

- (void)fetchSleepDisabledWithCompletion:(void (^)(NSNumber * _Nullable value, NSError * _Nullable error))completion;
- (void)setSleepDisabled:(BOOL)disabled
              completion:(void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
