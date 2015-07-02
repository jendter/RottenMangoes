//
//  MovieDetailsViewController.h
//  RottenMangoes
//
//  Created by Josh Endter on 7/1/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Movie;

@interface MovieDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) Movie *movie;
@property (strong, nonatomic) UIImage *moviePosterLowRes;
@property (strong, nonatomic) UIImage *moviePosterHighRes;

@property (weak, nonatomic) IBOutlet UIImageView *moviePosterImageView;
@property (weak, nonatomic) IBOutlet UILabel *synopsisLabel;
@property (weak, nonatomic) IBOutlet UILabel *criticsScoreLabel;
@property (weak, nonatomic) IBOutlet UIImageView *freshOrRottenImageView;


@end
