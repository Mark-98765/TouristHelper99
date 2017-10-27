//
//  ListTableViewCell.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import UIKit

protocol ListTableViewCellDelegate: class {
    func listTableViewCell(_ cell: ListTableViewCell, didSelectMapFor placeOfInterest: PlaceOfInterest)
}


class ListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var placeOfInterestTextLabel: UILabel!
    
    weak var delegate: ListTableViewCellDelegate?
    var indexPath: IndexPath?
    var placeOfInterest: PlaceOfInterest?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with placeOfInterest: PlaceOfInterest) {
        backgroundColor = tableViewCellBackgroundColor()
        selectionStyle = .blue
        
        self.placeOfInterest = placeOfInterest
        placeOfInterestTextLabel.text = placeOfInterest.text        
    }
    
    func configureNoData() {
        backgroundColor = tableViewCellBackgroundColor()
        selectionStyle = .none
        
        placeOfInterest = nil
        placeOfInterestTextLabel.text = nil
    }

}
