const std = @import("std");
const flint = @import("flint");
const win32 = @cImport({
	@cInclude("windows.h");
	@cInclude("windowsx.h");
	@cInclude("wchar.h");
	@cInclude("combaseapi.h");
	@cInclude("commdlg.h");
	@cInclude("shellapi.h"); });

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
	std.debug.print("Flint version {s}.\n", .{ flint.VERSION_STRING });
	const wnd_name: [*]const u8 = "Flint\x00";
	var window: *flint.Window = try flint.Window.new(.{ .name = wnd_name, .width = 1344, .height = 896, .allocator = allocator }, allocator);

	const window_ptr: *flint.Window = @ptrFromInt(@as(usize, @intCast(win32.GetWindowLongPtrA(@ptrCast(window.h_wnd), win32.GWLP_USERDATA))));
	std.debug.assert(window_ptr == window);

	const anycolor = try flint.AnyColor.newRGBA(0, 0, 0, 1);
	try window.buffer.fill(anycolor);
	const qoi_file = try std.fs.cwd().openFile("./image.qoi", .{});
	defer qoi_file.close();
	const qoi_bytes = try allocator.alloc(u8, (try qoi_file.stat()).size);
	defer allocator.free(qoi_bytes);
	_ = try qoi_file.readAll(qoi_bytes);
	const buffer = try flint.Buffer.newFromQOI(qoi_bytes, allocator);
	// _ = buffer;
	window.buffer = buffer;
	// try window.buffer.drawBuffer(&buffer, .COPY);
	while (window.poll()) {
		try window.draw(); } }
