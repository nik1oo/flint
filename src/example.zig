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
const W = flint.W;
const R = flint.R;
const G = flint.G;
const B = flint.B;
const A = flint.A;
const Vec2 = flint.Vec2;
const Vec3 = flint.Vec3;
const Vec4 = flint.Vec4;

const WIDTH = 192;
const HEIGHT = 108;
const RESOLUTION = Vec2{ WIDTH, HEIGHT };

fn shader_a(x: u16, y: u16, _: ?*anyopaque) flint.AnyColor {
	return try flint.AnyColor.newRGBA(@as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(WIDTH)), @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(HEIGHT)), 0, 1); }

fn palette(d: f32) Vec3 {
	return flint.mix(Vec3{ 0.2, 0.7, 0.9 }, flint.Vec3{ 1.0, 0.0, 1.0 }, d); }

fn rotate(p: Vec2, a: f32) Vec2 {
	const c: f32 = flint.cos(a);
	const s: f32 = flint.sin(a);
	return flint.vecMatMul2x2(p, flint.mat2x2(c, -s, s, c)); }

fn map(_p: Vec3, time: f32) f32 {
	var p = _p;
    for (0..8) |_| {
        const t: f32 = time * 0.2;
        p[X], p[Z] = rotate(.{ p[X], p[Z] }, t);
        p[X], p[Y] = rotate(.{ p[X], p[Y] }, t * 1.89);
        p[X], p[Z] = flint.abs(Vec2{ p[X], p[Z] });
        p[X] -= 0.5;
        p[Z] -= 0.5; }
	return flint.dot(std.math.sign(p), p) / 5.0; }

fn rm(ro: Vec3, rd: Vec3, time: f32) Vec4 {
	var t: f32 = 0.0;
	var col: Vec3 = .{ 0.0, 0.0, 0.0 };
	var d: f32 = 0.0;
	for (0..64) |_| {
		const p: Vec3 = ro + rd * Vec3{ t, t, t };
		d = map(p, time) * 0.5;
		if (d < 0.02) { break; }
		if (d > 100.0) { break; }
		col += palette(flint.length(p) * 0.1) / Vec3{ 400.0 * d, 400.0 * d, 400.0 * d };
		t += d; }
	return .{ col[R], col[G], col[B], 1.0 / (d * 100.0) }; }

pub fn shader_b(x: u16, y: u16, userPtr: ?*anyopaque) flint.AnyColor {
	if (false) {
	return try flint.AnyColor.newRGBA((@as(f32, @floatFromInt(x)) - WIDTH / 2) / @as(f32, @floatFromInt(WIDTH)), (@as(f32, @floatFromInt(y)) - HEIGHT / 2) / @as(f32, @floatFromInt(HEIGHT)), 0, 1); }
	else {
	const time_ptr: ?*f32 = @as(?*f32, @ptrCast(@alignCast(userPtr)));
	const time: f32 = if (time_ptr) |value| value.* else 0;
	const uv: Vec2 = .{ (@as(f32, @floatFromInt(x)) - WIDTH / 2) / WIDTH, (@as(f32, @floatFromInt(y)) - HEIGHT / 2) / HEIGHT };
	var ro: Vec3 = .{ 0.0, 0.0, -50.0 };
	ro[X], ro[Z] = rotate(Vec2{ ro[X], ro[Z] }, time);
	const cf: Vec3 = flint.normalize(-ro);
	const cs: Vec3 = flint.normalize(flint.cross(cf, Vec3{ 0.0, 1.0, 0.0 }));
	const cu: Vec3 = flint.normalize(flint.cross(cf, cs));
	const uuv: Vec3 = ro + cf * Vec3{ 3.0, 3.0, 3.0 } + Vec3{ uv[X], uv[X], uv[X] } * cs + Vec3{ uv[Y], uv[Y], uv[Y] } * cu;
	const rd: Vec3 = flint.normalize(uuv - ro);
	const col: Vec4 = rm(ro, rd, time);
	return try flint.AnyColor.newRGBA(col[R], col[G], col[B], col[A]); } }

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
		var window: *flint.Window = try flint.Window.new(.{ .name = wnd_name, .width = WIDTH, .height = HEIGHT, .allocator = allocator }, allocator);
		const anycolor = try flint.AnyColor.newRGBA(0, 0, 0, 1);
		try window.buffer.fillA(anycolor);
		const qoi_file = try std.fs.cwd().openFile("./image.qoi", .{});
		defer qoi_file.close();
		const qoi_bytes = try allocator.alloc(u8, (try qoi_file.stat()).size);
		defer allocator.free(qoi_bytes);
		_ = try qoi_file.readAll(qoi_bytes);
		// const buffer = try flint.Buffer.newFromQOI(qoi_bytes, allocator);
		// window.buffer = buffer;
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
		var time: f32 = window.getTime();
		try window.buffer.fillS(shader_b, @ptrCast(&time));
		while (window.poll()) {
			// const hovered_index: u32 = try window.getHoveredPixelIndex();
			// const hovered_pixel: flint.AnyColor = try window.getHoveredPixelColor();
			// std.debug.print("{d}: {d} {d} {d} {d}\n", .{ hovered_index, hovered_pixel.color[flint.R], hovered_pixel.color[flint.G], hovered_pixel.color[flint.B], hovered_pixel.color[flint.A] });
			time = window.getTime();
			try window.buffer.fillS(shader_b, @ptrCast(&time));
			try window.draw();
			std.debug.print("Draw finished at {d:.2}.\n", .{ time }); } } }
