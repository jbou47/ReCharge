//
//  ViewController.swift
//  ReCharge-iOS
//
//  Created by Justin Boudreau on 2/5/19.
//

import UIKit
import MapKit
import CoreLocation

class ChargingStationAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    //var annotations: [FuelStationAnnotation]
    let title: String?
    
    
    init(coordinate: CLLocationCoordinate2D, title: String) {
        self.title = title
        self.coordinate = coordinate
        super.init()
    }
}

extension ViewController: MKMapViewDelegate {
    // 1
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 2
        guard let annotation = annotation as? FuelStationAnnotation else { return nil }
        // 3
        let identifier = "marker"
        var view: FuelStationAnnotationView
        // 4
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? FuelStationAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
            //view.displayPriority = .required
        } else {
            // 5
            view = FuelStationAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.displayPriority = .required
            //view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            // change pin color/text based on station attributes
            
            if !annotation.isOpen {
                view.image = UIImage(named: "test")
    
            }
            else {
                if annotation.isPaid{
                    if annotation.isChargingAvaiable && annotation.isParkingAvaiable{
                        view.image = UIImage(named: "test")
                    }
                    else if !annotation.isChargingAvaiable && annotation.isParkingAvaiable{
                        view.image = UIImage(named: "test")
                    }
                    else if annotation.isChargingAvaiable && !annotation.isParkingAvaiable{
                        view.image = UIImage(named: "test")
                    }
                    else{
                        view.image = UIImage(named: "test")
                    }
                }
                else {
                    if annotation.isChargingAvaiable && annotation.isParkingAvaiable{
                        view.image = UIImage(named: "test")
                    }
                    else if !annotation.isChargingAvaiable && annotation.isParkingAvaiable{
                        view.image = UIImage(named: "test")
                    }
                    else if annotation.isChargingAvaiable && !annotation.isParkingAvaiable{
                        view.image = UIImage(named: "test")
                    }
                    else{
                        view.image = UIImage(named: "test")
                    }
                }
            }
            
            
            /*
            if (annotation.isPaid){
                view.glyphText = "$"
            }
            else {
                view.glyphText = "F"
            }
            
            if (annotation.isStandardCharger) {
                view.glyphTintColor = UIColor.white
            }
            
            if (annotation.isDCFastCharger) {
                view.glyphTintColor = UIColor.black
            }
            
            
            if (annotation.isChargingAvaiable) {
                view.markerTintColor = UIColor.green
            }
            else  {
                view.markerTintColor = UIColor.red
                view.glyphText = "X"
            }
            
            if (!annotation.isOpen) {
                view.markerTintColor = UIColor.gray
                view.glyphText = "!"
            }
 */
            
        }
        return view
    }
    
    // loads data into info
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        if let embeddedViewController = children.first as? InfoPaneViewController,
            let annotation = view.annotation,
            let fuelStation = annotation as? FuelStationAnnotation {
            
            embeddedViewController.annotation = fuelStation
    
            embeddedViewController.populateInfoPane(fuelStation: fuelStation)
            embeddedViewController.showInfoPane()
        }
        
    }
    
}

var userSettings : Settings = Settings(proximity: 3)
var testCount : Int = 0

class ViewController: UIViewController, InfoPaneDelegateProtocol {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var containerView: UIView!
    
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 500
    var firstLoad: Bool = true
    
    var stations = [FuelStationAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //registerMapAnnotationViews()
        
        if mapView.annotations.count != 0 {
            print("annotations removed")
            mapView.removeAnnotation(mapView!.annotations as! MKAnnotation)
        }
        
        view.addSubview(containerView)
        self.closeInfoPane()
        checkLocationServices()
        //self.mapView.showAnnotations(self.mapView.annotations, animated: true)
    
        //userSettings = loadSettings()!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // check for segue name
        if (segue.identifier == "InfoPane") {
            // set self as InfoPaneVC.delegate
            (segue.destination as! InfoPaneViewController).delegate = self;
        }
        
    }
    // InfoPane functions
    func openInfoPane() {
        containerView.isHidden = false
    }
    
    func closeInfoPane() {
        containerView.isHidden = true
    }
    
    @IBAction func unwindToMapView(_ sender: UIStoryboardSegue) {
        self.closeInfoPane()
    }
    
    // map function
    /*
    private func loadSettings() -> Settings? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Settings.ArchiveURL.path) as? Settings
    }
 */
    
