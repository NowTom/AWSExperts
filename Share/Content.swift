//
//  Content.swift
//  Share
//
//  Created by Tomoaki Imai
//

import Foundation
import AWSDynamoDB

public class Content: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    public var identityId: String?
    public var createdAt: NSNumber?
    public var userName: String?
    public var userImageURL: String?
    public var title: String?
    public var originalBucket: String?
    public var originalKey: String?
    public var postingSite: String?
    
    public static func dynamoDBTableName() -> String! {
        return "Content"
    }
    
    public static func hashKeyAttribute() -> String! {
        return "identityId"
    }
    
    public static func rangeKeyAttribute() -> String! {
        return "createdAt"
    }
    
    public override func `self`() -> Self {
        return self
    }
    
    public var pictureURL: String {
        return "https://s3.amazonaws.com/" + originalBucket! + "/" + originalKey!
    }
}