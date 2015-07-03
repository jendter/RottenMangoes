//
//  Theater.h
//  RottenMangoes
//
//  Created by Josh Endter on 7/2/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Theater : NSObject

@property (strong, nonatomic) NSString *theaterID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSNumber *latitude;
@property (strong, nonatomic) NSNumber *longitude;


@end
