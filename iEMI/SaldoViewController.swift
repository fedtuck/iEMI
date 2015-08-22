//
//  SaldoViewController.swift
//  iEMI
//
//  Created by Fer Rowies on 2/6/15.
//  Copyright (c) 2015 Rowies. All rights reserved.
//

import UIKit

class SaldoViewController: TabBarIconFixerViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var saldoLabel: UILabel!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!

    override func iconName() -> String { return "saldo" }

    var refreshControl: UIRefreshControl!
    var tableElements = [Transaction]()
    var parkingSelected: Parking?
    var sectionItemCount = [Int]()
    var sectionFirstItem = [Int]()
    var balance = 0.0
    
    let service: AccountService = AccountEMIService()
    let licensePlateSotrage = LicensePlate()

    
    //MARK: - View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.contentInset = UIEdgeInsetsMake(48, 0, 0, 0)
        
        reloadData(patente:licensePlateSotrage.currentLicensePlate!)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refresh(sender:AnyObject) {
        reloadData(patente: licensePlateSotrage.currentLicensePlate!)
    }
    
    //MARK: -

    
    func reloadData(patente patente: String) {
        
        self.loadingSpinner.startAnimating()
        
        self.reloadSaldoData(patente: patente)
        self.reloadTableData(patente: patente, count: 5)
        
    }
    
    func reloadTableData(patente patente: String, count: Int) {

        var newTableElements = [Transaction]()
        
        self.loadRecargas(patente: patente, count: count) { (creditos: [Credit]) -> Void in
            
            for credito in creditos {
                newTableElements.append(credito)
            }
            
           self.sortElements(&newTableElements)
            
            self.loadConsumos(patente: patente, desdeHoraIni: newTableElements.last!.timestamp) { (consumos: [Debit]) -> Void in
                
                for consumo in consumos {
                    newTableElements.append(consumo)
                }
                
                self.sortElements(&newTableElements)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.tableElements = newTableElements
                    self.tableView.reloadData()
                })
            }
        }
    }

    func updateSaldo(balance:String) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingSpinner.stopAnimating()
            self.saldoLabel.text = balance
            self.refreshControl.endRefreshing()
        })
    }
    
    func sortElements(inout elements:[Transaction]) {
        
        elements.sortInPlace({ (mov1: Transaction, mov2: Transaction) -> Bool in
            if mov1.timestamp > mov2.timestamp {
                return true
            }else if mov1.timestamp == mov2.timestamp {
                if mov1.isKindOfClass(Debit) {
                    return true
                }else {
                    return false
                }
            } else {
                return false
            }
        })
    }
    
    //MARK: - IBAction

    @IBAction func refreshButtonTouched(sender: UIButton) {
        reloadData(patente: licensePlateSotrage.currentLicensePlate!)
    }
    
    //MARK: - UITableViewDelegate implementation
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.sectionItemCount.removeAll(keepCapacity: false)
        self.sectionFirstItem.removeAll(keepCapacity: false)
        var sections = 0;
        var date: String = "";
        var index: Int = 0;
        var newSaldo = self.balance
        for mov: Transaction in self.tableElements {
            var timestamp: String = mov.timestamp
            let subDate = timestamp.substringToIndex(advance(timestamp.startIndex, 10))
            if (!(date == subDate)) {
                date = subDate
                self.sectionItemCount.append(0)
                self.sectionFirstItem.append(index)
                sections++
            }
            
            mov.balance = String(format: "%.2f $", newSaldo)
            if (mov.isKindOfClass(Debit))
            {
                let amount = (mov as! Debit).amount
                newSaldo += (amount! as NSString).doubleValue
            }
            if (mov.isKindOfClass(Credit))
            {
                let amount = (mov as! Credit).amount
                newSaldo -= (amount! as NSString).doubleValue
            }
            
            self.sectionItemCount[sections - 1] = self.sectionItemCount[sections - 1] + 1
            index++
        }
        return sections
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let mov = self.tableElements[self.sectionFirstItem[section]];
        
        var timestamp: String = mov.timestamp
        let subDate = timestamp.substringToIndex(advance(timestamp.startIndex, 10))
        
        let nsDate = NSDate(dateString: subDate)
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.FullStyle
        formatter.timeStyle = NSDateFormatterStyle.NoStyle
        return formatter.stringFromDate(nsDate)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.sectionItemCount[section]
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let movimiento = self.tableElements[self.sectionFirstItem[indexPath.section] + indexPath.row]
        
        if movimiento.isKindOfClass(Credit) {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("creditoCell", forIndexPath: indexPath) as! CreditoTableViewCell
            cell.credito = movimiento as! Credit
            return cell
        }
        
        if movimiento.isKindOfClass(Debit) {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("consumoCell", forIndexPath: indexPath) as! ConsumoTableViewCell
            cell.consumo = movimiento as! Debit
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        
        if let debit = self.tableElements[self.sectionFirstItem[indexPath.section] + indexPath.row] as? Debit {

            self.parkingSelected = Parking(number: debit.number, year: debit.year, serie: debit.serie)
            
        }else{
            return nil
        }

        return indexPath
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showTarjeta" {
            let dvc = segue.destinationViewController as! TarjetaViewController
            dvc.tarjeta = self.parkingSelected
        }
    }
    
    //MARK: - Service calls
    
    func reloadSaldoData(patente licensePlate: String) {
        
        service.accountBalance(licensePlate: licensePlate) { [unowned self] (result) -> Void in
            do {
                let currentBalance = try result()
                self.updateSaldo("\(currentBalance)"+" $")
                self.balance = currentBalance
                
            } catch {
                self.updateSaldo("Unknown")
                self.balance = 0.0
            }
        }
    }
    
    func loadRecargas(patente licensePlate: String, count cant: Int, completion: ([Credit] -> Void)) {
        
        service.credits(licensePlate: licensePlate, cant: cant) { [unowned self] (result) -> Void in
            do {
                let credits = try result()
                completion(credits)
            } catch let error{
                self.showTableError(error as NSError)
            }
        }
    }
    
    func loadConsumos(patente licensePlate: String, desdeHoraIni fromTimeStamp: String, completion: ([Debit] -> Void)) {
        
        service.debits(licensePlate: licensePlate, fromTimeStamp: fromTimeStamp) { [unowned self] (result) -> Void in
            do {
                let debits = try result()
                completion(debits)
            } catch let error{
                self.showTableError(error as NSError)
            }
        }
    }
    
    func showTableError(error: NSError?) {
        print("Error: \(error)")
        //TODO: show error feedback
    }
    
}
