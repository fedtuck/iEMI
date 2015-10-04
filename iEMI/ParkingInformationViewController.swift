//
//  ParkingInformationViewController.swift
//  iEMI
//
//  Created by Fer Rowies on 2/17/15.
//  Copyright (c) 2015 Rowies. All rights reserved.
//

import UIKit

let kHrs: String = NSLocalizedString("hrs", comment: "Hours abbreviation srting")
let kMin: String = NSLocalizedString("min", comment: "Minutes abbreviation srting")

class ParkingInformationViewController: NetworkActivityViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet private weak var slidingMapView: SlidingMapView!
    @IBOutlet weak var tableView: UITableView!
    
    private var parkingTime: ParkingTime? = nil
    
    let service: ParkingInformationService = ParkingInformationEMIService()
    var parking: Parking?
    
    //MARK: - UI Constants
    
    private let kParkingStatusParked: String = NSLocalizedString("parked", comment: "Parking status parked string")
    private let kParkingStatusClosed: String = NSLocalizedString("closed", comment: "Parking status closed string")
    
    private let kParkingDateTitle: String = NSLocalizedString("date", comment: "parking date title on table")
      private let kParkingStartTimeTitle: String = NSLocalizedString("start time", comment: "parking start time title on table")
      private let kParkingEndTimeTitle: String = NSLocalizedString("end time", comment: "parking end time title on table")
  private let kParkingDurationTitle: String = NSLocalizedString("duration", comment: "parking duration title on table")
      private let kParkingStatusTitle: String = NSLocalizedString("status", comment: "parking status title on table")

    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reloadParking()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Public methods
    
    func reloadParking() {
        self.loadLocation()
        self.loadTime()
    }
    
    // MARK: - Private methods
    
    private let kErrorLoadingParkingDataText = NSLocalizedString("Error loading parking data. Try again please.", comment: "error loading parking data message")
    
    private let kLoadingParkingDataText = NSLocalizedString("Loading parking data", comment: "loading parking data message")
    
    private func showError(error: NSError?, errorMessage: String?) {
        
        if let currentError = error {
            print("Error: \(currentError.localizedDescription)")
        }
        self.showErrorView(errorMessage, animated:false)
    }
    
    // MARK: - UITableViewDataSource implementation
    
    private let kParkingInformationCellId = "parkingInformationCell"
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.parkingTime?.parkingStatus == ParkingStatus.Closed {
            return 5
        } else {
            return 3
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(kParkingInformationCellId, forIndexPath: indexPath)
    
        guard let currentParkingTime = self.parkingTime else {
            return cell
        }
        
        var title: String? = ""
        var content: String? = ""
        
        if currentParkingTime.parkingStatus == ParkingStatus.Closed {
            
            var startTime = currentParkingTime.startTime! as NSString
            startTime = startTime.substringFromIndex(11) + " " + kHrs
        
            var endTime = currentParkingTime.endTime! as NSString
            endTime = endTime.substringFromIndex(11) + " " + kHrs
            
            let duration = currentParkingTime.parkingTime!
            let hours = Int(duration)!/60 as Int
            let minutes = Int(duration)! % 60
            let parkingDuration = String("\(hours) \(kHrs) \(minutes) \(kMin)")
            
            switch indexPath.row {
            case 0:
                title = kParkingDateTitle
                content = self.parkingTime?.date
                break
            case 1:
                title = kParkingDurationTitle
                content = parkingDuration
                break
            case 2:
                title = kParkingStartTimeTitle
                content = startTime as String
                break
            case 3:
                title = kParkingEndTimeTitle
                content = endTime as String
                break
            case 4:
                title = kParkingStatusTitle
                content = currentParkingTime.parkingStatus == ParkingStatus.Closed ? kParkingStatusClosed : kParkingStatusParked
                break
            default: break
            }
        } else {
            
            var startTime = currentParkingTime.startTime! as NSString
            startTime = startTime.substringFromIndex(11) + " " + kHrs
            
            switch indexPath.row {
            case 0:
                title = kParkingDateTitle
                content = self.parkingTime?.date
                break
            case 1:
                title = kParkingStartTimeTitle
                content = startTime as String
                break
            case 2:
                title = kParkingStatusTitle
                content = currentParkingTime.parkingStatus == ParkingStatus.Closed ? kParkingStatusClosed : kParkingStatusParked
                break
            default: break
            }
        }
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = content
        
        return cell
    }
    
    // MARK: - UITableViewDelegate implementation
    
    // MARK: - Service calls
    
    private func loadLocation() {
        
        guard let currentParking = self.parking else {
            self.showError(nil, errorMessage: kErrorLoadingParkingDataText)
            return
        }
        
        service.location(currentParking) { [weak self] (result) -> Void in
            
            do {
                let parkingLocation = try result()
                self?.slidingMapView.address = parkingLocation.fullAddress
                
            } catch let error as NSError{
                self?.showError(error, errorMessage: self?.kErrorLoadingParkingDataText)
            }
        }
    }
    
    private func loadTime() {
        
        guard let currentParking = self.parking else {
            self.showError(nil, errorMessage: kErrorLoadingParkingDataText)
            return
        }
        
        self.showLoadingView(kLoadingParkingDataText, animated: false)

        service.time(currentParking) { [weak self] (result) -> Void in
            
            do {
                let parkingTime = try result()
                self?.parkingTime = parkingTime
                self?.tableView.reloadData()
                self?.hideLoadingView(animated: true)
                
            } catch let error as NSError{
                self?.showError(error, errorMessage: self?.kErrorLoadingParkingDataText)
            }
        }
    }
    
}
