#include <string.h>

#include <unistd.h>

#import "ScryptPWGen.h"
#import "LegacyPasswordGenerator.h"

OF_APPLICATION_DELEGATE(ScryptPWGen)

static void
showHelp(OFStream *output, bool verbose)
{
	[output writeFormat: @"Usage: %@ [-hlr] site\n",
			     [OFApplication programName]];

	if (verbose)
		[output writeString:
		    @"\n"
		    @"Options:\n"
		    @"    -h  --help    Show this help\n"
		    @"    -l  --length  Length for the derived password\n"
		    @"    -r  --repeat  Repeat input\n"];
}

@implementation ScryptPWGen
- (void)applicationDidFinishLaunching
{
	OFString *lengthStr;
	const of_options_parser_option_t options[] = {
		{ 'h', @"help", 0, NULL, NULL },
		{ 'l', @"length", 1, NULL, &lengthStr },
		{ 'r', @"repeat", 0, &_repeat, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: options];
	of_unichar_t option;
	size_t length;
	char *passphrase;
	OFString *site, *prompt;

	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'h':
			showHelp(of_stdout, true);

			[OFApplication terminate];

			break;
		case ':':
			if (optionsParser.lastLongOption != nil)
				[of_stderr writeFormat:
				    @"%@: Argument for option --%@ missing\n",
				    [OFApplication programName],
				    optionsParser.lastLongOption];
			else
				[of_stderr writeFormat:
				    @"%@: Argument for option -%C missing\n",
				    [OFApplication programName],
				    optionsParser.lastOption];

			[OFApplication terminateWithStatus: 1];
			break;
		case '?':
			if (optionsParser.lastLongOption != nil)
				[of_stderr writeFormat:
				    @"%@: Unknown option: --%@\n",
				    [OFApplication programName],
				    optionsParser.lastLongOption];
			else
				[of_stderr writeFormat:
				    @"%@: Unknown option: -%C\n",
				    [OFApplication programName],
				    optionsParser.lastOption];

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

	if (lengthStr != nil) {
		@try {
			length = (size_t)[lengthStr decimalValue];

			if (length < 3)
				@throw [OFInvalidFormatException exception];
		} @catch (OFInvalidFormatException *e) {
			[of_stderr writeFormat:
			    @"%@: Invalid length: %@\n",
			    [OFApplication programName], lengthStr];

			[OFApplication terminateWithStatus: 1];
		}
	}

	if ([[optionsParser remainingArguments] count] != 1) {
		showHelp(of_stderr, false);

		[OFApplication terminateWithStatus: 1];
	}

	prompt = [OFString stringWithFormat: @"Passphrase for site \"%@\": ",
					     site];

	LegacyPasswordGenerator *generator =
	    [LegacyPasswordGenerator generator];
	generator.length = length;
	generator.site = [[optionsParser remainingArguments] firstObject];

	passphrase = getpass(
	    [prompt cStringWithEncoding: [OFSystemInfo native8BitEncoding]]);
	@try {
		generator.passphrase = passphrase;

		[generator derivePassword];
		@try {
			[of_stdout writeBuffer: generator.output
					length: generator.length];
			[of_stdout writeBuffer: "\n"
					length: 1];
		} @finally {
			of_explicit_memset(generator.output, 0,
			    generator.length);
		}
	} @finally {
		of_explicit_memset(passphrase, 0, strlen(passphrase));
	}

	[OFApplication terminate];
}
@end
