//
//  IDSearchController.m
//  iDeviant
//
//  Created by Ondrej Rafaj on 24.1.11.
//  Copyright 2011 Fuerte International. All rights reserved.
//

#import "IDSearchController.h"
#import "Reachability.h"
#import "IDViewController.h"

@implementation IDSearchController

@synthesize babaImageView, lupaImageView;

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[super setIsSearchBar:YES];
	
	[self setTitle:[IDLang get:@"search"]];
		
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
//	[imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
//	[imageView setContentMode:UIViewContentModeScaleAspectFit];
//	[imageView setContentMode:UIViewContentModeCenter];
    [imageView setImage:[UIImage imageNamed:@"search_anim_1@2x.png"]];
    [self.view addSubview:imageView];
	
	
	
	if (([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) || ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight))
		[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"DA_bg-empty-l@2x"]]];
	else
		[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"DA_bg-empty-p@2x"]]];
}

-(void)viewWillAppear:(BOOL)animated{
//    [imageView setCenter:self.view.center];
	[table setFrame:self.view.bounds];
	
	[table reloadData];
	[self backgroundImage];
}

#pragma mark - Background image

-(void)backgroundImage {
		
	Reachability *r = [Reachability reachabilityWithHostName:@"www.apple.com"];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
	
	if (internetStatus == NotReachable) {
		
		[searchBarHeader setUserInteractionEnabled:NO];
		
		[imageView setImage:[UIImage imageNamed:@"DD_grandma@2x.png"]];
		
		if (([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) || ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)) {
			[imageView setFrame: CGRectMake(0.0, 0.0, 160.0, 200.0)];
			imageView.center = CGPointMake(self.view.center.x, self.view.center.y + 20);
		} else {
			[imageView setFrame: CGRectMake(0.0, 0.0, 200.0, 250.0)];
			[imageView setCenter:self.view.center]; 
		}
    } else {		
		[searchBarHeader setUserInteractionEnabled:YES];
		
		[imageView setImage:[UIImage imageNamed:@"search_anim_1@2x.png"]];

		[imageView setFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
		[imageView setCenter:self.view.center];
	}
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{	
	if (([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) || ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight))
		[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"DA_bg-empty-l@2x"]]];
	else
		[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"DA_bg-empty-p@2x"]]];
	
	[table setFrame:self.view.bounds];
	
	[table reloadData];
	[self backgroundImage];
}

#pragma mark Table delegates

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([data count] > 0)
		return [super tableView:tableView heightForRowAtIndexPath:indexPath];
	else
        if (isLandscape)
			return 217;
		else
			return 372;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int count = [data count];
	
	if (count == 0) {
        [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [tableView setScrollEnabled:FALSE];
        [imageView setHidden:NO];
    } else{
        [tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [tableView setScrollEnabled:TRUE];
        [imageView setHidden:YES];
    }
	
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([data count] > 0)
		return [super tableView:tableView cellForRowAtIndexPath:indexPath];
	else {
		static NSString *cellIdentifier = @"EmptyCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		
		if (cell == nil)
            cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
        
		cell.layer.shouldRasterize = YES;
		cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
		
		return cell;
	}
}

@end
