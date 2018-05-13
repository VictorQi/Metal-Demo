//
//  MainTableViewController.m
//  MetalDemo1
//
//  Created by v.q on 2018/5/7.
//  Copyright © 2018年 v.q. All rights reserved.
//

#import "MainTableViewController.h"

static NSString *const kMainTableViewCellIdentifier = @"MainTableViewCellIdentifier";

#define SegueIdentifiers (@[ \
@"HelloTriangle",            \
@"ThreeDimensionModel",      \
@"GuassBlur",                \
])                           \

@interface MainTableViewController ()

@end

@implementation MainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [SegueIdentifiers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMainTableViewCellIdentifier forIndexPath:indexPath];
    
    NSString *title = (NSString *)[SegueIdentifiers objectAtIndex:indexPath.row];
    
    cell.textLabel.text = title;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *segueId = (NSString *)[SegueIdentifiers objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:segueId sender:nil];
}

@end
