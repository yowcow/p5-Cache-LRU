.PHONY: test

all: cpanfile.snapshot

cpanfile.snapshot: cpanfile
	carton install

test: cpanfile.snapshot
	carton exec -- prove
