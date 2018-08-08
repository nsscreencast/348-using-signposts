//
//  ViewController.swift
//  SignpostDemo
//
//  Created by Ben Scheirman on 7/27/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import UIKit
import os.log
import os.signpost

class ViewController: UITableViewController {

    private enum StoryLoading {
        case loading(URLSessionDataTask)
        case loaded(Story)
    }
    
    private lazy var newsAPI: NewsAPI = {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        return NewsAPI(session: session)
    }()
    
    private var storyIDs: [Int] = []
    private var stories: [Int: StoryLoading] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        os_signpost(.event, log: SignpostLog.pointsOfInterest, name: "ViewController-viewDidLoad")
        
        tableView.rowHeight = 123
        tableView.estimatedRowHeight = 0
        
        loadNews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        os_signpost(.event, log: SignpostLog.pointsOfInterest, name: "ViewController-viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        os_signpost(.event, log: SignpostLog.pointsOfInterest, name: "ViewController-viewDidAppear")
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storyIDs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StoryCell", for: indexPath) as! StoryCell
        let storyID = storyIDs[indexPath.row]
        
        cell.storyID = storyID
        
        let storyLoading = stories[storyID]
        switch storyLoading {
        case .loading?:
            cell.showLoadingIndicator()
        case .loaded(let story)?:
            os_signpost(.begin, log: SignpostLog.general, name: "Configure Cell", "Story %d - %s", story.id, story.title)
            configure(cell: cell, with: story)
            os_signpost(.end, log: SignpostLog.general, name: "Configure Cell")
        case .none:
            cell.showLoadingIndicator()
            loadStory(with: storyID, indexPath: indexPath)
        }
        
        return cell
    }
    
    // MARK: - Private Methods
    
    private func configure(cell: StoryCell, with story: Story) {
        cell.showContent()
        cell.titleLabel.text = story.title
        cell.authorLabel.text = "by \(story.by)"
        cell.scoreLabel.text = "\(story.score) points"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let date = dateFormatter.string(from: story.time)
        cell.dateLabel.text = "Posted on \(date)"
    }
    
    private func loadNews() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        newsAPI.loadTopStories { result in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            switch result {
                
            case .success(let storyIDs):
                self.storyIDs = storyIDs
                self.tableView.reloadData()
                
            case .failed(let error):
                self.displayError(error)
                
            }
        }.resume()
    }
    
    private func loadStory(with id: Int, indexPath: IndexPath) {
        let spidForStory = OSSignpostID(log: SignpostLog.general, object: id as AnyObject)
        os_signpost(.begin, log: SignpostLog.general, name: "loadStory", signpostID: spidForStory, "Load Story %d", id)
        let task = newsAPI.loadStory(id: id) { result in
            
            switch result {
            case .success(let story):
                os_signpost(.end, log: SignpostLog.general, name: "loadStory", signpostID: spidForStory, "%s", story.title)
                
                self.stories[story.id] = .loaded(story)
                
                if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows, visibleIndexPaths.contains(indexPath) {
                    assert(Thread.isMainThread)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
                
            case .failed(let error):
                if self.isCancellationError(error) {
                    os_signpost(.end, log: SignpostLog.general, name: "loadStory", signpostID: spidForStory, "Cancellation")
                    
                } else {
                    os_signpost(.end, log: SignpostLog.general, name: "loadStory", signpostID: spidForStory, "Error: %@", error as NSError)
                    
                    print("Error loading story: \(error)")
                }
            }
        }
        
        print("Loading story \(id)")
        stories[id] = .loading(task)
        task.resume()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        print("Will display cell \(indexPath.row)")
        
        if indexPath.row == 0 {
            os_signpost(.event, log: SignpostLog.pointsOfInterest, name: "Will Display First Cell")
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell:
        UITableViewCell, forRowAt indexPath: IndexPath) {
        print("didEndDisplayingCell \(indexPath.row)")

        guard let storyCell = cell as? StoryCell else { return }
        guard let storyID = storyCell.storyID else { return }
        guard let storyLoading = stories[storyID] else { return }
        if case .loading(let task) = storyLoading {
            print("Cancelling task for story \(storyID)")
            task.cancel()
            stories[storyID] = nil
        }
    }

    private func displayError(_ error: Error) {
        let alert = UIAlertController(title: "Connection error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func isCancellationError(_ error: Error) -> Bool {
        let e = error as NSError
        
        return e == NewsAPI.Errors.cancelled as NSError ||
            (e.domain == URLError.errorDomain &&
            e.code == URLError.cancelled.rawValue)
    }
}

