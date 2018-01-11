/*
 * Copyright (c) 2016, 2017, 2018, Jonathan Schleifer <js@heap.zone>
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

#import "AddSiteController.h"
#import "SelectKeyFileController.h"

static void
showAlert(UIViewController *controller, NSString *title, NSString *message)
{
	UIAlertController *alert = [UIAlertController
	    alertControllerWithTitle: title
			     message: message
		      preferredStyle: UIAlertControllerStyleAlert];
	[alert addAction:
	    [UIAlertAction actionWithTitle: @"OK"
				     style: UIAlertActionStyleDefault
				   handler: nil]];

	[controller presentViewController: alert
				 animated: YES
			       completion: nil];
}

@implementation AddSiteController
- (void)dealloc
{
	[_nameField release];
	[_lengthField release];
	[_legacySwitch release];
	[_keyFile release];
	[_keyFileLabel release];
	[_mainViewController release];

	[super dealloc];
}

-	  (void)tableView: (UITableView *)tableView
  didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: indexPath
				 animated: YES];

	if (indexPath.section == 1 && indexPath.row == 1)
		[self performSegueWithIdentifier: @"selectKeyFile"
					  sender: self];
}

- (NSIndexPath *)tableView: (UITableView *)tableView
  willSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
	if (indexPath.section == 1 && indexPath.row == 1)
		return indexPath;

	return nil;
}

- (IBAction)done: (id)sender
{
	OFString *name = self.nameField.text.OFObject;
	OFString *lengthString = self.lengthField.text.OFObject;
	bool lengthValid = true;
	size_t length;

	if (name.length == 0) {
		showAlert(self, @"Name missing", @"Please enter a name.");
		return;
	}

	@try {
		length = (size_t)lengthString.decimalValue;

		if (length < 3 || length > 64)
			lengthValid = false;
	} @catch (OFInvalidFormatException *e) {
		lengthValid = false;
	}

	if (!lengthValid) {
		showAlert(self, @"Invalid length",
		    @"Please enter a number between 3 and 64.");
		return;
	}

	if ([self.mainViewController.siteStorage hasSite: name]) {
		showAlert(self, @"Site Already Exists",
		    @"Please pick a name that does not exist yet.");
		return;
	}

	[self.mainViewController.siteStorage setSite: name
					      length: length
					      legacy: self.legacySwitch.on
					     keyFile: self.keyFile.OFObject];
	[self.mainViewController reset];

	[self.navigationController popViewControllerAnimated: YES];
}

- (IBAction)cancel: (id)sender
{
	[self.navigationController popViewControllerAnimated: YES];
}

- (void)prepareForSegue: (UIStoryboardSegue *)segue
		 sender: (id)sender
{
	if ([segue.identifier isEqual: @"selectKeyFile"])
		[segue.destinationViewController setAddSiteController: self];
}
@end
