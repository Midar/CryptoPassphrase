#import "LegacyPasswordGenerator.h"

@implementation LegacyPasswordGenerator
@synthesize length = _length, site = _site, passphrase = _passphrase;
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

- (void)derivePassword
{
	OFSHA256Hash *siteHash = [OFSHA256Hash cryptoHash];
	[siteHash updateWithBuffer: [_site UTF8String]
			    length: [_site UTF8StringLength]];

	if (_output != NULL) {
		of_explicit_memset(_output, 0, _length);
		[self freeMemory: _output];
	}

	_output = [self allocMemoryWithSize: _length + 1];

	of_scrypt(8, 524288, 2, [siteHash digest],
	    [[siteHash class] digestSize], _passphrase, strlen(_passphrase),
	    _output, _length);

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
