//
//  MovieDetailsViewController.m
//  RottenMangoes
//
//  Created by Josh Endter on 7/1/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import "MovieDetailsViewController.h"
#import "Movie.h"
#import "Review.h"
#import "ReviewCell.h"

@interface MovieDetailsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end

@implementation MovieDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //moviePosterHighResImageView.image = movie.image;
    self.navigationItem.title = self.movie.title;
    self.synopsisLabel.text = self.movie.synopsis;
    self.criticsScoreLabel.text = [NSString stringWithFormat:@"%@%%", self.movie.criticsScore];
    
    // If the score is over
    int movieScoreInt = [self.movie.criticsScore intValue];
    if (movieScoreInt > 60) {
        self.freshOrRottenImageView.image = [UIImage imageNamed:@"freshMedium"];
    } else {
        self.freshOrRottenImageView.image = [UIImage imageNamed:@"rottenMedium"];
    }
    //self.freshOrRottenImageView.image = // change to fresh or rotten image
    
    // Fetch the poster image
    if (!self.moviePosterLowRes && !self.moviePosterHighRes) {
        [self fetchLowResPoster]; // on completion, this calls fetchHighResImage
    } else if (self.moviePosterLowRes) {
        self.moviePosterImageView.image = self.moviePosterLowRes;
        [self fetchHighResPoster];
    } else if (self.moviePosterHighRes) {
        // this should never happen, since in the original view controller, all the low res images are loaded before the light res ones are requested
        self.moviePosterImageView.image = self.moviePosterHighRes;
    }
    
    // Fetch reviews
    [self fetchReviews];

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Fetch from server

-(void)fetchHighResPoster {
    
    // These images are still giant
    // If this were a shipping app, we would be using a proxy like rotten tomatoes is to make these smaller before the device even sees them
    
    NSString *searchedString = self.movie.posterThumbnailURL;
    NSRange   searchedRange = NSMakeRange(0, [searchedString length]);
    NSString *pattern = @"/[0-9]{2}x[0-9]{2}/"; //all numbers matching format /00x00/
    NSError  *error = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:0 error:&error];
    NSArray* matches = [regex matchesInString:searchedString options:0 range: searchedRange];
    NSString* matchText;
    for (NSTextCheckingResult* match in matches) {
        matchText = [searchedString substringWithRange:[match range]];
        NSLog(@"matched text: %@", matchText);
    }
    
    if (matchText) {
        NSArray *posterThumbnailURLParts = [self.movie.posterThumbnailURL componentsSeparatedByString:matchText];
        
        NSString *urlString =[@"http://" stringByAppendingString:posterThumbnailURLParts[1]];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        NSLog(@"%@", url);
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            self.moviePosterHighRes = [UIImage imageWithData:data];
            
            // main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self.moviePosterImageView.image = self.moviePosterHighRes;
                NSLog(@"high res image");
            });
        }];
        
        [task resume];
    }
}

-(void)fetchLowResPoster {
    NSURL *url = [NSURL URLWithString:self.movie.posterThumbnailURL];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        self.moviePosterLowRes = [UIImage imageWithData:data];
        
        // main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            self.moviePosterImageView.image = self.moviePosterLowRes;     // set the poster to the low res version
            [self fetchHighResPoster];                                    // get the high res version
        });
    }];
    
    [task resume];
}

-(void)fetchReviews {
    
    if (self.movie.reviews) {
        return;
    }
    
    NSString *urlString = self.movie.reviewsURL;
    urlString = [urlString stringByAppendingString:@"?apikey=sr9tdu3checdyayjz85mff8j&page_limit=10"];
    
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSError *jsonError;
        
        NSDictionary *reviewsDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (!reviewsDictionary) {
            NSLog(@"There was an error: %@", error);
        } else {
            
            NSArray *reviews = reviewsDictionary[@"reviews"];
            
            NSMutableArray *reviewObjects = [NSMutableArray array];
            
            for (NSDictionary *aReview in reviews) {
                Review *newReview = [Review new];
                
                newReview.critic = aReview[@"critic"];
                newReview.publication = aReview[@"publication"];
                newReview.date = aReview[@"date"];
                newReview.originalScore = aReview[@"original_score"];
                newReview.freshness = aReview[@"freshness"];
                newReview.quote = aReview[@"quote"];
                newReview.reviewSourceURL = aReview[@"links"][@"review"];
                
                [reviewObjects addObject:newReview];
            }
            
            self.movie.reviews = [NSArray arrayWithArray:reviewObjects];
            
            // main thread
            dispatch_async(dispatch_get_main_queue(), ^{
//                self.objects = movieObjectsInTheaters;
//                [self.collectionView reloadData];
//                
//                [self refreshCellImages];
                [self.tableView reloadData];
                NSLog(@"Got all the reviews.");
            });
            
        }
        
    }];
    
    [task resume];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.movie.reviews.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //ReviewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reviewCell" forIndexPath:indexPath];
    
    ReviewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reviewCell" forIndexPath:indexPath];
    
    Review *reviewForCell = self.movie.reviews[indexPath.row];
    
    cell.criticLabel.text = [NSString stringWithFormat:@"%@,", reviewForCell.critic];
    cell.publicationLabel.text = reviewForCell.publication;
    cell.reviewQuoteLabel.text = reviewForCell.quote;
    
    if ([reviewForCell.freshness  isEqual: @"rotten"]) {
        cell.freshOrRottenImage.image = [UIImage imageNamed:@"rottenMedium"];
    } else {
        cell.freshOrRottenImage.image = [UIImage imageNamed:@"freshMedium"];
    }
    
    // Round the corners on the cell
    cell.quoteContainerView.clipsToBounds = YES;
    cell.quoteContainerView.layer.cornerRadius = 5.0f;
    
    //cell.criticLabel.text = @"sd";
    
//    Todo *todo = self.objects[indexPath.row];
//    NSLog(@"Making object at: %@", todo);
//    cell.todoObject = todo;
//    cell.titleLabel.text = todo.title;
//    cell.descriptionLabel.text = todo.todoDescription;
//    cell.priorityLabel.text = [todo priorityString];
//    
//    if (todo.isCompleted) {
//        NSNumber *strikeSize = [NSNumber numberWithInt:2];
//        NSDictionary *strikeThroughAttribute = [NSDictionary dictionaryWithObject:strikeSize forKey:NSStrikethroughStyleAttributeName];
//        NSString *stringToStrikeThrough = cell.titleLabel.text;
//        NSAttributedString *strikeThroughText = [[NSAttributedString alloc] initWithString:stringToStrikeThrough attributes:strikeThroughAttribute];
//        cell.titleLabel.attributedText = strikeThroughText;
//    }
//    
    return cell;
}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
