//
//  Movie.h
//  RottenMangoes
//
//  Created by Josh Endter on 7/1/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Movie : NSObject

@property (strong, nonatomic) NSString *movieID;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSNumber *criticsScore;
@property (strong, nonatomic) NSString *criticsRating;
@property (strong, nonatomic) NSString *synopsis;
@property (strong, nonatomic) NSString *posterThumbnailURL;
@property (strong, nonatomic) NSString *reviewsURL;
@property (strong, nonatomic) NSArray *reviews;

@end
