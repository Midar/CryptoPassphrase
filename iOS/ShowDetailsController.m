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

@import ObjFW_Bridge;

#import "ShowDetailsController.h"

#import "SiteStorage.h"
#import "PasswordGenerator.h"
#import "NewPasswordGenerator.h"
#import "LegacyPasswordGenerator.h"

@interface ShowDetailsController ()
- (void)_generateWithCallback: (void (^)(NSMutableString *))block;
- (void)_generateAndCopy;
- (void)_generateAndShow;
@end

static void
clearNSMutableString(NSMutableString *string)
{
	/*
	 * NSMutableString does not offer a way to zero the string.
	 * This is in the hope that setting a single character at an index just
	 * replaces that character in memory, and thus allows us to zero the
	 * password.
	 */
	for (NSUInteger i = 0; i < string.length; i++)
		[string replaceCharactersInRange: NSMakeRange(i, 1)
				      withString: @" "];
}

@implementation ShowDetailsController
- (void)dealloc
{
	[_name release];
	[_nameField release];
	[_lengthField release];
	[_legacySwitch release];
	[_keyFile release];
	[_keyFileField release];
	[_passphraseField release];
	[_mainViewController release];

	[super dealloc];
}

- (void)viewWillAppear: (BOOL)animated
{
	SiteStorage *siteStorage;
	NSIndexPath *indexPath;

	[super viewWillAppear: animated];

	siteStorage = self.mainViewController.siteStorage;
	indexPath = self.mainViewController.tableView.indexPathForSelectedRow;

	[_name release];
	_name = [self.mainViewController.sites[indexPath.row] copy];
	_length = [siteStorage lengthForSite: _name];
	_legacy = [siteStorage isSiteLegacy: _name];
	_keyFile = [[siteStorage keyFileForSite: _name] copy];

	self.nameField.text = _name.NSObject;
	self.lengthField.text = [NSString stringWithFormat: @"%zu", _length];
	self.legacySwitch.on = _legacy;
	self.keyFileField.text = _keyFile.NSObject;

	[self.mainViewController.tableView deselectRowAtIndexPath: indexPath
							 animated: YES];
}

- (BOOL)textFieldShouldReturn: (UITextField *)textField
{
	[textField resignFirstResponder];
	return NO;
}

-	  (void)tableView: (UITableView *)tableView
  didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
	[self.passphraseField resignFirstResponder];
	[tableView deselectRowAtIndexPath: indexPath
				 animated: YES];

	if (indexPath.section == 3) {
		switch (indexPath.row) {
		case 0:
			[self _generateAndCopy];
			break;
		case 1:
			[self _generateAndShow];
			break;
		}
	}
}

- (void)_generateAndCopy
{
	[self _generateWithCallback: ^ (NSMutableString *password) {
		UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
		pasteBoard.string = password;

		clearNSMutableString(password);

		UIAlertController *alert = [UIAlertController
		    alertControllerWithTitle: @"Password Generated"
				     message: @"The password has been copied "
					      @"into the clipboard."
			      preferredStyle: UIAlertControllerStyleAlert];
		[alert addAction:
		    [UIAlertAction actionWithTitle: @"OK"
					     style: UIAlertActionStyleDefault
					   handler: ^ (UIAlertAction *action) {
			[self.navigationController
			    popViewControllerAnimated: YES];
		}]];

		[self presentViewController: alert
				   animated: YES
				 completion: nil];
	}];
}

- (void)_generateAndShow
{
	[self _generateWithCallback: ^ (NSMutableString *password) {
		UIAlertController *alert = [UIAlertController
		    alertControllerWithTitle: @"Generated Passphrase"
				     message: password
			      preferredStyle: UIAlertControllerStyleAlert];
		[alert addAction:
		    [UIAlertAction actionWithTitle: @"OK"
					     style: UIAlertActionStyleDefault
					   handler: ^ (UIAlertAction *action) {
			[self.navigationController
			    popViewControllerAnimated: YES];
		}]];

		[self presentViewController: alert
				   animated: YES
				 completion: ^ {
			clearNSMutableString(password);
		}];
	}];
}

- (void)_generateWithCallback: (void (^)(NSMutableString *))block
{
	id <PasswordGenerator> generator;
	char *passphrase;
	UIStoryboard *mainStoryboard;
	UIViewController *activityController;

	if (_legacy)
		generator = [LegacyPasswordGenerator generator];
	else
		generator = [NewPasswordGenerator generator];

	generator.site = _name;
	generator.length = _length;

	if (_keyFile != nil) {
		NSString *documentDirectory;
		OFString *keyFilePath;

		if ((documentDirectory = NSSearchPathForDirectoriesInDomains(
		    NSDocumentDirectory, NSUserDomainMask, YES).firstObject) ==
		    nil) {
			NSLog(@"Could not get key files: No documents "
			    @"directory");
			return;
		}

		keyFilePath = [documentDirectory.OFObject
		    stringByAppendingPathComponent: _keyFile];
		generator.keyFile = [OFMutableData
		    dataWithContentsOfFile: keyFilePath];
	}

	passphrase = of_strdup(self.passphraseField.text.UTF8String);
	generator.passphrase = passphrase;

	mainStoryboard = [UIStoryboard storyboardWithName: @"Main"
						   bundle: nil];
	activityController = [mainStoryboard
	    instantiateViewControllerWithIdentifier: @"activityIndicator"];
	[self.navigationController.view addSubview: activityController.view];

	dispatch_async(dispatch_get_global_queue(
	    DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
		@try {
			[generator derivePassword];
		} @finally {
			if (generator.keyFile != nil)
				of_explicit_memset(
				    (void *)generator.keyFile.items, 0,
				    generator.keyFile.count);

			of_explicit_memset(passphrase, 0, strlen(passphrase));
			free(passphrase);
		}

		NSMutableString *password = [[[NSMutableString alloc]
		    initWithBytes: (char *)generator.output
			   length: generator.length
			 encoding: NSUTF8StringEncoding] autorelease];
		of_explicit_memset(generator.output, 0, generator.length);

		dispatch_sync(dispatch_get_main_queue(), ^ {
			activityController.view.hidden = YES;
			block(password);
		});
	});
}

- (IBAction)remove: (id)sender
{
	UIAlertController *alert = [UIAlertController
	    alertControllerWithTitle: @"Remove Site?"
			     message: @"Do you want to remove this site?"
		      preferredStyle: UIAlertControllerStyleAlert];
	[alert addAction:
	    [UIAlertAction actionWithTitle: @"No"
				     style: UIAlertActionStyleCancel
				   handler: nil]];
	[alert addAction:
	    [UIAlertAction actionWithTitle: @"Yes"
				     style: UIAlertActionStyleDestructive
				   handler: ^ (UIAlertAction *action) {
		[self.mainViewController.siteStorage removeSite: _name];
		[self.mainViewController reset];

		[self.navigationController popViewControllerAnimated: YES];
	}]];

	[self presentViewController: alert
			   animated: YES
			 completion: nil];
}
@end
