/*
 * Copyright (c) 2016, 2017, Jonathan Schleifer <js@heap.zone>
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

#import "SelectKeyFileController.h"

@implementation SelectKeyFileController
- (void)viewDidLoad
{
	NSString *documentDirectory;
	NSArray<NSString *> *keyFiles;
	NSError *error;

	[super viewDidLoad];

	if ((documentDirectory = NSSearchPathForDirectoriesInDomains(
	    NSDocumentDirectory, NSUserDomainMask, YES).firstObject) == nil) {
		NSLog(@"Could not get key files: No documents directory");
		[self.navigationController popViewControllerAnimated: YES];
		return;
	}

	keyFiles = [NSFileManager.defaultManager
	    contentsOfDirectoryAtPath: documentDirectory
				error: &error];

	if (keyFiles == nil) {
		NSLog(@"Could not get key files: %@", error);
		[self.navigationController popViewControllerAnimated: YES];
		return;
	}

	_keyFiles = [[keyFiles sortedArrayUsingSelector:
	    @selector(compare:)] retain];
}

- (void)dealloc
{
	[_keyFiles release];

	[super dealloc];
}

-  (NSInteger)tableView: (UITableView *)tableView
  numberOfRowsInSection: (NSInteger)section
{
	return _keyFiles.count + 1;
}

- (UITableViewCell *)tableView: (UITableView *)tableView
	 cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView
	    dequeueReusableCellWithIdentifier: @"keyFile"];

	if (cell == nil)
		cell = [[[UITableViewCell alloc]
		      initWithStyle: UITableViewCellStyleDefault
		    reuseIdentifier: @"keyFile"] autorelease];

	cell.textLabel.text =
	    (indexPath.row > 0 ? _keyFiles[indexPath.row - 1] : @"None");

	return cell;
}

-	  (void)tableView: (UITableView *)tableView
  didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
	self.addSiteController.keyFile =
	    (indexPath.row > 0 ? _keyFiles[indexPath.row - 1] : nil);
	self.addSiteController.keyFileLabel.text =
	    (indexPath.row > 0 ? _keyFiles[indexPath.row - 1] : @"None");

	[self.navigationController popViewControllerAnimated: YES];
}
@end
