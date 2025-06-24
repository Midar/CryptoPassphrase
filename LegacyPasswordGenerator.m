/*
 * Copyright (c) 2016 - 2024 Jonathan Schleifer <js@nil.im>
 *
 * https://git.nil.im/js/CryptoPassphrase
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 * OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

#import "LegacyPasswordGenerator.h"

@implementation LegacyPasswordGenerator
@synthesize site = _site, keyFile = _keyFile, passphrase = _passphrase;
@synthesize output = _output;

+ (instancetype)generator
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	_length = 16;

	return self;
}

- (void)setLength: (size_t)length
{
	if (length < 3)
		@throw [OFInvalidArgumentException exception];

	_length = length;
}

- (size_t)length
{
	return _length;
}

- (void)derivePassword
{
	OFSHA256Hash *siteHash = [OFSHA256Hash
	    hashWithAllowsSwappableMemory: true];
	size_t passphraseLength, combinedPassphraseLength;
	OFSecureData *combinedPassphrase;
	char *combinedPassphraseItems;
	unsigned char *outputItems;

	[siteHash updateWithBuffer: _site.UTF8String
			    length: _site.UTF8StringLength];
	[siteHash calculate];

	[_output release];
	_output = nil;
	_output = [[OFSecureData alloc] initWithCount: _length + 1
				allowsSwappableMemory: true];

	passphraseLength = combinedPassphraseLength = _passphrase.count - 1;
	if (_keyFile != nil) {
		if (SIZE_MAX - combinedPassphraseLength < _keyFile.count)
			@throw [OFOutOfRangeException exception];

		combinedPassphraseLength += _keyFile.count;
	}

	combinedPassphrase = [OFSecureData
		    dataWithCount: combinedPassphraseLength
	    allowsSwappableMemory: true];
	combinedPassphraseItems = combinedPassphrase.mutableItems;
	memcpy(combinedPassphraseItems, _passphrase.items, passphraseLength);

	if (_keyFile != nil)
		memcpy(combinedPassphraseItems + passphraseLength,
		    _keyFile.items, _keyFile.count);

	outputItems = _output.mutableItems;
	OFScrypt((OFScryptParameters){
		.blockSize             = 8,
		.costFactor            = 524288,
		.parallelization       = 2,
		.salt                  = siteHash.digest,
		.saltLength            = [siteHash.class digestSize],
		.password              = combinedPassphraseItems,
		.passwordLength        = combinedPassphraseLength,
		.key                   = outputItems,
		.keyLength             = _length,
		.allowsSwappableMemory = true
	});

	/*
	 * This has a bias, however, this is what scrypt-genpass does and the
	 * legacy mode wants to be compatible to scrypt-genpass.
	 */
	outputItems[0] = "abcdefghijklmnopqrstuvwxyz"[outputItems[0] % 26];
	outputItems[1] = "0123456789"[outputItems[1] % 10];
	outputItems[2] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[outputItems[2] % 26];

	for (size_t i = 3; i < _length; i++)
		outputItems[i] = "abcdefghijklmnopqrstuvwxyz"
		    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		    "0123456789"[outputItems[i] % (26 + 26 + 10)];
}
@end
