/*
 * Copyright (c) 2016, 2017, Jonathan Schleifer <js@heap.zone>
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

#include <unistd.h>

#import "ScryptPWGen.h"
#import "NewPasswordGenerator.h"
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
		    @"    -L  --legacy  Use the legacy algorithm "
		    @"(compatible with scrypt-genpass)\n"
		    @"    -r  --repeat  Repeat input\n"];
}

@implementation ScryptPWGen
- (void)applicationDidFinishLaunching
{
	OFString *lengthStr;
	const of_options_parser_option_t options[] = {
		{ 'h', @"help", 0, NULL, NULL },
		{ 'l', @"length", 1, NULL, &lengthStr },
		{ 'L', @"legacy", 0, &_legacy, NULL },
		{ 'r', @"repeat", 0, &_repeat, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: options];
	of_unichar_t option;
	char *passphrase;
	OFString *prompt;

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

	if ([[optionsParser remainingArguments] count] != 1) {
		showHelp(of_stderr, false);

		[OFApplication terminateWithStatus: 1];
	}

	id <PasswordGenerator> generator = (_legacy
	    ? [LegacyPasswordGenerator generator]
	    : [NewPasswordGenerator generator]);
	generator.site = [[optionsParser remainingArguments] firstObject];

	if (lengthStr != nil) {
		bool invalid = false;

		@try {
			generator.length = (size_t)[lengthStr decimalValue];
		} @catch (OFInvalidFormatException *e) {
			invalid = true;
		} @catch (OFOutOfRangeException *e) {
			invalid = true;
		}

		if (invalid) {
			[of_stderr writeFormat:
			    @"%@: Invalid length: %@\n",
			    [OFApplication programName], lengthStr];

			[OFApplication terminateWithStatus: 1];
		}
	}


	prompt = [OFString stringWithFormat: @"Passphrase for site \"%@\": ",
					     generator.site];
	passphrase = getpass(
	    [prompt cStringWithEncoding: [OFLocalization encoding]]);
	@try {
		if (_repeat) {
			char *passphraseCopy = of_strdup(passphrase);

			if (passphraseCopy == NULL)
				@throw [OFOutOfMemoryException exception];

			@try {
				of_string_encoding_t encoding =
				    [OFLocalization encoding];

				prompt = [OFString stringWithFormat:
				    @"Repeat passphrase for site \"%@\": ",
				    generator.site];
				passphrase = getpass(
				    [prompt cStringWithEncoding: encoding]);

				if (strcmp(passphrase, passphraseCopy) != 0) {
					[of_stderr writeString:
					    @"Passphrases do not match!\n"];
					[OFApplication terminateWithStatus: 1];
				}
			} @finally {
				of_explicit_memset(passphraseCopy, 0,
				    strlen(passphraseCopy));
				free(passphraseCopy);
			}
		}

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
