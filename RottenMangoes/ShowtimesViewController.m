//
//  ShowtimesViewController.m
//  RottenMangoes
//
//  Created by Josh Endter on 7/2/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import "ShowtimesViewController.h"
#import "Theater.h"

@import MapKit;

@interface ShowtimesViewController ()

// Outlets
@property (weak, nonatomic) IBOutlet MKMapView *localTheatersMapView;
@property (weak, nonatomic) IBOutlet UITextField *locationSearchTextField;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


// Other Properties
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) BOOL initialLocationSet;
@property (assign, nonatomic) BOOL locationArrowIsEnabled;
@property (strong, nonatomic) NSArray *localTheaters;

@end

@implementation ShowtimesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // UI Setup -----------------------
        // Set the location arrow to it's default state (which affects it's color)
        self.locationArrowIsEnabled = NO;
    
        // Round the corners on the map view
        self.localTheatersMapView.clipsToBounds = YES;
        self.localTheatersMapView.layer.cornerRadius = 5.0f;
        
        // Set the placeholder color
        UIColor *color = [UIColor whiteColor];
        self.locationSearchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Zip Code" attributes:@{NSForegroundColorAttributeName: color}];
        
        // Set the clear button color to white (OR grey?)
        /*
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:@"clearSelection"] forState:UIControlStateNormal];
        [button setFrame:CGRectMake(0.0f, 0.0f, 15.0f, 15.0f)]; // Required for iOS7
        self.locationSearchTextField.rightView = button;
        self.locationSearchTextField.rightViewMode = UITextFieldViewModeWhileEditing;
        */
    //-----------------------------------
    
    
    // Location Services
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // No initial location set
    self.initialLocationSet = NO;
    
    // No map view rotation
    self.localTheatersMapView.rotateEnabled = NO;
    
    // Test Fetch
    //[self fetchMovieDataForZipCode:@""];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Location Arrow

-(void)setLocationArrowIsEnabled:(BOOL)locationArrowIsEnabled {
    _locationArrowIsEnabled = locationArrowIsEnabled;
    if (locationArrowIsEnabled) {
        //UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [[UIImage imageNamed:@"locationArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.locationButton setImage:image forState:UIControlStateNormal];
        self.locationButton.tintColor = [UIColor colorWithRed:182.0/255.0 green:214.0/255.0 blue:80.0/255.0 alpha:1];
    } else {
        UIImage *image = [[UIImage imageNamed:@"locationArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.locationButton setImage:image forState:UIControlStateNormal];
        self.locationButton.tintColor = [UIColor grayColor];
    }
}



#pragma mark - Actions
- (IBAction)locationButtonPressed:(id)sender {
    
    if ([CLLocationManager locationServicesEnabled]) {
        // Ask for permission if we don't have it
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (status == kCLAuthorizationStatusNotDetermined) {
            [self.locationManager requestWhenInUseAuthorization];
        }
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        // Prompt User settings
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Disabled" message:@"Location services must be turned on to find theaters near you." preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        
        UIAlertAction *openAction = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if (settingsURL) {
                [[UIApplication sharedApplication] openURL:settingsURL];
            }
        }];
        [alertController addAction:openAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else if (self.localTheatersMapView.userLocation && self.initialLocationSet==YES) {
        
        // Set the location arrow to enabled
        self.locationArrowIsEnabled = YES;
        
        // Center on current location (for immediate user feedback)
            // We also do this after we update the theater list
            //[self clearMapAnnotations]; // Necessary to avoid scrolling bug
            CLLocationCoordinate2D coordinate = self.localTheatersMapView.userLocation.coordinate;
            MKCoordinateRegion region = self.localTheatersMapView.region; //MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.02, 0.02));
            [self centerMapOnLocationCoordinate:coordinate forRegion:region];
        // ---------
        
        // Update theater list
        [self updateTheaterListForLocation:[self.locationManager location]];
    }
    
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
        self.localTheatersMapView.showsUserLocation = YES;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *currentLocation = [locations lastObject];
    NSLog(@"%@", currentLocation);
    
    if (!self.initialLocationSet) {
        self.initialLocationSet = YES;
        self.locationArrowIsEnabled = YES; // Set the location arrow to the correct color
        
        // Update the on screen theater list
        [self updateTheaterListForLocation:[self.locationManager location]];
    }
}


#pragma mark - Parsing and Associated Helper Methods

-(void)updateTheaterListForLocation:(CLLocation *)location {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"Geocode failed with error: %@", error);
            return;
        } else if ([placemarks firstObject]) {
            CLPlacemark *placemark = [placemarks firstObject];
            NSString *zipCode = placemark.postalCode;
            zipCode = [zipCode stringByReplacingOccurrencesOfString:@" " withString:@""];
            [self fetchTheaterDataForZipCode:zipCode];
        }
    }];
}

