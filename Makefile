all:
	@objfw-compile -Werror -o cryptopassphrase *.m

clean:
	rm -f *.o *~ cryptopassphrase
