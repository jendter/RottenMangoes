//
//  Theater.m
//  RottenMangoes
//
//  Created by Josh Endter on 7/2/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import "Theater.h"

@import MapKit;

@implementation Theater


#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
    return coordinate;
}

-(NSString *)title {
    return self.name;
}

-(NSString *)subtitle {
    return self.address;
}


@end
