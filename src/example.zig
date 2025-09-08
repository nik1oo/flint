const std = @import("std");
const flint = @import("flint");
const win32 = @cImport({
	@cInclude("windows.h");
	@cInclude("windowsx.h");
	@cInclude("wchar.h");
	@cInclude("combaseapi.h");
	@cInclude("commdlg.h");
	@cInclude("shellapi.h"); });

const X = flint.X;
const Y = flint.Y;
const Z = flint.Z;

pub fn shader_a(x: u16, y: u16, _: ?*anyopaque) flint.AnyColor {
	return try flint.AnyColor.newRGBA(@as(f32, @floatFromInt(x)) / 1344, @as(f32, @floatFromInt(y)) / 896, 0, 1); }

pub fn main() !void {
	const k: flint.Mat2x3 = flint.mat2x3(1, 2, 3, 4, 5, 6);
	std.debug.print("[{d:.2} {d:.2}\n {d:.2} {d:.2}\n {d:.2} {d:.2}]\n", .{ k[0][0], k[1][0], k[0][1], k[1][1], k[0][2], k[1][2] });
	const rk: flint.Mat3x2 = flint.rotateMat2x3(k);
	std.debug.print("[{d:.2} {d:.2} {d:.2}\n {d:.2} {d:.2} {d:.2}]\n", .{ rk[0][0], rk[1][0], rk[2][0], rk[0][1], rk[1][1], rk[2][1] });
	const mk: flint.Mat3x3 = flint.matMul2x3(k, rk);
	std.debug.print("[{d:.2} {d:.2} {d:.2}\n {d:.2} {d:.2} {d:.2}\n {d:.2} {d:.2} {d:.2}]\n", .{ mk[0][0], mk[1][0], mk[2][0], mk[0][1], mk[1][1], mk[2][1], mk[0][2], mk[1][2], mk[2][2] });
	if (true) {
	    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	    defer arena.deinit();
	    const allocator = arena.allocator();
		std.debug.print("Flint version {s}.\n", .{ flint.VERSION_STRING });
		const wnd_name: [*]const u8 = "Flint\x00";
		var window: *flint.Window = try flint.Window.new(.{ .name = wnd_name, .width = 1024, .height = 653, .allocator = allocator }, allocator);
		const anycolor = try flint.AnyColor.newRGBA(0, 0, 0, 1);
		try window.buffer.fillA(anycolor);
		const qoi_file = try std.fs.cwd().openFile("./image.qoi", .{});
		defer qoi_file.close();
		const qoi_bytes = try allocator.alloc(u8, (try qoi_file.stat()).size);
		defer allocator.free(qoi_bytes);
		_ = try qoi_file.readAll(qoi_bytes);
		const buffer = try flint.Buffer.newFromQOI(qoi_bytes, allocator);
		// _ = buffer;
		window.buffer = buffer;
		// try window.buffer.drawBuffer(&buffer, .COPY);
		try window.buffer.drawPoint(.{ 100, 100 }, try flint.AnyColor.newRGBA(1, 0, 0, 1), .COPY);
		try window.buffer.drawPoint(.{ 101, 100 }, try flint.AnyColor.newRGBA(0, 1, 0, 1), .COPY);
		try window.buffer.drawPoint(.{ 102, 100 }, try flint.AnyColor.newRGBA(0, 0, 1, 1), .COPY);
		const points_array: [10][2]u16 = .{
			.{ 12, 23 },
			.{  5, 14 },
			.{  2, 14 },
			.{ 13,  2 },
			.{ 21,  2 },
			.{ 23, 26 },
			.{  1,  4 },
			.{  4, 28 },
			.{ 16,  7 },
			.{  4,  6 } };
		const points: [][2]u16 = @constCast(&points_array);
		try window.buffer.drawPoints(points, try flint.AnyColor.newRGBA(1, 1, 1, 1), .COPY);
		try window.buffer.drawRect(.{ .position = .{ 80, 40 }, .size = .{ 40, 20 } }, try flint.AnyColor.newRGBA(1, 0, 1, 1), .COPY);
		// try window.buffer.fillS(shader_a, null);
		while (window.poll()) {
			// const hovered_index: u32 = try window.getHoveredPixelIndex();
			// const hovered_pixel: flint.AnyColor = try window.getHoveredPixelColor();
			// std.debug.print("{d}: {d} {d} {d} {d}\n", .{ hovered_index, hovered_pixel.color[flint.R], hovered_pixel.color[flint.G], hovered_pixel.color[flint.B], hovered_pixel.color[flint.A] });
			try window.draw(); } } }