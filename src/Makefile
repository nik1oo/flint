main:
	zig build run --build-file ../build.zig
doc:
	zig build-lib -femit-docs root.zig
doc-host:
	python -m http.server 8000 -d docs/
