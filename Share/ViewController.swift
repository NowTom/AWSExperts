//
//  ViewController.swift
//  Share
//
//  Created by Tomoaki Imai
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Bolts
import AWSCore
import AWSCognito
import AWSDynamoDB

class ViewController: UIViewController, FBSDKLoginButtonDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loginButton: FBSDKLoginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile", "email"]
        loginButton.delegate = self
        loginButton.center = self.view.center
        self.view.addSubview(loginButton)
        
        FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "onProfileUpdated:",
            name:FBSDKProfileDidChangeNotification,
            object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if FBSDKAccessToken.currentAccessToken() != nil {
            login()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
    }

    func onProfileUpdated(notification: NSNotification) {
        login()
    }

    func login() {
        guard let token = FBSDKAccessToken.currentAccessToken() else {
            return
        }
        guard let tokenString = token.tokenString else {
            return
        }
        // Facebookの認証に成功したのでCognitoの認証を行う
        // NOTE: 環境に合わせて変更する
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx")
        credentialsProvider.logins = ["graph.facebook.com": tokenString]
        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        // http://stackoverflow.com/questions/33205271/unauthenticated-user-to-authenticated-user-on-aws-cognito
        credentialsProvider.refresh().continueWithSuccessBlock { (task) -> AnyObject! in
            // Cognitoの認証に成功した
            guard let identityId = task.result as? String else {
                return task
            }
            print("Cognito identity id = \(identityId)")
            return task
        }.continueWithSuccessBlock { (task) -> AnyObject? in
            guard let identityId = task.result as? String else {
                return task
            }
            let user = User()
            user.identityId = identityId
            let currentProfile = FBSDKProfile.currentProfile()
            user.facebookId = currentProfile?.userID
            user.name = currentProfile?.name
            user.imageURL = currentProfile?.imageURLForPictureMode(.Normal, size: CGSize(width: 60, height: 60)).absoluteString
            return AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(user).continueWithSuccessBlock { (task) -> AnyObject? in
                User.currentUser = user
                return task
            }
        }.continueWithExecutor(AWSExecutor.mainThreadExecutor(), withSuccessBlock: { [unowned self] (task) -> AnyObject! in
            self.performSegueWithIdentifier("TopViewController", sender: self)
            return nil
        })
    }

}

