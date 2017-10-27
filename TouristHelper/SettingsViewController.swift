//
//  SettingsViewController.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var titleContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    fileprivate struct Storyboard {
        static let TableViewEstimatedRowHeight: CGFloat = 50.0
        
        static let SettingsCellReuseIdentifier = "SettingsCellReuseIdentifier"
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        titleContainerView.backgroundColor = systemColor()
        
        let text = Constants.SettingsText
        titleLabel.attributedText = NSAttributedString(string: text, attributes: navigationBarTitleTextAttributes())
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = Storyboard.TableViewEstimatedRowHeight
        tableView.backgroundColor = tableViewBackgroundColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Init/Setup methods
    
    
    // MARK: - UI Methods
    
    func updateUI() {
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    // MARK: - Action methods
    
    // MARK: - Gesture methods
    
    // MARK: - Navigation
    

}


// MARK: - Extension - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // tableView.separatorStyle = .singleLine
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.SettingsCellReuseIdentifier, for: indexPath) as! SettingsTableViewCell
        
        if indexPath.row == 0 {
            let text = Constants.AppVersion + " (" + Constants.AppDate + ")"
            cell.configure(title: Constants.AppVersionText, text: text)
            cell.selectionStyle = .none
            cell.accessoryType = .none
            return cell
        }
        
        let text = UserPrefs.serverDataSource().rawValue
        cell.configure(title: Constants.DataSourceText, text: text)
        cell.selectionStyle = .blue
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
}

// MARK: - Extension - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 1 {
            showOKAlert(title: Constants.DataSourceText, message: Constants.SelectionNotAvailableText, presentingViewController: self, handler: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    }
}



