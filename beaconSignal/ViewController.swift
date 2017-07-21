//
//  ViewController.swift
//  beaconSignal
//
//  Created by Cameron Wilcox on 7/17/17.
//  Copyright © 2017 Cameron Wilcox. All rights reserved.
//

import UIKit
import CoreLocation
import QuartzCore
import CoreBluetooth


class ViewController: UIViewController, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
    
    let locationManager = CLLocationManager()
    let uuid = NSUUID(uuidString:"5122CBA8-9020-40B5-A252-AC84F6041A02")
    var beaconRegion: CLBeaconRegion!
    var isBroadcasting = false
    var bluetoothPeripheralManager: CBPeripheralManager!
    var dataDictionary = NSDictionary()
    var longitude = CLLocationDegrees()
    var latitude = CLLocationDegrees()
    var currentLng = CLLocationDegrees()
    var currentLat = CLLocationDegrees()

    var secDataDictionary = NSDictionary()
    var secBeaconRegion : CLBeaconRegion!
    var secBluetoothPerhipheralManager: CBPeripheralManager!
    let secondUuid = NSUUID(uuidString:"FEE8B592-C1B2-4DEC-B210-0DC8C38C36F5")
    var secIsBroadcasting = false
    
    var advertisingFirst = true
    
    @IBOutlet var startButton: UIButton!
    
    @IBOutlet var calibratingLabel: UILabel!
    @IBOutlet var signalDotView: UIView!
    @IBOutlet var signalDotGrowView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        bluetoothPeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        secBluetoothPerhipheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        
        
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        startButton.layer.cornerRadius = 23.5
        
        signalDotGrowView.layer.borderColor = UIColor.red.cgColor
        
        signalDotView.layer.cornerRadius = 5
        signalDotGrowView.layer.borderWidth = 0.3
        signalDotGrowView.layer.cornerRadius = 5
        
        calibratingLabel.isHidden = true
        
        let gradient: CAGradientLayer = CAGradientLayer()
        let colorTop = UIColor(red: 112.0/255.0, green: 219.0/255.0, blue: 155.0/255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 86.0/255.0, green: 197.0/255.0, blue: 238.0/255.0, alpha: 1.0).cgColor
        
        gradient.colors = [colorTop, colorBottom]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = startButton.bounds
        gradient.cornerRadius = 23.5
        startButton.layer.addSublayer(gradient)
        
    }
    
    @IBAction func startAdvertising(_ sender: AnyObject) {
        UIView.animate(withDuration: 2.0, delay: 1.0, options: [.repeat], animations: {
            self.signalDotGrowView.transform = CGAffineTransform(scaleX: 50.0, y: 50.0)
            self.signalDotGrowView.alpha = 0.0
        }, completion: nil)
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { (timer) in
            print(self.advertisingFirst);
            
            if self.advertisingFirst == true {
                self.startBroadcast()
            } else {
                self.secondStartBroadcast()
            }
            
            self.advertisingFirst = !self.advertisingFirst
        }
    }

    func startBroadcast() {
        let when = DispatchTime.now()
        calibratingLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.calibratingLabel.isHidden = true
            let latDecimalPlaces = self.latitude.truncatingRemainder(dividingBy: 1)
            var latTrimmed = String(latDecimalPlaces).components(separatedBy: ".")
            
            var latString = latTrimmed[1]
            var scndLatString = latTrimmed[1]
            
            latString.remove(at: latString.startIndex)
            scndLatString.remove(at: scndLatString.startIndex)
            
            scndLatString = String(scndLatString.characters.dropFirst(4))
            
            
            latString =  latString.substring(to:latString.index(latString.startIndex, offsetBy: 4))
            scndLatString = scndLatString.substring(to: scndLatString.index(scndLatString.startIndex, offsetBy: 5))
            
            let latInt = Int(latString)!
            let scndLatInt = Int(scndLatString)! / 2
            if !self.isBroadcasting {
                if self.bluetoothPeripheralManager.state == .poweredOn
                {
                    let  major: CLBeaconMajorValue = UInt16(latInt)
                    let minor: CLBeaconMinorValue = UInt16(scndLatInt)
                    self.beaconRegion = CLBeaconRegion(proximityUUID: self.uuid! as UUID, major: major, minor: minor, identifier: "DateId3")
                    
                    
                    self.dataDictionary = self.beaconRegion.peripheralData(withMeasuredPower: nil)
                    self.bluetoothPeripheralManager.startAdvertising(self.dataDictionary as? [String: Any])
                    
                    print("BROADCASTING...")
                    
                    self.isBroadcasting = true
                    
                    self.startButton.titleLabel?.text = "Stop Broadcasting"
                    
//                    UIView.animate(withDuration: 2.0, delay: 1.0, options: [.repeat], animations: {
//                        self.signalDotGrowView.transform = CGAffineTransform(scaleX: 50.0, y: 50.0)
//                        self.signalDotGrowView.alpha = 0.0
//                    }, completion: nil)
                    
                }
            } else {
                
                self.startButton.titleLabel?.text = "Stop Broadcasting"
                
                self.signalDotGrowView.layer.removeAllAnimations()
                
                self.bluetoothPeripheralManager.stopAdvertising()
                
                self.isBroadcasting = false
                
                self.calibratingLabel.isHidden = true
            }

        }
    }
    
    func secondStartBroadcast() {
        let when = DispatchTime.now()

        DispatchQueue.main.asyncAfter(deadline: when) {
            self.calibratingLabel.isHidden = true

            let lngDecimalPlaces = self.longitude.truncatingRemainder(dividingBy: 1)
            var lngTrimmed = String(lngDecimalPlaces).components(separatedBy: ".")
            
            var lngString = lngTrimmed[1]
            var scndLngString = lngTrimmed[1]
            
            lngString.remove(at: lngString.startIndex)
            scndLngString.remove(at: scndLngString.startIndex)
            
            scndLngString = String(scndLngString.characters.dropFirst(4))
            
            
            lngString =  lngString.substring(to:lngString.index(lngString.startIndex, offsetBy: 4))
            scndLngString = scndLngString.substring(to: scndLngString.index(scndLngString.startIndex, offsetBy: 5))
            
            let lngInt = Int(String("1"+lngString))!
            let scndLngInt = Int(scndLngString)! / 2
            //        latString = String(latInt)
            //        lngString = String(lngInt)
//            print(lngString)
//            print(scndLngString)
            if !self.secIsBroadcasting {
                if self.secBluetoothPerhipheralManager.state == .poweredOn
                {
                    let  major: CLBeaconMajorValue = UInt16(lngInt)
                    let minor: CLBeaconMinorValue = UInt16(scndLngInt)
                    self.secBeaconRegion = CLBeaconRegion(proximityUUID: self.secondUuid! as UUID, major: major, minor: minor, identifier: "SECOND")
                    
                    
                    self.secDataDictionary = self.secBeaconRegion.peripheralData(withMeasuredPower: nil)
                    self.secBluetoothPerhipheralManager.startAdvertising(self.secDataDictionary as? [String: Any])
                    
                    print("BROADCASTING...")
                    
                    self.secIsBroadcasting = true
                    
                    self.startButton.titleLabel?.text = "Stop Broadcasting"
                    
                }
            } else {
                
                self.startButton.titleLabel?.text = "Stop Broadcasting"
                
                self.signalDotGrowView.layer.removeAllAnimations()
                
                self.secBluetoothPerhipheralManager.stopAdvertising()
                
                self.secIsBroadcasting = false
            }
            
        }
    }
    
//    func doMath(_ origional: CLLocationDegrees, current: CLLocationDegrees){
//        var trimmedCurrent = String(format: "%.2f", current)
//        var trimmedOrigional = String(format: "%.2f", origional)
//        var leftover = Double(trimmedCurrent)! - Double(trimmedCurrent)!
//        print(leftover)
//        return
//    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations[0]
        
        currentLat = location.coordinate.latitude
        currentLng = location.coordinate.longitude
        
        longitude = currentLng
        latitude = currentLat
        
        print(longitude)
        print(latitude)

    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }

}

