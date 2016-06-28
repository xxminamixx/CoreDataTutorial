//
//  RootViewController.m
//  Location
//
//  Created by Minami Kyohei on 2016/06/28.
//  Copyright © 2016年 Minami Kyohei. All rights reserved.
//

#import "RootViewController.h"
#import "AppDelegate.h"
#import "Event.h"

@interface RootViewController ()

@end

@implementation RootViewController

@synthesize eventsArray;
@synthesize managedObjectContext;
@synthesize addButton;
@synthesize locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    // タイトルを設定する。
    self.title = @"Locations";
    
    // ボタンをセットアップする。
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                   target:self
                                                                   action:@selector(addEvent)];
    //addボタン追加
    self.navigationItem.rightBarButtonItem = self.addButton;

    //locationManager初期化
    locationManager = [CLLocationManager new];
    
    // ロケーションマネージャを起動する。
    locationManager.delegate = self;
    [[self locationManager] startUpdatingLocation];
    
    eventsArray = [[NSMutableArray alloc] init];
    
    //イベントのフェッチ
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event"
                                              inManagedObjectContext:managedObjectContext];
    [request setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"corectionDate" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    // [sortDescriptors release];
    // [sortDescriptor release];
    
    // [self setEventsArray:mutableFetchResults];
    // [mutableFetchResults release];
    // [request release];
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[managedObjectContext
                                            executeFetchRequest:request error:&error] mutableCopy];
   
    // 起動時eventArrayに保持していたデータを格納処理追加
    eventsArray = mutableFetchResults;
    
    if (mutableFetchResults == nil) {
        // エラーを処理する。
    }
    
    

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
    self.eventsArray = nil;
    self.locationManager = nil;
    self.addButton = nil;
}

/*
- (void)dealloc {
    [managedObjectContext release];
    [eventsArray release];
    [locationManager release];
    [addButton release];
    [super dealloc];
}
*/
 
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [eventsArray count];
}

- (CLLocationManager *)locationManager {
    if (locationManager != nil) {
        return locationManager;
    }
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    locationManager.delegate = self;
    return locationManager;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    addButton.enabled = YES;
}
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    addButton.enabled = NO;
}

- (void)addEvent
{
    CLLocation *location = [self.locationManager location];
    /* この部分で制御され位置表示されない
    if (!location) {
        return;
    }
     */
    // Eventエンティティの新規インスタンスを作成して設定する
    Event *event = (Event *)[NSEntityDescription insertNewObjectForEntityForName:@"Event"
                                                          inManagedObjectContext:managedObjectContext];
    CLLocationCoordinate2D coordinate = [location coordinate];
    [event setLatitude:[NSNumber numberWithDouble:coordinate.latitude]];
    [event setLongitude:[NSNumber numberWithDouble:coordinate.longitude]];
    [event setCorectionDate:[NSDate date]];
    
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        // エラーを処理する。
    }
    
    [eventsArray insertObject:event atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop animated:YES];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // タイムスタンプ用の日付フォーマッタ
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    // 緯度と経度用の数値フォーマッタ
    static NSNumberFormatter *numberFormatter = nil;
    if (numberFormatter == nil) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [numberFormatter setMaximumFractionDigits:3];
    }
    static NSString *CellIdentifier = @"Cell";
    // 新規セルをデキューまたは作成する
    UITableViewCell *cell = [tableView
                             dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier] init];
    }
    Event *event = (Event *)[eventsArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [dateFormatter stringFromDate:[event corectionDate]];
    NSString *string = [NSString stringWithFormat:@"%@, %@",
                        [numberFormatter stringFromNumber:[event latitude]],
                        [numberFormatter stringFromNumber:[event longitude]]];
    cell.detailTextLabel.text = string;
    return cell;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // 指定のインデックスパスにある管理オブジェクトを削除する。
        NSManagedObject *eventToDelete = [eventsArray objectAtIndex:indexPath.row];
        [managedObjectContext deleteObject:eventToDelete];
        // 配列とTable Viewを更新する。
        [eventsArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:YES];
        // 変更をコミットする。
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // エラーを処理する。
        }
    }
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