    func fitAll() {
        var zoomRect            = MKMapRect.null;
        for annotation in stations {
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect       = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.01, height: 0.01);
            zoomRect            = zoomRect.union(pointRect);
        }
        //setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
    }
    
    func getNREL(coordinate: CLLocationCoordinate2D, amount: Int) {
        
        let urlString = "https://developer.nrel.gov/api/alt-fuel-stations/v1/nearest.json?api_key=OxpIDL7uE8O60BL52DC7YYp3T1mq4uy01wlLw5bK&latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&radius=\(userSettings.proximity)&fuel_type=ELEC&limit=\(amount)"
        
        guard let url = URL(string: urlString) else { return }
    
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            
            //TODO: check err
            //TODO: check response status is 200 OK
            
            guard let data = data else {return}
            
            do {
                let NRELJson = try JSONDecoder().decode(NRELJsonObj.self, from: data)
                
                print(NRELJson)
                print(urlString)
                
                for fuel_station in NRELJson.fuel_stations {
                    let temp = FuelStationAnnotation(obj: fuel_station)
                    
                    //test data
                    if testCount == 0 {
                        temp.isChargingAvaiable = true
                        temp.isPaid = false
                        temp.isOpen = true
                    }
                    if testCount == 1 {
                        temp.isChargingAvaiable = true
                        temp.isPaid = true
                        temp.isOpen = true
                    }
                    if testCount == 2 {
                        temp.isOpen = false
                    }
                    if testCount == 3 {
                        temp.isOpen = true
                        temp.isPaid = true
                        temp.isDCFastCharger = true
                    }
                    if testCount == 4 {
                        temp.isOpen = true
                        temp.isChargingAvaiable = true
                        temp.isDCFastCharger = true
                    }
                    if testCount == 5 {
                        temp.isOpen = true
                        temp.isChargingAvaiable = true
                        temp.isDCFastCharger = true
                    }
                    if testCount == 6 {
                        temp.isOpen = false
                    }
                    
                    testCount += 1

                    
                    self.addStationAnnotation(station: temp)
                }
                
            } catch let jsonErr {
                print("lat: \(coordinate.latitude)\nlon: \(coordinate.longitude)")
                print("Error serializing json: ", jsonErr)
            }
          
        }.resume()
        
    }
    
    //adds map annotations using array of stations pulled from NREL database
    func addStationAnnotation(station: FuelStationAnnotation) {
        
        var matchedCriteria = true
        
        /* check station based on availability toggles */
        
        // check if only available is toggled
        if userSettings.availableToggle && !userSettings.busyToggle {
            if !station.isChargingAvaiable {
                matchedCriteria = false
            }
        }
        // check if only busy is toggled
        else if !userSettings.availableToggle && userSettings.busyToggle {
            if station.isChargingAvaiable {
                matchedCriteria = false
            }
        }
        // check if both are toggled off
        else if !userSettings.availableToggle && !userSettings.busyToggle{
            matchedCriteria = false
        }
        
        /* check station based on cost toggles */
        
        // check if only free is toggled
        if userSettings.freeToggle && !userSettings.paidToggle {
            if station.isPaid {
                matchedCriteria = false
            }
        }
        // check if only paid is toggled
        else if !userSettings.freeToggle && userSettings.paidToggle {
            if !station.isPaid {
                matchedCriteria = false
            }
        }
        // check if both are toggled off
        else if !userSettings.freeToggle && !userSettings.paidToggle {
            matchedCriteria = false
        }
        
        /* check station based on charging type */
        
        // check if only standard is toggled
        if userSettings.standardToggle && !userSettings.fastToggle {
            if !station.isStandardCharger {
                matchedCriteria = false
            }
        }
        // check if only DC fast is toggled
        else if !userSettings.standardToggle && userSettings.fastToggle {
            if !station.isDCFastCharger {
                matchedCriteria = false
            }
        }
        // check if both are toggled off
        else if !userSettings.standardToggle && !userSettings.fastToggle {
            matchedCriteria = false
        }
        
        // check if station should be added to the map
        if matchedCriteria {
            
            self.stations.append(station)
            mapView.addAnnotation(station)
        }
    }
    
    private func registerMapAnnotationViews() {
       // mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(ChargingStationAnnotation.self))
        mapView.register(FuelStationAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    }

    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: Double(userSettings.proximity*regionInMeters),
                                                 longitudinalMeters: Double(userSettings.proximity*regionInMeters))
            
            mapView.setRegion(region, animated: true)
            
            getNREL(coordinate: location, amount: 100)
        }
    }

    private func displaySystemLocationWarning(){
        let alert = UIAlertController(title: "Location Services Permission Alert", message: "You need to give location permission to Re:Charge to experience all the features of the Re:Charge application.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Go to Settings", style: .cancel, handler:{ action in
            UIApplication.shared.open(URL(string:"App-Prefs:root=Privacy&path=LOCATION")!)
            
        }))
        alert.addAction(UIAlertAction(title: "Ignore", style: .default, handler: nil))
        
        
        self.present(alert, animated: true)
    }
    
    //check system wide location services
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
            locationManager.startUpdatingLocation()
            //mapView.userTrackingMode = MKUserTrackingMode(rawValue: 2)!
        }
        else {
            // show alert to enable location services
            displaySystemLocationWarning()
        }
    }
    
    private func displayLocationWarning(){
        let alert = UIAlertController(title: "Location Services Permission Alert", message: "You need to give location permission to Re:Charge to experience all the features of the Re:Charge application.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Go to Settings", style: .cancel, handler:{ action in
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
            
        }))
        alert.addAction(UIAlertAction(title: "Ignore", style: .default, handler: nil))
        
        
        self.present(alert, animated: true)
    }
    
    //checks app specific location services
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            break
        case .denied:
            displayLocationWarning()
            break
        case .notDetermined:
            //prompt user to allow location services when app in use
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            //location services are unavialable due to parental controls
            //show alert
            displayLocationWarning()
            break
        case .authorizedAlways:
            break
        default:
            break
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        //let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        //self.mapView.setRegion(region, animated: true)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("location auth changed")
        
        if status != CLLocationManager.authorizationStatus(){
            checkLocationAuthorization()
        }
    }
}

