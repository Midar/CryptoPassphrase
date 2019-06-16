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

#import <UIKit/UIKit.h>
#import <ObjFW/ObjFW.h>
#import <ObjFW_Bridge/ObjFW_Bridge.h>

#import "scrypt_pwgen-Swift.h"

@interface OFAppDelegate: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(OFAppDelegate)

void
_references_to_categories_of_ObjFW_Bridge(void)
{
	_NSString_OFObject_reference = 1;
	_OFArray_NSObject_reference = 1;
	_OFString_NSObject_reference = 1;
}

@implementation OFAppDelegate
- (void)applicationDidFinishLaunching
{
	int *argc;
	char ***argv;
	int status;

	[[OFApplication sharedApplication]
	    getArgumentCount: &argc
	   andArgumentValues: &argv];

	status = UIApplicationMain(*argc, *argv, nil,
	    NSStringFromClass([AppDelegate class]));

	[OFApplication terminateWithStatus: status];
}
@end
