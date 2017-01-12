//
//  RiderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Loaner on 11/28/15.
//  Copyright © 2015 Parse. All rights reserved.
//

//feature: can cancel an Uber while the driver is on the way by using push notifications to the driver
//billing

import UIKit
import Parse
import MapKit


class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    var locationManager: CLLocationManager!
    
    //set up some vars to hold the user's lat/long. Type CLLocationDegrees object
    //when initializing a variable, if no value is given, will have to force unwrap later. Or give it a value right away so it won't crash the app
    //var latitude: CLLocationDegrees
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    
    //using this var to determine if the user is calling an uber or if they are canceling the uber call
    var riderRequestActive = false
    //use this var to determine the state to the rider if the driver is on the way or not
    var driverOnTheWay = false
    
    @IBOutlet var map: MKMapView!
    
    @IBOutlet var callUberButton: UIButton!
    
    @IBAction func callUber(sender: AnyObject) {
        //1.initially, the riderRequestActive is set to false. When the user presses the button,
        //perform a check to determien if it is false. If it is false, then make a new request and set the riderRequestActive to true. This means the cuser now has requested an uber
        if riderRequestActive == false {
        
            //class name refers to the class in parse (the db's name)
            var riderRequest = PFObject(className:"riderRequest")
            riderRequest["username"] = PFUser.currentUser()?.username
            riderRequest["location"] = PFGeoPoint(latitude: latitude, longitude: longitude)

            riderRequest.saveInBackgroundWithBlock {(success: Bool, error: NSError?) -> Void in
                if (success) {
                    // The object has been saved.
                    
                    //if the caling uber was successful, change the title of the button
                    self.callUberButton.setTitle("Cancel Uber", forState: UIControlState.Normal)
                    
                   
                
                } else {
                    // There was a problem, check error.description
                    if #available(iOS 8.0, *) {
                        //display an alert box to the user
                        var alert = UIAlertController(title: "Could not call Uber", message: "Please try again", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    
                    } else {
                        // Fallback on earlier versions
            
                    }
                }
            }
            //2.runs through the above code, then switches the riderRequestActive to true
            riderRequestActive = true
        } else {
            //3. otherwise, if the riderRequest is already true, then cancel the request, change the button label and set the riderRequest to false
            self.callUberButton.setTitle("Call an Uber", forState: UIControlState.Normal)

            
            //if the rider request is already active, then remove all of the requests
            riderRequestActive = false
            
            //perform a query in the riderRequest to get
            var query = PFQuery(className:"riderRequest")
            //can unwrap both the current user and the username because it has already been checked at this point
            query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
            
            query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
                if error == nil {
                    // The find succeeded.
                    print("Successfully retrieved \(objects!.count) scores.")
                    // Do something with the found objects
                    if let objects = objects {
                        for object in objects {
                            object.deleteInBackground()
                        }
                    }
                } else {
                    // Log details of the failure
                    print(error)
                }
            }
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create a location manager of type CLLocationManager
        locationManager = CLLocationManager()
        //make sure to add the delegate to the viewcontroller since the location manager is asking the view controller to handle the map
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //triggers the info.plist NSLocationUsage. the if/else is needed for version checking
        if #available(iOS 8.0, *) {
            //this pops up a display to tell the user that the app is requesting for the user's location
            locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions

        }
        locationManager.startUpdatingLocation()
        
        
    }

    //method to get the user's location as it is being updated
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //location needs an unwrap
        var location: CLLocationCoordinate2D = (manager.location!.coordinate)
        
        //get the cusers lat/long in the closure
        self.latitude = location.latitude
        self.longitude = location.longitude
        
        //check if the riderRequest has been responded to. query riderRequest -> driverLocation
        var query = PFQuery(className:"riderRequest")
        //query for the cuser's username
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)

        
        query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                //print("Successfully retrieved \(objects!.count) scores.")
                // Do something with the found objects
                if let objects = objects as? [PFObject]! {
                    
                    for object in objects {
                        //a check to determine if the driverResponded field is empty or contains a value
                        if let driverUsername = object["driverResponded"] {
                            //self.callUberButton.setTitle("Driver is on the way", forState: UIControlState.Normal)
                            
                            //query for the driver's location. Use the class driverLocation and query for the geopoint (driverResponded)
                            
                            var query = PFQuery(className:"driverLocation")
                            //query for the driver's username. The driverUsername was created from the object (driverResponded)
                            query.whereKey("username", equalTo: driverUsername)
                            
                            
                            query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
                                if error == nil {
                                    // The find succeeded.
                                    //print("Successfully retrieved \(objects!.count) scores.")
                                    // Do something with the found objects
                                    if let objects = objects as? [PFObject]! {
                                        
                                        for object in objects {
                                            //check if the driverLocation is a GeoPoint and if it is
                                            if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                                //the driverLocaiton is a GeoPoint. Needs to be converted to a CLLocation
                                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                let userCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                                
                                                //compare the distance from rider to driver. CLLocation is the destination. Since location is a CLLocationCoordinate2D, needs to be further converted
                                                let distanceMeters = userCLLocation.distanceFromLocation(driverCLLocation)
                                                let distanceKM = distanceMeters / 1000
                                                //instead of showing two decimal place, one decimal place.
                                                let roundedTwoDigitDistance = Double(round(distanceKM * 10) / 10)
                                                
                                                //updates the button to the rider that the driver is X km away
                                                self.callUberButton.setTitle("Driver is \(roundedTwoDigitDistance) km away", forState: UIControlState.Normal)
                                                
                                                self.driverOnTheWay = true
                                                
                                                //1.if the driver is on the way, then create a location on the map for the rider to see.
                                                //2.since the mapview has to be rendered with both the rider and the driver, annotations and both location points must be recreated
                                                //this creates a CLLocationCoordinate from the user's locatoin
                                                let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                                                
                                                //modify the zoom so that it can contain the user and driver
                                                //the change between two latitues. This answer will be positive or negative depending on who's further. Use the absolute function to take the positive number of this delta but then multiply it by 2 (since the user's location is in the middle of the map, double the delta to get the distance away from the edges of the map) then add a bit of space (0.001) so it does not render right on the border of the map
                                                let latDelta = abs(driverLocation.latitude - location.latitude) * 2 + 0.005
                                                let lonDelta = abs(driverLocation.longitude - location.longitude) * 2 + 0.005
                                                
                                                //this controls the scaling and the delta of the mapview. smaller numbers indicate a more zoomed in level. Can use a hardcoded number like 0.1 or 0.001 to control the zoom. In this case, using the latDelta and lonDelta
                                                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                                //then updates the mapview
                                                self.map.setRegion(region, animated: true)
                                                
                                                //before adding the new annotation, remove all annotations from the map
                                                self.map.removeAnnotations(self.map.annotations)
                                                
                                                
                                                //3.create an annotation for the rider to be shown on the map by getting the rider's location
                                                var pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                                //creates a MKPointAnnotation object manager
                                                var objectAnnotation = MKPointAnnotation()
                                                //displays the pinLocation
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Your location"
                                                //this adds the rider's annotation to the mapview and the map view object in storyboard
                                                self.map.addAnnotation(objectAnnotation)
                                                
                                                //4.update the annotation for the driver to be shown on the map by updating the lat/long to use the driverLocation
                                                pinLocation = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
                                                //reusing the variable. Updating MKPointAnnotation object manager
                                                objectAnnotation = MKPointAnnotation()
                                                //update and displays the pinLocation
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Driver location"
                                                //this adds the driver's annotation to the mapview and the map view object in storyboard
                                                self.map.addAnnotation(objectAnnotation)
                                                
                                                
                                            }
                                        }
                                    }
                                }
                            }
                            
                            
                            
                        }
                    }
                }
            }
        }
            
            
        
        
        //use this state to determine if the driver is on the way. If it's false, create annotation on the map of the user's location
        if (driverOnTheWay == false) {
            
            //centers it to the user's location
            let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            //then updates the mapview
            self.map.setRegion(region, animated: true)
        
            //before adding the new annotation, remove all annotations from the map
            self.map.removeAnnotations(map.annotations)
        
        
            //create an annotation to keep track of the user's pin based on the lat/long
            var pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            //creates a MKPointAnnotation object manager
            var objectAnnotation = MKPointAnnotation()
            //displays the pinLocation
            objectAnnotation.coordinate = pinLocation
            objectAnnotation.title = "Your location"
            //this adds the annotation to the mapview and the map view object in storyboard
            self.map.addAnnotation(objectAnnotation)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //whenever a segue happens, this configures the settings of the segue before the segue is created
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        //since theres only 1 segue in this view, probably do not need to check. always good practice to do so and check the identifier
        if segue.identifier == "logoutRider" {
            
            PFUser.logOut()
            var currentUser = PFUser.currentUser()
            print(currentUser)
        }
        
    }
    
}
