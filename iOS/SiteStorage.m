/*
 * Copyright (c) 2016, Jonathan Schleifer <js@heap.zone>
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

#import <ObjFW/ObjFW.h>

#import "SiteStorage.h"

@interface SiteStorage ()
- (void)_update;
@end

static OFNumber *lengthField, *legacyField;

@implementation SiteStorage
+ (void)initialize
{
	lengthField = [@(UINT8_C(0)) retain];
	legacyField = [@(UINT8_C(1)) retain];
}

- init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFFileManager *fileManager = [OFFileManager defaultManager];
		OFString *userDataPath = [OFSystemInfo userDataPath];

		if (![fileManager directoryExistsAtPath: userDataPath])
			[fileManager createDirectoryAtPath: userDataPath];

		_path = [[userDataPath stringByAppendingPathComponent:
		    @"sites.msgpack"] retain];

		@try {
			_storage = [[[OFData dataWithContentsOfFile: _path]
			    messagePackValue] mutableCopy];
		} @catch (id e) {
			_storage = [[OFMutableDictionary alloc] init];
		}

		_sites = [[[_storage allKeys] sortedArray] retain];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_path release];
	[_storage release];
	[_sites release];

	[super dealloc];
}

- (OFArray<OFString *> *)sitesWithFilter: (OFString *)filter
{
	void *pool = objc_autoreleasePoolPush();
	/*
	 * FIXME: We need case folding here, but there is no method for it yet.
	 */
	filter = [filter lowercaseString];
	OFArray *sites = [[[_storage allKeys] sortedArray]
	    filteredArrayUsingBlock: ^ (id name, size_t index) {
		if (filter == nil)
			return true;

		return [[name lowercaseString] containsString: filter];
	}];

	[sites retain];
	objc_autoreleasePoolPop(pool);
	return [sites autorelease];
}

- (bool)hasSite: (OFString *)name
{
	return (_storage[name] != nil);
}

- (size_t)lengthForSite: (OFString *)name
{
	OFDictionary *site = _storage[name];

	if (site == nil)
		@throw [OFInvalidArgumentException exception];

	return [site[lengthField] sizeValue];
}

- (bool)isSiteLegacy: (OFString *)name
{
	OFDictionary *site = _storage[name];

	if (site == nil)
		@throw [OFInvalidArgumentException exception];

	return [site[legacyField] boolValue];
}

- (void)setSite: (OFString *)site
	 length: (size_t)length
	 legacy: (bool)legacy
{
	void *pool = objc_autoreleasePoolPush();

	_storage[site] = @{
		lengthField: @(length),
		legacyField: @(legacy)
	};
	[self _update];

	objc_autoreleasePoolPop(pool);
}

- (void)removeSite: (OFString *)name
{
	[_storage removeObjectForKey: name];
	[self _update];
}

- (void)_update
{
	void *pool = objc_autoreleasePoolPush();

	[[_storage messagePackRepresentation] writeToFile: _path];

	[_sites release];
	_sites = [[[_storage allKeys] sortedArray] retain];

	objc_autoreleasePoolPop(pool);
}
@end
