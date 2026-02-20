#import "AppDelegate.h"
#import "FPLMainViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor systemBackgroundColor];

    FPLMainViewController *mainVC = [[FPLMainViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mainVC];

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
