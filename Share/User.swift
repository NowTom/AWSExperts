//
//  User.swift
//  Share
//
//  Created by Tomoaki Imai
//

import Foundation
import FBSDKCoreKit
import AWSDynamoDB

public class User: AWSDynamoDBObjectModel, AWSDynamoDBModeling {

    public static var currentUser: User?

    public var identityId: String?
    public var facebookId: String?
    public var name: String?
    public var imageURL: String?
    
    public static func dynamoDBTableName() -> String! {
        return "User"
    }
    
    public static func hashKeyAttribute() -> String! {
        return "identityId"
    }
    
    public override func `self`() -> Self {
        return self
    }
}