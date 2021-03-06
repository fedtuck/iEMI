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
    
    func credits(licensePlate licensePlate:String ,start:Int ,cant:Int ,completion: (result: () throws -> [Credit]) -> Void) -> Void
    
    func debits(licensePlate licensePlate:String, fromTimeStamp:String ,completion: (result: () throws -> [Debit]) -> Void) -> Void
    
    func balance(licensePlate licensePlate:String, completion: (result: () throws -> [Transaction]) -> Void) -> Void

}