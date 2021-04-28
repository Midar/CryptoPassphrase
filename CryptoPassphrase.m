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

#include <unistd.h>

#import "CryptoPassphrase.h"
#import "NewPasswordGenerator.h"
#import "LegacyPasswordGenerator.h"

OF_APPLICATION_DELEGATE(CryptoPassphrase)

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
		    @"    -k  --keyfile Use the specified key file\n"
		    @"    -l  --length  Length for the derived password\n"
		    @"    -L  --legacy  Use the legacy algorithm "
		    @"(compatible with scrypt-genpass)\n"
		    @"    -r  --repeat  Repeat input\n"];
}

@implementation CryptoPassphrase
- (void)applicationDidFinishLaunching
{
	OFString *keyFilePath, *lengthString;
	const OFOptionsParserOption options[] = {
		{ 'h', @"help", 0, NULL, NULL },
		{ 'k', @"keyfile", 1, NULL, &keyFilePath },
		{ 'l', @"length", 1, NULL, &lengthString },
		{ 'L', @"legacy", 0, &_legacy, NULL },
		{ 'r', @"repeat", 0, &_repeat, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: options];
	OFUnichar option;
	OFMutableData *keyFile = nil;
	OFString *prompt;
	const char *promptCString;
	char *passphraseCString;
	size_t passphraseLength;
	OFSecureData *passphrase;

	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'h':
			showHelp(OFStdOut, true);

			[OFApplication terminate];

			break;
		case ':':
			if (optionsParser.lastLongOption != nil)
				[OFStdErr writeFormat:
				    @"%@: Argument for option --%@ missing\n",
				    [OFApplication programName],
				    optionsParser.lastLongOption];
			else
				[OFStdErr writeFormat:
				    @"%@: Argument for option -%C missing\n",
				    [OFApplication programName],
				    optionsParser.lastOption];

			[OFApplication terminateWithStatus: 1];
			break;
		case '?':
			if (optionsParser.lastLongOption != nil)
				[OFStdErr writeFormat:
				    @"%@: Unknown option: --%@\n",
				    [OFApplication programName],
				    optionsParser.lastLongOption];
			else
				[OFStdErr writeFormat:
				    @"%@: Unknown option: -%C\n",
				    [OFApplication programName],
				    optionsParser.lastOption];

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

	if (optionsParser.remainingArguments.count != 1) {
		showHelp(OFStdErr, false);

		[OFApplication terminateWithStatus: 1];
	}

	id <PasswordGenerator> generator = (_legacy
	    ? [LegacyPasswordGenerator generator]
	    : [NewPasswordGenerator generator]);
	generator.site = optionsParser.remainingArguments.firstObject;

	if (lengthString != nil) {
		bool invalid = false;

		@try {
			unsigned long long length =
			    lengthString.unsignedLongLongValue;

			if (length > SIZE_MAX)
				@throw [OFOutOfRangeException exception];

			generator.length = (size_t)length;
		} @catch (OFInvalidFormatException *e) {
			invalid = true;
		} @catch (OFOutOfRangeException *e) {
			invalid = true;
		}

		if (invalid) {
			[OFStdErr writeFormat:
			    @"%@: Invalid length: %@\n",
			    [OFApplication programName], lengthString];

			[OFApplication terminateWithStatus: 1];
		}
	}

	prompt = [OFString stringWithFormat: @"Passphrase for site \"%@\": ",
					     generator.site];
	promptCString = [prompt cStringWithEncoding: [OFLocale encoding]];

	if (keyFilePath != nil)
		keyFile = [OFMutableData dataWithContentsOfFile: keyFilePath];

	passphraseCString = getpass(promptCString);
	passphraseLength = strlen(passphraseCString);
	@try {
		passphrase = [OFSecureData dataWithCount: passphraseLength + 1
				   allowsSwappableMemory: true];
		memcpy(passphrase.mutableItems, passphraseCString,
		    passphraseLength + 1);
	} @finally {
		OFZeroMemory(passphraseCString, passphraseLength);
	}

	if (_repeat) {
		OFStringEncoding encoding = [OFLocale encoding];

		prompt = [OFString stringWithFormat:
		    @"Repeat passphrase for site \"%@\": ", generator.site];
		passphraseCString =
		    getpass([prompt cStringWithEncoding: encoding]);

		if (strcmp(passphraseCString, passphrase.items) != 0) {
			[OFStdErr writeString: @"Passphrases do not match!\n"];
			[OFApplication terminateWithStatus: 1];
		}

		OFZeroMemory(passphraseCString, strlen(passphraseCString));
	}

	generator.keyFile = keyFile;
	generator.passphrase = passphrase;

	[generator derivePassword];
	[OFStdOut writeBuffer: generator.output.items length: generator.length];
	[OFStdOut writeBuffer: "\n" length: 1];

	[OFApplication terminate];
}
@end