-(void)updateTheaterListForString:(NSString *)string {
    // TODO: Get current region's zip code
    // pass it to the "inRegion" arguement below
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:string inRegion:nil completionHandler:^(NSArray *placemarks, NSError *error) {
        if ([placemarks firstObject]) {
            self.locationArrowIsEnabled = NO;
            
            CLPlacemark *placemark = [placemarks firstObject];
            NSString *zipCode = placemark.postalCode;
            zipCode = [zipCode stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            // Center the map on the zip code
            // This will happen when the request for theater data completes as well
            // but this means that if the fetch takes a while, the map change will still show immediately
            //[self clearMapAnnotations]; // Necessary to avoid scrolling bug
            MKCoordinateRegion mapViewCurrentRegion = [self.localTheatersMapView region];
            [self centerMapOnLocationCoordinate:placemark.location.coordinate forRegion:mapViewCurrentRegion];
            
            // Update the theater data
            [self fetchTheaterDataForZipCode:zipCode];
        }
    }];
}

-(void)clearMapAnnotations {
    // Clear the current annotations, so that pins for the previous location are not still shown
    NSMutableArray *annotations = [self.localTheatersMapView.annotations mutableCopy];   // get all annotations
    id userLocation = [self.localTheatersMapView userLocation];   // get the current user location
    if (userLocation) {
        [annotations removeObject:userLocation];  // remove the user's location from the array, so it doesn't get removed from the map view
    }
    [self.localTheatersMapView removeAnnotations:annotations];
}

-(void)fetchTheaterDataForZipCode:(NSString *)zipCode {
    NSString *urlString = @"http://lighthouse-movie-showtimes.herokuapp.com/theatres.json?address=";
    urlString = [urlString stringByAppendingString:zipCode];
    urlString = [urlString stringByAppendingString:@"&movie=Max"]; // This is hard coded because of the limitations of the example API
                                                                   // TODO: Replace API
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
            NSError *jsonError;
            
            NSDictionary *theatersInZipCodeDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            if (!theatersInZipCodeDictionary) {
                NSLog(@"There was an error: %@", error);
            } else {
                
                NSArray *theatresInZipCode = theatersInZipCodeDictionary[@"theatres"];
                
                NSMutableArray *theaterObjectsInZipCode = [NSMutableArray array];
                
                for (NSDictionary *aTheater in theatresInZipCode
                     ) {
                    Theater *newTheater = [Theater new];
                    
                    newTheater.theaterID = aTheater[@"id"];
                    newTheater.name = aTheater[@"name"];
                    newTheater.address = aTheater[@"address"];
                    newTheater.latitude = aTheater[@"lat"];
                    newTheater.longitude = aTheater[@"lng"];
                    
                    [theaterObjectsInZipCode addObject:newTheater];
                }
                
                // main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.localTheaters = [NSArray arrayWithArray:theaterObjectsInZipCode];
                    
                    // Update old annotations and add new ones
                    [self clearMapAnnotations];
                    for (Theater *theater in theaterObjectsInZipCode) {
                        [self.localTheatersMapView addAnnotation:theater];
                    }
                    
                    // Update the table view
                    [self.tableView reloadData];
                    
                    // Update the map
                    if (self.locationArrowIsEnabled) {
                        
                        CLLocationCoordinate2D coordinate = self.localTheatersMapView.userLocation.coordinate;
                        MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.025, 0.025));
                            // TODO: Set region to include all theaters
                        
                        [self centerMapOnLocationCoordinate:coordinate forRegion:region];
                        
                    } else {
                        // TODO: Use the zip code's location to center the view
                    }
                    
                    
                });
            }
    }];
    
    [task resume];
}

#pragma mark - Centering

-(void)centerMapOnLocationCoordinate:(CLLocationCoordinate2D)coordinate forRegion:(MKCoordinateRegion)region {
    [self.localTheatersMapView setCenterCoordinate:coordinate animated:YES];
    [self.localTheatersMapView setRegion:region animated:YES];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.localTheaters) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.localTheaters.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"theaterCell" forIndexPath:indexPath];
    
    Theater *theaterForCell = self.localTheaters[indexPath.row];
    
    cell.textLabel.text = theaterForCell.name;
    
    return cell;
}



#pragma mark - Text Field
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Seach button tapped in the text field
    [textField resignFirstResponder];
//    NSString *zipCode = [self zipCodeForString:textField.text];
//    [self fetchMovieDataForZipCode:zipCode];
//    self.locationArrowIsEnabled = NO;
    
    [self updateTheaterListForString:textField.text];
    
    return YES;
}







/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
