//
//  BalanceService.swift
//  iEMI
//
//  Created by Fer Rowies on 8/18/15.
//  Copyright © 2015 Rowies. All rights reserved.
//

import UIKit

protocol AccountService: NSObjectProtocol {
    
    var service: Service { get set }
    
    func accountBalance(licensePlate licensePlate:String, completion: (result: () throws -> Double) -> Void) -> Void
    
    func accountCredits(licensePlate licensePlate:String, cant:Int ,completion: (result: () throws -> [Credit]) -> Void) -> Void
    
}