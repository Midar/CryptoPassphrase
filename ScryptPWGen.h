#import <ObjFW/ObjFW.h>

@interface ScryptPWGen: OFObject <OFApplicationDelegate>
{
	size_t _length;
	bool _repeat;
}
@end
