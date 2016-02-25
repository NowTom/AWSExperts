//
//  AWSCognitoClient.swift
//  Share
//
//  Created by Tomoaki Imai
//

import Foundation
import AWSCore
import AWSCognito

public class AWSCognitoClient {

    public static let sharedInstance = AWSCognitoClient()

    public var identityId: String? {
        guard let credentialsProvider = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration.credentialsProvider as? AWSCognitoCredentialsProvider else {
            return nil
        }
        return credentialsProvider.identityId
    }

    private init() {
    }
    
}