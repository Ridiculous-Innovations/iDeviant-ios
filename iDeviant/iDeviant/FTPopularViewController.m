//
//  FTPopularViewController.m
//  iDeviant
//
//  Created by Ondrej Rafaj on 27/09/2013.
//  Copyright (c) 2013 Fuerte Innovations. All rights reserved.
//

#import "FTPopularViewController.h"

@interface FTPopularViewController ()

@end

@implementation FTPopularViewController


#pragma mark Initialization

- (void)setupView {
    [super setupView];
    
    [super getDataForSearchString:@"special%3Apopular&type=deviation"];
}

#pragma mark Creating elements

- (void)createAllElements {
    [super createAllElements];
}


@end
