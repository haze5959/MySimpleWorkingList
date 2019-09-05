//
//  OQ+String.swift
//  MyWorkingList
//
//  Created by kwonogyu on 05/09/2019.
//  Copyright © 2019 OQ. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: "Localizable", value: self, comment: "")
    }
}
