//
//  StoryCell.swift
//  SignpostDemo
//
//  Created by Ben Scheirman on 7/27/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import UIKit

class StoryCell : UITableViewCell {
    var storyID: Int?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        setContent(visible: false)
    }
    
    func showLoadingIndicator() {
        activityIndicator.startAnimating()
        setContent(visible: false)
    }
    
    func showContent() {
        activityIndicator.stopAnimating()
        setContent(visible: true)
    }
    
    private func setContent(visible: Bool) {
        let contentFields = [titleLabel, authorLabel, scoreLabel, dateLabel]
        contentFields.forEach { $0?.isHidden = !visible }
    }
}
