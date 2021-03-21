/*
 * Copyright (c) 2016 - 2021 Jonathan Schleifer <js@nil.im>
 *
 * https://fossil.nil.im/cryptopassphrase
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

#import "NewPasswordGenerator.h"

@implementation NewPasswordGenerator
@synthesize length = _length, site = _site, keyFile = _keyFile;
@synthesize passphrase = _passphrase, output = _output;

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

- (void)derivePassword
{
	OFSHA384Hash *siteHash = [OFSHA384Hash
	    cryptoHashWithAllowsSwappableMemory: true];
	size_t passphraseLength, combinedPassphraseLength;
	OFSecureData *combinedPassphrase;
	char *combinedPassphraseItems;
	unsigned char *outputItems;

	[siteHash updateWithBuffer: _site.UTF8String
			    length: _site.UTF8StringLength];

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
	of_scrypt((of_scrypt_parameters_t){
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

	for (size_t i = 0; i < _length; i++)
		outputItems[i] =
		    "123456789"
		    "abcdefghijkmnopqrstuvwxyz"
		    "ABCDEFGHJKLMNPQRSTUVWXYZ"
		    "#$%-=?"[outputItems[i] & 0x3F];
}
@end
