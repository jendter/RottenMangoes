//
//  ReviewCell.h
//  RottenMangoes
//
//  Created by Josh Endter on 7/1/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReviewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *criticLabel;
@property (weak, nonatomic) IBOutlet UILabel *publicationLabel;
@property (weak, nonatomic) IBOutlet UILabel *reviewQuoteLabel;
@property (weak, nonatomic) IBOutlet UIView *quoteContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *freshOrRottenImage;


@end
