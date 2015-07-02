//
//  ViewController.m
//  RottenMangoes
//
//  Created by Josh Endter on 7/1/15.
//  Copyright (c) 2015 Josh Endter. All rights reserved.
//

#import "ViewController.h"
#import "Movie.h"
#import "MovieCell.h"
#import "MovieDetailsViewController.h"

@interface ViewController ()

@property NSMutableArray *objects;
@property NSMutableDictionary *lowResMovieThumbnails;
//@property NSMutableDictionary *highResMovieThumbnails;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *urlString = @"http://api.rottentomatoes.com/api/public/v1.0/lists/movies/in_theaters.json?apikey=sr9tdu3checdyayjz85mff8j&page_limit=50";
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSError *jsonError;
        
        NSDictionary *inTheatersDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (!inTheatersDictionary) {
            NSLog(@"There was an error: %@", error);
        } else {
            
            NSArray *moviesInTheaters = inTheatersDictionary[@"movies"];
            
            NSMutableArray *movieObjectsInTheaters = [NSMutableArray array];
            
            for (NSDictionary *aMovie in moviesInTheaters) {
                Movie *newMovie = [Movie new];
                
                newMovie.movieID = aMovie[@"id"];
                newMovie.title = aMovie[@"title"];
                newMovie.criticsRating = aMovie[@"ratings"][@"critics_rating"];
                newMovie.criticsScore = aMovie[@"ratings"][@"critics_score"];
                newMovie.synopsis = aMovie[@"synopsis"];
                newMovie.posterThumbnailURL = aMovie[@"posters"][@"thumbnail"];
                newMovie.reviewsURL = aMovie[@"links"][@"reviews"];
                
                
                [movieObjectsInTheaters addObject:newMovie];
            }
            
            // main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self.objects = movieObjectsInTheaters;
                [self.collectionView reloadData];
                
                [self refreshCellImages];
            });
            
        }
        
    }];
    
    [task resume];
    
    
    
                                      
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void)refreshCellImages {

    // It assumes that all movies will have a thumbnail?
    
    self.lowResMovieThumbnails = [NSMutableDictionary new];
    
    for (Movie *aMovie in self.objects) {
        
        NSURL *url = [NSURL URLWithString:aMovie.posterThumbnailURL];
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            UIImage *movieThumbnail;
            movieThumbnail = [UIImage imageWithData:data];
            
            //NSLog(@"Movie Thumbnail: %@", movieThumbnail);
            
            [self.lowResMovieThumbnails setObject:movieThumbnail forKey:aMovie.movieID];
            
            //NSLog(@"%@", self.movieThumbnails);
            
            // main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
                //NSLog(@"Image Recieved for: %@", aMovie.movieID);
            });
        }];
        
        [task resume];
        
    }
}

-(void)getHighResPosterForMovieCell:(MovieCell *)cell withMovie:(Movie *)movie {
    
    NSString *searchedString = movie.posterThumbnailURL;
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
        NSArray *posterThumbnailURLParts = [movie.posterThumbnailURL componentsSeparatedByString:matchText];
        
        NSString *urlString =[@"http://" stringByAppendingString:posterThumbnailURLParts[1]];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        NSLog(@"%@", url);
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            
            cell.moviePosterHighRes = [UIImage imageWithData:data];
            
            // main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        }];
        
        [task resume];
    }

    
}


#pragma mark - Collection View

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MovieCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"movieCell" forIndexPath:indexPath];
    
    Movie *movieForCell = self.objects[indexPath.row];

    NSString *movieID = movieForCell.movieID;
    //cell.movieID = movieID;
    cell.movieTitleLabel.text = movieForCell.title;
    
    if (cell.moviePosterHighRes) {
        // If there is a high res image, use it
        cell.movieThumbnailImageView.image = cell.moviePosterHighRes;
    } else if (self.lowResMovieThumbnails[movieID]) {
        // If not, use the low res one
        UIImage *posterThumbnailForCell = self.lowResMovieThumbnails[movieID];
        cell.movieThumbnailImageView.image = posterThumbnailForCell;
        
        // And start a download of the high res one
        //[self getHighResPosterForMovieCell:cell withMovie:movieForCell];
    }
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.objects.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped!");
    Movie *movieForCell = self.objects[indexPath.row];
    
    [self performSegueWithIdentifier:@"showMovieDetails" sender:movieForCell];
}

#pragma mark - Navigation

// TODO: Cell based, not Movie object based
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {    
    if ([[segue identifier] isEqualToString:@"showMovieDetails"]) {
        MovieDetailsViewController *destination = segue.destinationViewController;
        destination.movie = sender;
        destination.moviePosterLowRes = self.lowResMovieThumbnails[destination.movie.movieID];
        //destination.moviePosterHighRes = self.highResMovieThumbnails[destination.movie.movieID];
    }
}


@end
