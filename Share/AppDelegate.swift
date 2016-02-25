//
//  AppDelegate.swift
//  Share
//
//  Created by Tomoaki Imai
//

import UIKit
import FBSDKCoreKit
import AWSMobileAnalytics
import AWSSNS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        let settings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()

        AWSLogger.defaultLogger().logLevel = .Debug

        // NOTE: 環境に合わせて変更する
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId:"us-east-1:xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx")
        let serviceConfiguration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = serviceConfiguration

        // NOTE: 環境に合わせて変更する
        let mobileAnalytics = AWSMobileAnalytics(forAppId: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", identityPoolId: "us-east-1:xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx")
        let eventClient = mobileAnalytics.eventClient
        let event = eventClient.createEventWithEventType("ApplicationStart")
        eventClient.recordEvent(event)
        eventClient.submitEvents()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let deviceTokenString = "\(deviceToken)"
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString:"<>"))
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        print("deviceToken: \(deviceTokenString)")

        // NOTE: 環境に合わせて変更する
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx")
        let serviceConfiguration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = serviceConfiguration
        
        let createPlatformEndpointInput = AWSSNSCreatePlatformEndpointInput()
        // NOTE: 環境に合わせて変更する
        createPlatformEndpointInput.platformApplicationArn = "arn:aws:sns:us-east-1:xxxxxxxxxxxx:app/APNS_SANDBOX/Share"
        createPlatformEndpointInput.token = deviceTokenString
        AWSSNS.defaultSNS().createPlatformEndpoint(createPlatformEndpointInput).continueWithSuccessBlock { (task) -> AnyObject? in
            guard let createEndpointResponse = task.result as? AWSSNSCreateEndpointResponse else {
                return task
            }
            let subscribeInput = AWSSNSSubscribeInput()
            subscribeInput.protocols = "application"
            // NOTE: 環境に合わせて変更する
            subscribeInput.topicArn = "arn:aws:sns:us-east-1:xxxxxxxxxxxx:share-users"
            subscribeInput.endpoint = createEndpointResponse.endpointArn
            return AWSSNS.defaultSNS().subscribe(subscribeInput)
        }
    }

}

