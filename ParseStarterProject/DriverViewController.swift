//
//  DriverViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Loaner on 11/29/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class DriverViewController: UITableViewController, CLLocationManagerDelegate {

    var locationManager: CLLocationManager!
    
    //set up some vars to hold the user's lat/long. Type of CLLocationDegrees object
    //when initializing a variable, if no value is given, will have to force unwrap later. Or give it a value right away so it won't crash the app
    //var latitude: CLLocationDegrees
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    
    
    //arrays to hold all of the usernames that are requesting an uber and their location
    var usernames = [String]()
    var locations = [CLLocationCoordinate2D]()
    //used to calculate the distance between the driver and rider
    var distances = [CLLocationDistance]()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        //get the location of the riders, sort it and then display it to the driver. This way, the driver does not have to tap on each rider to see their location
        //create a location manager of type CLLocationManager
        locationManager = CLLocationManager()
        //make sure to add the delegate to the viewcontroller since the location manager is asking the view controller to handle the map
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //triggers the info.plist NSLocationUsage. the if/else is needed for version checking
        if #available(iOS 8.0, *) {
            //this pops up a display to tell the user that the app is requesting for the user's location
            //must make a decision here to request for the gps when the app is in use only, or whenever we want
            //locationManager.requestWhenInUseAuthorization()
            //this authorization will always request for the gps. Also, go to Capabilities -> background modes -> location updates to turn this on/off
            locationManager.requestAlwaysAuthorization()
            
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
        
        print("locations = \(location.latitude), \(location.longitude)")
        
        
        //copied from RequestViewController. Purpose is to update the rider with the driver's locations. Get the driverResponded
        //class updated to driverLocation. Parse gives an error as only one GeoPoint field may exist in an object. Since riderRequest already has col location (as its geopoint), adding another class to Parse
        var query = PFQuery(className:"driverLocation")
        //query for the driverResponded. Target is to get the cuser's username. The cuser references the rider
        //query updated to get the username instead since the class referened has changed to driverLocation
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        
        query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded
                // Do something with the found objects. did not need to cast objects as a PFObject since it already is a PFObject
                if let objects = objects {
                    
                    //check to see if theres actually an object there
                    if objects.count > 0 {
                    
                        //this loop is to queery for the driver's geoPoint
                        for object in objects {
                            //this will create a driverResponded in parse
                            //object["driverResponded"] = PFUser.currentUser()!.username!
                            //then save the object in parse. Needs the do/try/catch
                            //do {
                            //    try object.save()
                            //} catch {}
                        
                            //added in since the example did not save the driver's username in driverResponded. The difference here is instead of just saving the object, it's querying for the objectId then saving that into parse
                            var query = PFQuery(className: "driverLocation")
                            //query to get the current user's id
                            query.getObjectInBackgroundWithId(object.objectId!, block: { (object: PFObject?, error) -> Void in
                                //check for errors
                                if error != nil {
                                print(error)
                                //the else if let object checks to see if a result is returned
                                } else if let object = object {
                                    //update the Driver's location with their current location. This must be a PFGeoPoint
                                    //driverLocation is a new column for parse
                                    object["driverLocation"] = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)
                                    object.saveInBackground()
                                
                                }
                            })
                        }
                    } else {
                        //since the check for objects contained objects (objects > 0), driverLocation can be saved to parse. Save to parse so that it can be queried and save the driver's location. 
                        //save it to Parse instead of updating an existing field in Parse
                        
                        //class name refers to the class in parse (the db's name)
                        var driverLocation = PFObject(className:"driverLocation")
                        driverLocation["username"] = PFUser.currentUser()?.username
                        //this refers to the current location of the user
                        driverLocation["driverLocation"] = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)
                        //block is removed and just needs to save
                        driverLocation.saveInBackground()
                        
                    }

                }
    
            }
        }
        
        
        //perform a query in the riderRequest to get all of the User Requests that are looking for an uber. The query has been moved to the locationManager
        //since this conflicted with a query created already, redefining the value of query instead
        query = PFQuery(className:"riderRequest")
        //use a geoPoint query for the driver so it can compare with user requests
        
        //create a PFGeoPoint from lat/long
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
        //set up a limit on the query
        query.limit = 10
        query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                //print("Successfully retrieved \(objects!.count) scores.")
                // Do something with the found objects
                if let objects = objects as? [PFObject]! {
                    
                    //clear both arrays each time it's ran, otherwise, it will clog up the array
                    self.usernames.removeAll()
                    self.locations.removeAll()
                    
                    for object in objects {
                        //do a check here to see if the driverResponded field is nil. If it is, then the driver can pick up the rider. Otherwise, filter out the rider Request in the table view so the rider doesn't show up in the TableView.
                        if object["driverResponded"] == nil {
                        
                            //do a check to see if the object can be cast as a string
                            if let username = object["username"] as? String {
                                self.usernames.append(username)
                            }
                        
                            //if let location = object["location"] as? PFGeoPoint {
                            //the location variable had to be changed as it was overriding the previously set location
                            if let returnedLocation = object["location"] as? PFGeoPoint {
                                let requestLocation = CLLocationCoordinate2DMake(returnedLocation.latitude, returnedLocation.longitude)
                            
                                //convert the PFGeoPoint into a CLLocationcoordinate and append it to the locations array
                                //this should work because the code will not fire if  the if let failed or if the object["location"] cannot be cast as a PFGeoPoint
                                self.locations.append(requestLocation)
                            
                                //convert the CLLocation2d objects into CLLocations objects
                                let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
                            
                                //find the user's location and convert user's CLLocation2D objects into CLLocation objects so it can be compred to the drivers
                                let driverCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                            
                                //now that both requestCLLocation(user) and drierCLLOcation are both the same type (CLLocation objects), find the delta
                                let distance = driverCLLocation.distanceFromLocation(requestCLLocation)
                            
                                //append this to the distances array then display it to the driver. Normally, the distane is in meters. Divide by 1000 to get the km
                                self.distances.append(distance/1000)
                            }
                        }
                    }
                    //refresh the table when viewDidLoad runs
                    self.tableView.reloadData()
                    
                    //print(self.locations)
                    //print(self.usernames)
                }
            } else {
                // Log details of the failure
                print(error)
            }
        }
        
        //no longer need to update the map
