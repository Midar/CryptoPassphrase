all:
	@objfw-compile -o scrypt-pwgen *.m

clean:
	rm -f *.o *~ scrypt-pwgen
