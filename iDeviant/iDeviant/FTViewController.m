//
//  FTViewController.m
//  iDeviant
//
//  Created by Ondrej Rafaj on 25/09/2013.
//  Copyright (c) 2013 Fuerte Innovations. All rights reserved.
//

#import "FTViewController.h"
#import "FTDetailViewController.h"
#import "FTDownloader.h"
#import "FTBasicCell.h"
#import "FTNoResultsCell.h"
#import "FTCategoryCell.h"
#import "GCNetworkReachability.h"
#import "UIImageView+AFNetworking.h"


@interface FTViewController ()

@property (nonatomic, readonly) NSMutableArray *tempParsedItems;

@property (nonatomic, readonly) NSString *dataUrl;

@end


@implementation FTViewController


#pragma mark Positioning

- (BOOL)isTablet {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

- (BOOL)isBigPhone {
    return ([[UIScreen mainScreen] bounds].size.height == 568);
}

- (CGFloat)screenHeight {
    CGFloat h = 0;
    if ([self isTablet]) {
        h = self.isLandscape ? 748 : 1004;
    }
    else {
        h = self.isLandscape ? 300 : ([self isBigPhone] ? 548 : 460);
    }
    return h;
}

- (CGFloat)screenWidth {
    CGFloat w = 0;
    if ([self isTablet]) {
        w = self.isLandscape ? 1024 : 768;
    }
    else {
        w = self.isLandscape ? ([self isBigPhone] ? 568 : 480) : 320;
    }
    return w;
}

- (void)layoutElements {
    if (_popover) {
        [_popover dismissPopoverAnimated:YES];
    }
}

- (BOOL)isRetina {
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0));
}

- (BOOL)isOS7 {
#if defined __IPHONE_7_0
    return YES;
#else
    return NO;
#endif
    
}

#pragma mark Data

- (void)fillData {
    
}

- (void)didFinishLoading {
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    if (_refreshControl.isRefreshing) {
        [_refreshControl endRefreshing];
    }
}

- (void)loadFakeData:(NSError *)error {
    if (error && ![[GCNetworkReachability reachabilityForInternetConnection] isReachable]) {
        NSString *testFilePath = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"xml"];
        NSData *data = [NSData dataWithContentsOfFile:testFilePath];
        [FTMediaRSSParser parseData:data withCompletionHandler:^(FTMediaRSSParserFeedInfo *info, NSArray *items, NSError *error) {
            _data = items;
            [_tableView reloadData];
        }];
    }
}

