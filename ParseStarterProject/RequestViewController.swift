//
//  RequestViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Loaner on 11/30/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit


class RequestViewController: UIViewController, CLLocationManagerDelegate {


    @IBOutlet var map: MKMapView!
    

    @IBAction func pickUpRider(sender: AnyObject) {
        //perform a query in the when the button is tapped. Find the requestUsername
        var query = PFQuery(className:"riderRequest")
        //can unwrap both the current user and the username because it has already been checked at this point
        query.whereKey("username", equalTo: requestUsername)
        
        query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded
                // Do something with the found objects. did not need to cast objects as a PFObject since it already is a PFObject
                if let objects = objects {
                    for object in objects {
                        //this will create a driverResponded in parse
                        object["driverResponded"] = PFUser.currentUser()!.username!
                        //then save the object in parse. Needs the do/try/catch
                        do {
                            try object.save()
                        } catch {}
                        
                        //added in since the example did not save the driver's username in driverResponded. The difference here is instead of just saving the object, it's querying for the objectId then saving that into parse
                        var query = PFQuery(className: "riderRequest")
                        //query to get the current user's id
                        query.getObjectInBackgroundWithId(object.objectId!, block: { (object: PFObject?, error) -> Void in
                            //check for errors
                            if error != nil {
                                print(error)
                            } else if let object = object {
                                //if there are no errors, save the cuser's username in driverResponded
                                //if this still does not save the username in parse, check the ACL and make sure it has "Public Read Write"
                                object["driverResponded"] = PFUser.currentUser()!.username!
                                object.saveInBackground()
                                
                                let requestCLLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
                                
                                //the CLGeocoder should return an array of placemarks of CLPlaceMarks type
                                CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: { (placemarks, error) -> Void in
                                    if error != nil {
                                        print(error!)
                                    } else {
                                    
                                        if placemarks!.count > 0 {
                                            //take the first placemarks from the array (placemark)
                                            let pm = placemarks![0] as! CLPlacemark
                                            
                                            //convert a CLPlacemark to a MKPlacemark
                                            let mkPm = MKPlacemark(placemark: pm)
                                            
                                            //from stackOF. Need to get your current address using PlaceMark. Need to convert from CLLocation2D to a placemark
                                            var mapItem = MKMapItem(placemark: mkPm)
                                            
                                            mapItem.name = self.requestUsername
                                            
                                            //You could also choose: MKLaunchOptionsDirectionsModeWalking
                                            var launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                                            
                                            mapItem.openInMapsWithLaunchOptions(launchOptions)
                                            
                                            
                                        } else {
                                            print("Problem with the data received from geocoder")
                                        }
                                    }
                                })
                            }
                        })
                    }
                } else {
                // Log details of the failure
                print(error)
            }
            }
        }
    }
    
    //store the location. This is the same type as the DriverViewController's location var. Make sure to initialize the variables with a default value or it runs into an initializer error
    var requestLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var requestUsername: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print(requestUsername)
        print(requestLocation)
        
        

        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        //then updates the mapview
        self.map.setRegion(region, animated: true)
        
        //before adding the new annotation, remove all annotations from the map
        self.map.removeAnnotations(map.annotations)
        
        //creates a MKPointAnnotation object manager
        var objectAnnotation = MKPointAnnotation()
        //displays the pinLocation
        objectAnnotation.coordinate = requestLocation
        objectAnnotation.title = requestUsername
        //this adds the annotation to the mapview and the map view object in storyboard
        self.map.addAnnotation(objectAnnotation)

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
