//
//  Review.h
//  RottenMangoes
//
//  Created by Josh Endter on 7/1/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Review : NSObject

@property (strong, nonatomic) NSString *critic;
@property (strong, nonatomic) NSString *publication;
@property (strong, nonatomic) NSString *date;
@property (strong, nonatomic) NSString *originalScore;
@property (strong, nonatomic) NSString *freshness;
@property (strong, nonatomic) NSString *quote;
@property (strong, nonatomic) NSString *reviewSourceURL;

@end
