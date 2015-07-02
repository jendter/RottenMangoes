//
//  MovieCell.h
//  RottenMangoes
//
//  Created by Josh Endter on 7/1/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MovieCell : UICollectionViewCell

//@property (strong, nonatomic) NSString *movieID;
@property (weak, nonatomic) IBOutlet UIImageView *movieThumbnailImageView;
@property (strong, nonatomic) UIImage *moviePosterLowRes;
@property (strong, nonatomic) UIImage *moviePosterHighRes;
@property (weak, nonatomic) IBOutlet UILabel *movieTitleLabel;



@end
