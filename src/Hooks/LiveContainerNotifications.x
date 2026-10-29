//
// LiveContainerNotifications.x
//
// LiveContainer cannot present or complete X's remote-notification
// registration flow reliably. Treat notification permission as unavailable in
// that host only so the optional onboarding screen cannot block app startup.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

static BOOL BHTRunningInLiveContainer(void) {
    NSProcessInfo* processInfo = NSProcessInfo.processInfo;
    for (NSString* key in processInfo.environment) {
        NSString* normalized = key.lowercaseString;
        if ([normalized containsString:@"livecontainer"]) {
            return YES;
        }
    }

    for (NSString* path in @[
             NSBundle.mainBundle.bundlePath ?: @"",
             NSBundle.mainBundle.executablePath ?: @"",
             processInfo.arguments.firstObject ?: @""
         ]) {
        if ([path.lowercaseString containsString:@"livecontainer"]) {
            return YES;
        }
    }
    return NSClassFromString(@"LCApplication") != Nil ||
           NSClassFromString(@"LiveContainer") != Nil;
}

%group BHTLiveContainerNotifications

%hook UNUserNotificationCenter

- (void)requestAuthorizationWithOptions:(UNAuthorizationOptions)options
                      completionHandler:(void (^)(BOOL granted,
                                                   NSError* error))completion {
    if (!completion) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(NO, nil);
    });
}

- (void)registerForRemoteNotifications {
    // Remote notification registration is unsupported by this host.
}

%end

%end

%ctor {
    if (BHTRunningInLiveContainer() &&
        NSClassFromString(@"UNUserNotificationCenter")) {
        %init(BHTLiveContainerNotifications);
    }
}
