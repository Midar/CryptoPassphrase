/*
 * Copyright (c) 2016 - 2019 Jonathan Schleifer <js@heap.zone>
 *
 * https://heap.zone/git/scrypt-pwgen.git
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <ObjFW_Bridge/ObjFW_Bridge.h>

#import "MainViewController.h"

#import "AddSiteController.h"
#import "ShowDetailsController.h"

@implementation MainViewController
- (void)viewDidLoad
{
	[super viewDidLoad];

	_siteStorage = [[SiteStorage alloc] init];
	[self reset];
}

- (void)dealloc
{
	[_sites release];
	[_siteStorage release];
	[_searchBar release];
	[_tableView release];

	[super dealloc];
}

- (void)reset
{
	void *pool = objc_autoreleasePoolPush();

	_searchBar.text = @"";
	self.sites = [_siteStorage sitesWithFilter: nil];
	[_tableView reloadData];

	objc_autoreleasePoolPop(pool);
}

-  (NSInteger)tableView: (UITableView *)tableView
  numberOfRowsInSection: (NSInteger)section
{
	return self.sites.count;
}

- (UITableViewCell *)tableView: (UITableView *)tableView
	 cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView
	    dequeueReusableCellWithIdentifier: @"site"];

	if (cell == nil)
		cell = [[[UITableViewCell alloc]
		      initWithStyle: UITableViewCellStyleDefault
		    reuseIdentifier: @"site"] autorelease];

	cell.textLabel.text = self.sites[indexPath.row].NSObject;

	return cell;
}

- (void)searchBar: (UISearchBar *)searchBar
    textDidChange: (NSString *)searchText
{
	self.sites = [_siteStorage sitesWithFilter: _searchBar.text.OFObject];
	[_tableView reloadData];
}

-	  (void)tableView: (UITableView *)tableView
  didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
	[self performSegueWithIdentifier: @"showDetails"
				  sender: self];
}

- (void)prepareForSegue: (UIStoryboardSegue *)segue
		 sender: (id)sender
{
	if ([segue.identifier isEqual: @"addSite"] ||
	    [segue.identifier isEqual: @"showDetails"])
		[segue.destinationViewController setMainViewController: self];
}
@end
