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

#import "LegacyPasswordGenerator.h"

@implementation LegacyPasswordGenerator
@synthesize site = _site, keyfile = _keyfile, passphrase = _passphrase;
@synthesize output = _output;

+ (instancetype)generator
{
	return [[[self alloc] init] autorelease];
}

- init
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
	OFSHA256Hash *siteHash = [OFSHA256Hash cryptoHash];
	size_t passphraseLength, combinedPassphraseLength;
	char *combinedPassphrase;

	[siteHash updateWithBuffer: [_site UTF8String]
			    length: [_site UTF8StringLength]];

	if (_output != NULL) {
		of_explicit_memset(_output, 0, _length);
		[self freeMemory: _output];
	}

	_output = [self allocMemoryWithSize: _length + 1];

	passphraseLength = combinedPassphraseLength = strlen(_passphrase);
	if (_keyfile != nil) {
		if (SIZE_MAX - combinedPassphraseLength < [_keyfile count])
			@throw [OFOutOfRangeException exception];

		combinedPassphraseLength += [_keyfile count];
	}

	if ((combinedPassphrase = malloc(combinedPassphraseLength)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: combinedPassphraseLength];
	@try {
		memcpy(combinedPassphrase, _passphrase, passphraseLength);

		if (_keyfile != nil)
			memcpy(combinedPassphrase + passphraseLength,
			    [_keyfile items], [_keyfile count]);

		of_scrypt(8, 524288, 2, [siteHash digest],
		    [[siteHash class] digestSize], combinedPassphrase,
		    combinedPassphraseLength, _output, _length);
	} @finally {
		of_explicit_memset(combinedPassphrase, 0,
		    combinedPassphraseLength);
		free(combinedPassphrase);
	}

	/*
	 * This has a bias, however, this is what scrypt-genpass does and the
	 * legacy mode wants to be compatible to scrypt-genpass.
	 */
	_output[0] = "abcdefghijklmnopqrstuvwxyz"[_output[0] % 26];
	_output[1] = "0123456789"[_output[1] % 10];
	_output[2] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[_output[2] % 26];

	for (size_t i = 3; i < _length; i++)
		_output[i] = "abcdefghijklmnopqrstuvwxyz"
		    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		    "0123456789"[_output[i] % (26 + 26 + 10)];
}
@end
