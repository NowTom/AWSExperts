//
//  TopViewController.swift
//  Share
//
//  Created by Tomoaki Imai
//

import UIKit
import AWSCore
import AWSS3
import AWSSNS
import AWSDynamoDB
import FBSDKCoreKit

class TopViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let imagePicker = UIImagePickerController()

    var contents: [Content]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary

        refreshView()
    }

    func didPickButtonTapped() {
        presentViewController(imagePicker, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contents?.count ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ContentCell", forIndexPath: indexPath)
        guard let contentCell = cell as? ContentCell else {
            return cell
        }
        guard let contents = contents else {
            return cell
        }
        contentCell.update(contents[indexPath.row])
        return cell
    }
    
    @IBAction func didRefreshButtonTapped(sender: UIBarButtonItem) {
    }

    @IBAction func didAddButtonTapped(sender: UIBarButtonItem) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("didFinishPickingMediaWithInfo")
        guard let url = info["UIImagePickerControllerReferenceURL"] as? NSURL else {
            return
        }
        guard let path = url.path else {
            return
        }
        print("\(path)")
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        let imagePath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(url.path!)
        guard let imageData = UIImageJPEGRepresentation(image, 0) else {
            return
        }
        guard imageData.writeToFile(imagePath, atomically: true) else {
            return
        }
        let uploadImageURL = NSURL(fileURLWithPath: imagePath)
        print("\(uploadImageURL)")
        print("\(uploadImageURL.lastPathComponent)")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let now = NSDate()
        upload(uploadImageURL, createdAt: now).continueWithSuccessBlock { [weak self] (task) -> AnyObject? in
            guard let weakSelf = self else {
                return nil
            }
            return weakSelf.saveContent(uploadImageURL, createdAt: now)
        }.continueWithBlock { [weak self] (task) -> AnyObject? in
            guard let weakSelf = self else {
                return nil
            }
            if task.error == nil {
                weakSelf.push()
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                weakSelf.imagePicker.dismissViewControllerAnimated(true) { () -> Void in
                    weakSelf.refreshView()
                }
            })
            return nil
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        print("imagePickerControllerDidCancel")
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
    }

    func refreshView() {
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = "postingSite-createdAt-index"
        queryExpression.hashKeyAttribute = "postingSite";
        queryExpression.hashKeyValues = "Global"
        queryExpression.scanIndexForward = false
        AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().query(Content.self, expression: queryExpression).continueWithBlock({ [weak self] (task) -> AnyObject! in
            guard let weakSelf = self else {
                return nil
            }
            guard task.error == nil else {
                return task
            }
            guard let paginatedOutput = task.result as? AWSDynamoDBPaginatedOutput else {
                return task
            }
            guard let contents = paginatedOutput.items as? [Content] else {
                return task
            }
            weakSelf.contents = contents
            return contents
        }).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withSuccessBlock: { [weak self] (task) -> AnyObject! in
            guard let weakSelf = self else {
                return nil
            }
            weakSelf.collectionView?.reloadData()
            return nil
        })
    }

    func upload(imageURL: NSURL, createdAt: NSDate) -> AWSTask {
        let request = AWSS3TransferManagerUploadRequest()
        // NOTE: 環境に合わせて変更する
        request.bucket = "share-xxxxxxxxxxxx"
        request.key = "images/original/\(createdAt.timeIntervalSince1970)-\(imageURL.lastPathComponent!)"
        request.body = imageURL
        return AWSS3TransferManager.defaultS3TransferManager().upload(request)
    }

    func saveContent(imageURL: NSURL, createdAt: NSDate) -> AWSTask {
        let content = Content()
        content.identityId = AWSCognitoClient.sharedInstance.identityId
        content.createdAt = createdAt.timeIntervalSince1970
        content.userName = User.currentUser?.name
        content.userImageURL = User.currentUser?.imageURL
        content.title = "こんなことしてきました"
        // NOTE: 環境に合わせて変更する
        content.originalBucket = "share-xxxxxxxxxxxx"
        content.originalKey = "images/original/\(createdAt.timeIntervalSince1970)-\(imageURL.lastPathComponent!)"
        content.postingSite = "Global"
        return AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(content)
    }
    
    func push() {
        let publishInput = AWSSNSPublishInput()
        // NOTE: 環境に合わせて変更する
        publishInput.targetArn = "arn:aws:sns:us-east-1:share-xxxxxxxxxxxx:share-users"
        publishInput.message = "新しい写真が投稿されました"
        AWSSNS.defaultSNS().publish(publishInput)
    }
}
