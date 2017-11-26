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

#import "NewPasswordGenerator.h"

@implementation NewPasswordGenerator
@synthesize length = _length, site = _site, keyfile = _keyfile;
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
	OFSHA384Hash *siteHash = [OFSHA384Hash cryptoHash];
	size_t passphraseLength, combinedPassphraseLength;
	char *combinedPassphrase;

	[siteHash updateWithBuffer: _site.UTF8String
			    length: _site.UTF8StringLength];

	if (_output != NULL) {
		of_explicit_memset(_output, 0, _length);
		[self freeMemory: _output];
	}

	_output = [self allocMemoryWithSize: _length + 1];

	passphraseLength = combinedPassphraseLength = strlen(_passphrase);
	if (_keyfile != nil) {
		if (SIZE_MAX - combinedPassphraseLength < _keyfile.count)
			@throw [OFOutOfRangeException exception];

		combinedPassphraseLength += _keyfile.count;
	}

	if ((combinedPassphrase = malloc(combinedPassphraseLength)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: combinedPassphraseLength];
	@try {
		memcpy(combinedPassphrase, _passphrase, passphraseLength);

		if (_keyfile != nil)
			memcpy(combinedPassphrase + passphraseLength,
			    _keyfile.items, _keyfile.count);

		of_scrypt(8, 524288, 2, siteHash.digest,
		    [siteHash.class digestSize], combinedPassphrase,
		    combinedPassphraseLength, _output, _length);
	} @finally {
		of_explicit_memset(combinedPassphrase, 0,
		    combinedPassphraseLength);
		free(combinedPassphrase);
	}

	for (size_t i = 0; i < _length; i++)
		_output[i] =
		    "123456789"
		    "abcdefghijkmnopqrstuvwxyz"
		    "ABCDEFGHJKLMNPQRSTUVWXYZ"
		    "#$%-=?"[_output[i] & 0x3F];
}
@end
