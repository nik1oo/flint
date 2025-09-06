const std = @import("std");
const flint = @import("flint");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
	std.debug.print("Flint version {s}.\n", .{ flint.VERSION_STRING });
	const wnd_name: [*]const u8 = "Flint\x00";
	const window: flint.Window = try flint.Window.new(.{ .name = wnd_name, .width = 1280, .height = 720, .allocator = allocator });
	const anycolor = try flint.AnyColor.newRGBA(0.5, 0.25, 0.333, 1);
	std.debug.print("Color: {d}, {d}, {d}, {d}.\n", .{ anycolor.color[0], anycolor.color[1], anycolor.color[2], anycolor.color[3] });
	try window.buffer.print();
	const qoi_file = try std.fs.cwd().openFile("../flint.qoi", .{});
	defer qoi_file.close();
	const qoi_bytes = try allocator.alloc(u8, (try qoi_file.stat()).size);
	defer allocator.free(qoi_bytes);
	const bytes_read = try qoi_file.readAll(qoi_bytes);
	std.debug.print("{s}\n", .{qoi_bytes});
	_ = bytes_read;
	_ = try flint.Buffer.newFromQOI(qoi_bytes, allocator);
	while (window.poll()) {
		try window.draw(); } }