//        //centers it to the user's location
//        let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
//        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//        //then updates the mapview
//        self.map.setRegion(region, animated: true)
//        
//        //before adding the new annotation, remove all annotations from the map
//        self.map.removeAnnotations(map.annotations)
//        
//        
//        //create an annotation to keep track of the user's pin based on the lat/long
//        var pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
//        //creates a MKPointAnnotation object manager
//        var objectAnnotation = MKPointAnnotation()
//        //displays the pinLocation
//        objectAnnotation.coordinate = pinLocation
//        objectAnnotation.title = "Your location"
//        //this adds the annotation to the mapview and the map view object in storyboard
//        self.map.addAnnotation(objectAnnotation)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return usernames.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        //convert the array elements into a double so it can be reduced into smaller decimal places
        var distanceDouble = Double(distances[indexPath.row])
        
        //since there isn't a decimal format method, multiply it by then, apply Round, then divide by 10. Round removes the decimal by rounding the number up. Dividing by 10 then provides a single decimal place
        var roundedDistance = Double(round(distanceDouble * 10) / 10)
        
        // Configure the cell...
        cell.textLabel?.text = usernames[indexPath.row] + " : " + String(roundedDistance) + " km away"
        return cell
    }
    
    
    
    
    //whenever a segue happens, this configures the settings of the segue before the segue is created
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        //since theres only 1 segue in this view, probably do not need to check. always good practice to do so and check the identifier. Copied from RiderViewController
        if segue.identifier == "logoutDriver" {
            
            //from stackOF. hides the navigation bar when the cuser is logged out
            navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: true) //or animated: false
        
            
            PFUser.logOut()
            //var currentUser = PFUser.currentUser()
            //print(currentUser)
        } else if segue.identifier == "showViewRequests" {
            //prepare this segue so that it catches the id of the request and the row path when the driver taps on it
            //get the new view controller (RequestViewController) by getting the segue, then the segue's viewController. Then cast it as a RequestViewController type
            if let destination = segue.destinationViewController as? RequestViewController {
            
                //since the destination variable has accessed the RequestViewcontroller, it can access variables in the class
                //requestLocation was the variable. Locations array and getting an item in the array equivalent to the row of the table that was just tapped on
                //both of these values must exist since the driver just tapped on it
                destination.requestLocation = locations[(tableView.indexPathForSelectedRow!.row)]
                destination.requestUsername = usernames[(tableView.indexPathForSelectedRow!.row)]
                
            }
            
        }
        
    }
    
    
    
}
