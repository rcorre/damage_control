SETCOMPILER=
ifdef DC
	SETCOMPILER="--compiler=$(DC)"
endif

all: debug

debug:
	@dub build $(SETCOMPILER) --build=debug --quiet

run:
	@dub run $(SETCOMPILER) --quiet

release:
	@dub build $(SETCOMPILER) release --quiet

test:
	@dub test $(SETCOMPILER)

docs:
	@dub build $(SETCOMPILER) --build=ddox --quiet

clean:
	@dub clean
	@$(RM) bin/*
