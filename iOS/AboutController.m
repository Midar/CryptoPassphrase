/*
 * Copyright (c) 2016, Jonathan Schleifer <js@heap.zone>
 *
 * https://heap.zone/git/?p=scrypt-pwgen.git
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

#import "AboutController.h"

static NSString *aboutHTMLTemplate =
    @"<html>"
    @"<head>"
    @"<style type='text/css'>"
    @"body {"
    @"    font-family: sans-serif;"
    @"}"
    @""
    @"#title {"
    @"    font-size: 2.5em;"
    @"    font-weight: bold;"
    @"}"
    @""
    @"#copyright {"
    @"    font-size: 0.9em;"
    @"    font-weight: bold;"
    @"}"
    @"</style>"
    @"</head>"
    @"<body>"
    @"<div id='title'>"
    @" scrypt-pwgen {version}"
    @"</div>"
    @"<div id='copyright'>"
    @" Copyright © 2016, Jonathan Schleifer"
    @"</div>"
    @"<p name='free_software'>"
    @" scrypt-pwgen is free software and the source code is available at "
    @" <a href='https://heap.zone/scrypt-pwgen/'>here</a>."
    @"</p>"
    @"<p name='objfw'>"
    @" It makes use of the <a href='https://heap.zone/objfw/'>ObjFW</a> "
    @"framework and also uses its scrypt implementation."
    @"</p>"
    @"</body>"
    @"</html>";

@implementation AboutController
- (void)viewDidLoad
{
	self.automaticallyAdjustsScrollViewInsets = NO;

	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSString *version = infoDictionary[@"CFBundleShortVersionString"];
	NSString *aboutHTML = [aboutHTMLTemplate
	    stringByReplacingOccurrencesOfString: @"{version}"
				      withString: version];
	[self.webView loadHTMLString: aboutHTML
			     baseURL: nil];
}

- (void)dealloc
{
	[_webView release];

	[super dealloc];
}

-	       (BOOL)webView: (UIWebView*)webView
  shouldStartLoadWithRequest: (NSURLRequest*)request
	      navigationType: (UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL: request.URL
						   options: @{}
					 completionHandler: ^ (BOOL success) {
		}];
		return NO;
	}

	return YES;
}
@end
