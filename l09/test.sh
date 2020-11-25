#!/usr/bin/env /bin/bash

source ../test/common.sh

if [[ -r exploit.png ]] ; then
	./pnginfo exploit.png
	true # it's ok for the binary to segfault if it prints the correct message
elif [[ -r exploit32.png ]] ; then
	./pnginfo32 exploit32.png
	true # it's ok for the binary to segfault if it prints the correct message
else
	die "No exploit present!"
fi

# vim: set sw=4 sts=4 ts=4 noet :