- (void)getDataForParams:(NSString *)params {
    [self createLoadingSpinner];
    if (!_dataUrl) {
        _dataUrl = [[NSString stringWithFormat:@"http://backend.deviantart.com/rss.xml?q=%@%@", params, [FTConfig sortStringForFeedType:self.feedType]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    NSDate *startTime = [NSDate date];
    [FTDownloader downloadFileWithUrl:_dataUrl withProgressBlock:^(CGFloat progress) {
        NSLog(@"Download progress: %.2f", progress);
    } andSuccessBlock:^(id data, NSError *error) {
        _loadingTime = [[NSDate date] timeIntervalSinceDate:startTime];
        [FTMediaRSSParser parse:data withCompletionHandler:^(FTMediaRSSParserFeedInfo *info, NSArray *items, NSError *error) {
            [self didFinishLoading];
            _data = items;
            [_tableView reloadData];
        }];
#if (TARGET_IPHONE_SIMULATOR)
        [self loadFakeData:error];
#endif
    }];
}

- (void)getDataForSearchString:(NSString *)search andCategory:(NSString *)category {
    [self createLoadingSpinner];
    if (!_dataUrl) {
        _dataUrl = [[NSString stringWithFormat:@"http://backend.deviantart.com/rss.xml?q=%@%@", search, [FTConfig sortStringForFeedType:self.feedType]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *categoryString = @"";
        if (category && (![category isEqualToString:@""])) {
            categoryString = [NSString stringWithFormat:@"+in:%@", category];
            _dataUrl = [_dataUrl stringByAppendingString:categoryString];
        }
	}
    NSDate *startTime = [NSDate date];
	[FTDownloader downloadSingleFileWithUrl:_dataUrl withProgressBlock:^(CGFloat progress) {
        NSLog(@"Download progress: %.2f", progress);
    } andSuccessBlock:^(id data, NSError *error) {
        _loadingTime = [[NSDate date] timeIntervalSinceDate:startTime];
        [FTMediaRSSParser parse:data withCompletionHandler:^(FTMediaRSSParserFeedInfo *info, NSArray *items, NSError *error) {
            [self didFinishLoading];
            if (_searchBar.text.length >= 3) {
                _searchData = items;
                [_searchController.searchResultsTableView reloadData];
                [_searchController.searchResultsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }];
#if (TARGET_IPHONE_SIMULATOR)
        [self loadFakeData:error];
#endif
    }];
}

- (void)getDataForCategory:(NSString *)category {
	[self getDataForParams:[NSString stringWithFormat:@"in:%@+boost:popular", category]];
}

- (void)getDataForSearchString:(NSString *)search {
	[self getDataForSearchString:search andCategory:nil];
}

- (void)getFeedData {
	[self getDataForSearchString:nil];
}

- (void)reloadData {
    if (_dataUrl) {
        [self getDataForParams:nil];
    }
}

#pragma mark Creating elements

- (void)createLoadingSpinner {
    UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [ai startAnimating];
    UIBarButtonItem *loading = [[UIBarButtonItem alloc] initWithCustomView:ai];
    [self.navigationItem setRightBarButtonItem:loading animated:YES];
}

- (void)createSearchBarWithSearchOptionTitles:(NSArray *)searchOptions {
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [_searchBar setPlaceholder:FTLangGet(@"searchdesc")];
    [_searchBar setBarTintColor:[UIColor colorWithHexString:@"5E7162"]];
    if (searchOptions) {
        [_searchBar setScopeButtonTitles:searchOptions];
    }
}

- (void)createSearchBar {
    [self createSearchBarWithSearchOptionTitles:nil];
}

- (void)createSearchController {
    _searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    [_searchController.searchResultsTableView setBackgroundColor:[UIColor colorWithHexString:@"D6E0D4"]];
    [_searchController setDelegate:self];
    [_searchController setSearchResultsDataSource:self];
    [_searchController setSearchResultsDelegate:self];
    [_searchController setDisplaysSearchBarInNavigationBar:NO];
    [_tableView setTableHeaderView:_searchBar];
}

- (void)createTableView {
    [self fillData];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [_tableView setAutoresizingWidthAndHeight];
    [_tableView setBackgroundView:nil];
    [_tableView setBackgroundColor:[UIColor colorWithHexString:@"C0CDBF"]];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [self.view addSubview:_tableView];
}

- (void)createRefreshView {
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:_refreshControl];
}

- (void)createAllElements {
    
}

#pragma mark Settings

- (void)setNeedsCloseButton:(BOOL)needsCloseButton {
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:FTLangGet(@"Close") style:UIBarButtonItemStyleDone target:nil action:nil];
    [self.navigationItem setLeftBarButtonItem:close];
}

#pragma mark Initialization

- (void)setupView {
    [self.view setBackgroundColor:[UIColor colorWithHexString:@"EFEFF4"]];
    
    _feedType = FTConfigFeedTypePopular;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setupView];
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _isLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
    [self createAllElements];
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([self isTablet]) {
        return UIInterfaceOrientationMaskAll;
    }
    else {
        return UIInterfaceOrientationPortrait | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
    }
}

- (void)viewWillLayoutSubviews {
    _isLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
    [self layoutElements];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    _isLandscape = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    return YES;
}

#pragma mark Effects

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:FTLangGet(@"Ok") otherButtonTitles:nil];
    [alert show];
}

#pragma mark Table view delegate & data source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _searchController.searchResultsTableView) {
        return (_searchData.count > 0) ? _searchData.count : 1;
    }
    else {
        return _data.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return FTLangGet(@"Remove");
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 85;
}

- (void)configureArtCell:(FTArtCell *)cell forIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView {
    FTMediaRSSParserFeedItem *item = [(_searchIsEnabled ? _searchData : _data) objectAtIndex:indexPath.row];
    [cell.textLabel setText:item.title];
    [cell.detailTextLabel setText:item.descriptionText];
    
    if ([item.thumbnails count] > 0) {
        NSString *url = [(FTMediaRSSParserFeedItemThumbnail *)[item.thumbnails lastObject] urlString];
        [cell.cellImageView setImageWithURL:[NSURL URLWithString:url]];
    }
    else {
        NSLog(@"Item type: %@", item.content);
    }
}

- (FTBasicCell *)categoryCellForTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *category = [_categoryData objectAtIndex:indexPath.row];
    FTCategoryCell *cell = [FTCategoryCell categoryCellForTable:tableView withTitle:[category objectForKey:@"name"] andData:category];
    [cell setFeedType:self.feedType];
    return cell;
}

- (FTArtCell *)artCellForTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"artCellId";
    FTArtCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[FTArtCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    [self configureArtCell:cell forIndexPath:indexPath inTable:tableView];
    return cell;
}

- (FTBasicCell *)basicCellForTableView:(UITableView *)tableView {
    static NSString *cellId = @"cellId";
    FTBasicCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[FTBasicCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    [cell.textLabel setText:@"Title"];
    [cell.detailTextLabel setText:@"Description"];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _searchController.searchResultsTableView) {
        if (_searchData.count == 0) {
            return [FTNoResultsCell noResultCellForTable:tableView];
        }
        else return [self artCellForTableView:tableView withIndexPath:indexPath];
    }
    else {
        return [self basicCellForTableView:tableView];
    }
}

- (void)showDetailFor:(FTMediaRSSParserFeedItem *)item inDataSet:(NSArray *)data {
    FTDetailViewController *c = [[FTDetailViewController alloc] init];
    [c setTitle:item.title];
    [c setItems:data];
    [c setSelectedIndex:[data indexOfObject:item]];
    [self.navigationController pushViewController:c animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView == _searchController.searchResultsTableView) {
        FTMediaRSSParserFeedItem *item = [_searchData objectAtIndex:indexPath.row];
        [self showDetailFor:item inDataSet:_searchData];
    }
}

#pragma mark Search bar delegate methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [_searchController setActive:YES animated:YES];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    NSString *str = searchBar.text;
    [_searchController setActive:NO animated:YES];
    _searchController.searchBar.text = str;
    _searchData = nil;
    _searchIsEnabled = NO;
    return YES;
}

#pragma mark Search controller delegate methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    _dataUrl = nil;
    _searchIsEnabled = YES;
    if (searchString.length >= 3) {
        [self getDataForSearchString:searchString andCategory:_categoryCode];
    }
    else {
        _searchData = nil;
        [_searchController.searchResultsTableView reloadData];
    }
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    _dataUrl = nil;
    [[FTConfig sharedConfig] setFeedType:searchOption];
    [self reloadData];
    return YES;
}


@end
