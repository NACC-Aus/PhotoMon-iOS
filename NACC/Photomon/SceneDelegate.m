#import "SceneDelegate.h"
#import "AppDelegate.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    AppDelegate *applicationDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = applicationDelegate.window ?: [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.windowScene = windowScene;
    // The legacy nibs use fixed light backgrounds and artwork. Keep UIKit's
    // inherited label, placeholder, table, alert, and navigation colors in the
    // matching light appearance so text remains readable in device Dark Mode.
    self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    applicationDelegate.window = self.window;
    [self.window makeKeyAndVisible];
}

- (void)sceneWillResignActive:(UIScene *)scene
{
    AppDelegate *applicationDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [applicationDelegate applicationWillResignActive:[UIApplication sharedApplication]];
}

- (void)sceneDidEnterBackground:(UIScene *)scene
{
    AppDelegate *applicationDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [applicationDelegate applicationDidEnterBackground:[UIApplication sharedApplication]];
}

- (void)sceneWillEnterForeground:(UIScene *)scene
{
    AppDelegate *applicationDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [applicationDelegate applicationWillEnterForeground:[UIApplication sharedApplication]];
}

- (void)sceneDidBecomeActive:(UIScene *)scene
{
    AppDelegate *applicationDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [applicationDelegate applicationDidBecomeActive:[UIApplication sharedApplication]];
}

@end
