#import "AppDelegate.h"
#import "PowerSleepController.h"

@interface AppDelegate ()
@property(nonatomic, strong) PowerSleepController *powerController;
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSTimer *refreshTimer;
@property(nonatomic, strong, nullable) NSNumber *sleepDisabled;
@property(nonatomic) BOOL changing;
@property(nonatomic) BOOL refreshing;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    self.powerController = [[PowerSleepController alloc] init];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [self renderMenu];
    [self refreshStatusShowingError:NO];

    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                        target:self
                                                      selector:@selector(periodicRefresh:)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    [self.refreshTimer invalidate];
}

- (void)toggleSleepState:(id)sender {
    (void)sender;
    if (self.sleepDisabled == nil || self.changing) {
        return;
    }

    BOOL targetState = !self.sleepDisabled.boolValue;
    self.changing = YES;
    [self renderMenu];

    __weak typeof(self) weakSelf = self;
    [self.powerController setSleepDisabled:targetState completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self = weakSelf;
            if (self == nil) {
                return;
            }
            self.changing = NO;
            if (error == nil) {
                [self refreshStatusShowingError:YES];
                return;
            }

            [self renderMenu];
            if ([error.domain isEqualToString:LSTPowerSleepErrorDomain] &&
                error.code == LSTPowerSleepErrorCancelled) {
                return;
            }
            [self showError:error.localizedDescription];
        });
    }];
}

- (void)manualRefresh:(id)sender {
    (void)sender;
    [self refreshStatusShowingError:YES];
}

- (void)periodicRefresh:(NSTimer *)timer {
    (void)timer;
    [self refreshStatusShowingError:NO];
}

- (void)showAbout:(id)sender {
    (void)sender;
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Lid Sleep Toggle";
    alert.informativeText = @"从菜单栏一键切换 Mac 合盖休眠状态。\n\n开启“合盖继续运行”后，请勿将仍在工作的 Mac 放入包中，以免积热。";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"好"];
    [alert runModal];
}

- (void)quit:(id)sender {
    (void)sender;
    [NSApp terminate:nil];
}

- (void)refreshStatusShowingError:(BOOL)showError {
    if (self.changing || self.refreshing) {
        return;
    }

    self.refreshing = YES;
    [self renderMenu];

    __weak typeof(self) weakSelf = self;
    [self.powerController fetchSleepDisabledWithCompletion:^(NSNumber *value, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self = weakSelf;
            if (self == nil) {
                return;
            }
            self.refreshing = NO;
            self.sleepDisabled = error == nil ? value : nil;
            [self renderMenu];
            if (showError && error != nil) {
                [self showError:error.localizedDescription];
            }
        });
    }];
}

- (void)renderMenu {
    if (self.statusItem == nil) {
        return;
    }

    NSString *symbolName;
    NSString *tooltip;
    if (self.sleepDisabled == nil) {
        symbolName = @"questionmark.circle";
        tooltip = @"正在检查休眠状态";
    } else if (self.sleepDisabled.boolValue) {
        symbolName = @"bolt.fill";
        tooltip = @"合盖继续运行";
    } else {
        symbolName = @"moon.zzz.fill";
        tooltip = @"合盖会休眠";
    }

    NSImage *image = [NSImage imageWithSystemSymbolName:symbolName
                               accessibilityDescription:tooltip];
    NSImageSymbolConfiguration *configuration =
        [NSImageSymbolConfiguration configurationWithPointSize:15 weight:NSFontWeightSemibold];
    image = [image imageWithSymbolConfiguration:configuration];
    image.template = YES;
    self.statusItem.button.image = image;
    self.statusItem.button.toolTip = tooltip;

    NSMenu *menu = [[NSMenu alloc] init];
    menu.autoenablesItems = NO;

    NSString *statusTitle;
    if (self.changing) {
        statusTitle = @"状态：正在切换…";
    } else if (self.refreshing) {
        statusTitle = @"状态：正在检查…";
    } else if (self.sleepDisabled == nil) {
        statusTitle = @"状态：无法读取";
    } else {
        statusTitle = self.sleepDisabled.boolValue
            ? @"状态：合盖继续运行"
            : @"状态：合盖会休眠";
    }

    NSMenuItem *statusMenuItem = [[NSMenuItem alloc] initWithTitle:statusTitle
                                                            action:nil
                                                     keyEquivalent:@""];
    statusMenuItem.enabled = NO;
    [menu addItem:statusMenuItem];
    [menu addItem:[NSMenuItem separatorItem]];

    NSString *toggleTitle = self.sleepDisabled.boolValue
        ? @"恢复合盖休眠"
        : @"开启合盖继续运行";
    NSMenuItem *toggleItem = [[NSMenuItem alloc] initWithTitle:toggleTitle
                                                       action:@selector(toggleSleepState:)
                                                keyEquivalent:@""];
    toggleItem.target = self;
    toggleItem.enabled = self.sleepDisabled != nil && !self.changing && !self.refreshing;
    [menu addItem:toggleItem];

    NSMenuItem *refreshItem = [[NSMenuItem alloc] initWithTitle:@"重新检查状态"
                                                        action:@selector(manualRefresh:)
                                                 keyEquivalent:@"r"];
    refreshItem.target = self;
    refreshItem.enabled = !self.changing && !self.refreshing;
    [menu addItem:refreshItem];
    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"关于 Lid Sleep Toggle"
                                                      action:@selector(showAbout:)
                                               keyEquivalent:@""];
    aboutItem.target = self;
    aboutItem.enabled = YES;
    [menu addItem:aboutItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"退出"
                                                     action:@selector(quit:)
                                              keyEquivalent:@"q"];
    quitItem.target = self;
    quitItem.enabled = YES;
    [menu addItem:quitItem];

    self.statusItem.menu = menu;
}

- (void)showError:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"操作失败";
    alert.informativeText = message;
    alert.alertStyle = NSAlertStyleCritical;
    [alert addButtonWithTitle:@"好"];
    [alert runModal];
}

@end
