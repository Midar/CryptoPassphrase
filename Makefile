all:
	@objfw-compile -Werror -o scrypt-pwgen *.m

clean:
	rm -f *.o *~ scrypt-pwgen
