#import <ObjFW/ObjFW.h>

@interface LegacyPasswordGenerator: OFObject
{
	size_t _length;
	OFString *_site;
	const char *_passphrase;
	unsigned char *_output;
}

@property size_t length;
@property (copy) OFString *site;
@property const char *passphrase;
@property (readonly) unsigned char *output;

+ (instancetype)generator;
- (void)derivePassword;
@end
