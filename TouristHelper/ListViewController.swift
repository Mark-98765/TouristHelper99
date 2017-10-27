//
//  ListViewController.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var titleContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var menuButton: UIButton!
    @IBAction func menuButtonAction(_ sender: UIButton) {
        showMenu()
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    
    
    fileprivate struct Storyboard {
        static let TableViewEstimatedRowHeight: CGFloat = 50.0
        
        static let ListCellReuseIdentifier = "ListCellReuseIdentifier"
    }
    
    var tabBarViewController: TabBarViewController?
    
    var isLoading = false
    
    var refreshControl = UIRefreshControl()
    var isRefreshing: Bool = false // For use when using the refreshControl
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tbc = self.tabBarController as? TabBarViewController {
            tabBarViewController = tbc
        }

        titleContainerView.backgroundColor = systemColor()
        
        let text = Constants.AppNameText
        titleLabel.attributedText = NSAttributedString(string: text, attributes: navigationBarTitleTextAttributes())
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = Storyboard.TableViewEstimatedRowHeight
        tableView.backgroundColor = tableViewBackgroundColor()
        
        hideActivityIndicator() // Just in case...
        activityIndicator.color = systemColor()
        activityIndicatorContainerView.backgroundColor = .white
        activityIndicatorContainerView.isHidden = true
        activityIndicatorContainerView.layer.cornerRadius = Constants.ImageViewLayerCornerRadius
        activityIndicatorContainerView.clipsToBounds = true
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(tableViewSwipeRight(_:)))
        swipeGestureRecognizer.direction = .right
        tableView.addGestureRecognizer(swipeGestureRecognizer)
        
        initRefreshControl()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !appIsValid() {
            showAppInvalidAlert()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Init/Setup methods
    
    func initRefreshControl() {
        refreshControl.attributedTitle = NSAttributedString(string: Constants.PullToRefreshText)
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor.lightGray // UIColor.whiteColor()
        tableView?.addSubview(refreshControl)
    }
    
    // MARK: - UI Methods
    
    func updateUI() {
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    func showActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicatorContainerView.isHidden = false
    }
    
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicatorContainerView.isHidden = true
    }
    
    // MARK: - Action methods
    
    func showAppInvalidAlert() {
        if let reason = appIsInvalidReason() {
            showOKAlert(title: Constants.AppNameText, message: reason, presentingViewController: self, handler: nil)
        }
    }
    
    func showMenu() {
        if !appIsValid() {
            showAppInvalidAlert()
            return
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: Constants.SortAlphabeticallyText, style: .default) { [weak self] (action) in
            guard let strongSelf = self else { return }
            strongSelf.tabBarViewController?.placesOfInterestSortType = .alphabetic
            strongSelf.tabBarViewController?.processLocationDataOnServerReturn(strongSelf.tabBarViewController?.placesOfInterest)
            strongSelf.reloadData()
        })
        alert.addAction(UIAlertAction(title: Constants.SortByLocationText, style: .default) { [weak self] (action) in
            guard let strongSelf = self else { return }
            strongSelf.tabBarViewController?.placesOfInterestSortType = .distance
            strongSelf.tabBarViewController?.processLocationDataOnServerReturn(strongSelf.tabBarViewController?.placesOfInterest)
            strongSelf.reloadData()
        })
        alert.addAction(UIAlertAction(title: Constants.CancelText, style: .cancel) { (action) in
            // Do nothing
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        printLog("handleRefresh")
        refreshControl.endRefreshing()
        // getSomeData() // Not implemented
    }

    // MARK: - Gesture methods
    
    func tableViewSwipeRight(_ gestureRecognizer: UISwipeGestureRecognizer) {
        showMenu()
    }
    
    // MARK: - Navigation
    

}

// MARK: - Extension - UITableViewDataSource

extension ListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        
        if isLoading {
            tableView.separatorStyle = .none
            printLog("numberOfSections isLoading")
            return 0
        }
        
        if let tbc = self.tabBarController as? TabBarViewController, let returnedData = tbc.placesOfInterest, returnedData.count > 0 {
            tableView.separatorStyle = .singleLine
            return 1
        }
        
        // No results
        
        let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        noDataLabel.textColor = UIColor.lightGray
        noDataLabel.textAlignment = .center
        noDataLabel.numberOfLines = 0
        noDataLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        tableView.backgroundView = noDataLabel
        tableView.separatorStyle = .none
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tbc = self.tabBarController as? TabBarViewController, let returnedData = tbc.placesOfInterest {
            return returnedData.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.ListCellReuseIdentifier, for: indexPath) as! ListTableViewCell
        cell.delegate = self
        
        if let tbc = self.tabBarController as? TabBarViewController,
           let returnedData = tbc.placesOfInterest, returnedData.count > indexPath.row {
            cell.configure(with: returnedData[indexPath.row])
        } else {
            cell.configureNoData()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
}

// MARK: - Extension - UITableViewDelegate

extension ListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) as? ListTableViewCell, let placeOfInterest = cell.placeOfInterest {
            tabBarViewController?.addAnnotationForPlaceOfInterest(placeOfInterest)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    }
}

// MARK: - Extension - ListTableViewCellDelegate

extension ListViewController: ListTableViewCellDelegate {

    func listTableViewCell(_ cell: ListTableViewCell, didSelectMapFor placeOfInterest: PlaceOfInterest) {
        if let tbc = tabBarController as? TabBarViewController {
            tbc.addAnnotationForPlaceOfInterest(placeOfInterest)
        }
    }

}



