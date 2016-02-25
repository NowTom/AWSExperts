//
//  ContentCell.swift
//  Share
//
//  Created by Tomoaki Imai
//

import Foundation

import UIKit

class ContentCell: UICollectionViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var pictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    // http://tanakalivesinsendai.blogspot.jp/2014/05/iosuicollectionviewcellimage.html
    override func prepareForReuse() {
        super.prepareForReuse()
        
        userImageView.image = nil
        pictureImageView.image = nil
    }
    
    func update(content: Content) {
        nameLabel.text = content.userName
        let createdAt = NSDate(timeIntervalSince1970: content.createdAt! as NSTimeInterval)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        createdAtLabel.text = dateFormatter.stringFromDate(createdAt)
        titleLabel.text = content.title
        // http://cccookie.hatenablog.com/entry/2014/01/08/104544
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [unowned self] () -> Void in
            let userImageURL = NSURL(string: content.userImageURL!)
            let userImage = NSData(contentsOfURL: userImageURL!)
            let pictureURL = NSURL(string: content.pictureURL)
            let pictureImage = NSData(contentsOfURL: pictureURL!)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.userImageView.image = UIImage(data: userImage!)
                self.pictureImageView.image = UIImage(data: pictureImage!)
            })
        })
    }
}
