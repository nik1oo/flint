//! Flint is a simple and easy to use 2D software renderer.

const std = @import("std");
const win32 = @cImport({
	@cInclude("windows.h");
	@cInclude("windowsx.h");
	@cInclude("wchar.h");
	@cInclude("combaseapi.h");
	@cInclude("commdlg.h");
	@cInclude("shellapi.h"); });

pub const VERSION_STRING = "0.1.0";
pub const R = 0;
pub const G = 1;
pub const B = 2;
pub const A = 3;

fn depthIsValid(depth: u8) bool {
	return (depth == 1) or (depth == 2) or (depth == 4); }

fn nChannelsIsValid(n_channels: u8) bool {
	return (n_channels == 1) or (n_channels == 3) or (n_channels == 4); }

/// An RGB, RGBA, or grayscale value.
pub const Color = struct {
	bytes: []u8,

	/// Create a 1-byte deep RGBA value..
	pub fn rgba8(r: f32, g: f32, b: f32, a: f32, allocator: std.mem.Allocator) !Color {
		const values = try allocator.alloc(u8, 4);
		values[0] = @intFromFloat(r * 0xFF);
		values[1] = @intFromFloat(g * 0xFF);
		values[2] = @intFromFloat(b * 0xFF);
		values[3] = @intFromFloat(a * 0xFF);
		return .{ .bytes = @ptrCast(values) }; }

	/// Create a 1-byte deep RGB value..
	pub fn rgb8(r: f32, g: f32, b: f32, allocator: std.mem.Allocator) !Color {
		const values = try allocator.alloc(u8, 3);
		values[0] = @intFromFloat(r * 0xFF);
		values[1] = @intFromFloat(g * 0xFF);
		values[2] = @intFromFloat(b * 0xFF);
		return .{ .bytes = @ptrCast(values) }; }

	/// Create a 1-byte deep grayscale value..
	pub fn gray8(gray: f32, allocator: std.mem.Allocator) !Color {
		const values = try allocator.alloc(u8, 1);
		values[0] = @intFromFloat(gray * 0xFF);
		return .{ .bytes = @ptrCast(values) }; }

	/// Create a 2-byte deep RGBA value..
	pub fn rgba16(r: f32, g: f32, b: f32, a: f32, allocator: std.mem.Allocator) !Color {
		const values = try allocator.alloc(u16, 4);
		values[0] = @intFromFloat(r * 0xFF);
		values[1] = @intFromFloat(g * 0xFF);
		values[2] = @intFromFloat(b * 0xFF);
		values[3] = @intFromFloat(a * 0xFF);
		return .{ .bytes = @ptrCast(values) }; }

	/// Create a 2-byte deep RGB value..
	pub fn rgb16(r: f32, g: f32, b: f32, allocator: std.mem.Allocator) !Color {
		const values = try allocator.alloc(u16, 3);
		values[0] = @intFromFloat(r * 0xFF);
		values[1] = @intFromFloat(g * 0xFF);
		values[2] = @intFromFloat(b * 0xFF);
		return .{ .bytes = @ptrCast(values) }; }

	/// Create a 2-byte deep grayscale value..
	pub fn gray16(gray: f32, allocator: std.mem.Allocator) !Color {
		const values = try allocator.alloc(u16, 1);
		values[0] = @intFromFloat(gray * 0xFF);
		return .{ .bytes = @ptrCast(values) }; }

	/// Create a 4-byte deep RGBA value..
	pub fn rgba32(r: f32, g: f32, b: f32, a: f32, allocator: std.mem.Allocator) !Color {
		const values = try allocator.alloc(u32, 4);
		values[0] = @intFromFloat(r * 0xFF);
		values[1] = @intFromFloat(g * 0xFF);
		values[2] = @intFromFloat(b * 0xFF);
		values[3] = @intFromFloat(a * 0xFF);
		return .{ .bytes = @ptrCast(values) }; }

	/// Create a 4-byte deep RGB value..
	pub fn rgb32(r: f32, g: f32, b: f32, allocator: std.mem.Allocator) !Color {
		const values = try allocator.alloc(u32, 3);
		values[0] = @intFromFloat(r * 0xFF);
		values[1] = @intFromFloat(g * 0xFF);
		values[2] = @intFromFloat(b * 0xFF);
		return .{ .bytes = @ptrCast(values) }; }

	/// Create a 4-byte deep grayscale value..
	pub fn gray32(gray: f32, allocator: std.mem.Allocator) !Color {
		const values = try allocator.alloc(u32, 1);
		values[0] = @intFromFloat(gray * 0xFF);
		return .{ .bytes = @ptrCast(values) }; } };

/// Decompose a slice of bytes representing a color
// pub fn decomposeColor(color: []u8, n_channels: u8, depth: u8) [][]u8 {
// }

/// A single channel of an image buffer. Contains the red, green, blue, or alpha values of a color image, or the gray values of a grayscale image. Contains no meta-data about dimensions, channels, or encoding. Those are determined by the parent `Buffer`.
pub const Channel = struct {
	const Self = @This();

	/// The contents of the channel.
	bytes: []u8,

	/// Create empty `Channel`.
	pub fn empty() !Channel {
		return .{ .bytes = &[0]u8{} }; }

	/// Allocate and initialize a new `Channel`.
	pub fn new(width: u16, height: u16, depth: u8, allocator: std.mem.Allocator) !Channel {
		const channel: Channel = .{
			.bytes = try allocator.alloc(u8, @as(u32, width) * @as(u32, height) * @as(u32, depth)) };
		return channel; }

	/// Fill the given `Channel` uniformly with a given `Color`.
	pub fn fill(channel: *const Channel, depth: u8, color: Color) noreturn {
		for (0..channel.bytes.len) |i| {
			channel.bytes[i] = color.bytes[i % depth]; } }

	/// Fill the given `Channel` with zeroes.
	pub fn clear(channel: *const Channel) noreturn {
		for (0..channel.bytes.len) |i| {
			channel.bytes[i] = 0; } }

	/// Get the index of the pixel at the given coordinates.
	pub fn pixelIndex(depth: u8, width: u16, x: u16, y: u16) u32 {
		return y * width * depth + x * depth; }

	/// Set the value of the pixel at the given coordinates.
	pub fn set_pixel(self: *const Channel, depth: u8, width: u16, height: u16, x: u16, y: u16, value: []u8) !void {
		if (depthIsValid(depth) == false) { return error.InvalidColorDepth; }
		const i: u32 = self.pixelIndex(depth, width, height, x, y);
		@memcpy(self.bytes[i..i + depth], value[0..depth]); }

	/// Get the value of the pixel at the given coordinates.
	pub fn get_pixel(self: *const Channel, depth: u8, width: u16, height: u16, x: u16, y: u16) ![]u8 {
		if (depthIsValid(depth) == false) { return error.InvalidColorDepth; }
		const i: u32 = self.pixelIndex(depth, width, height, x, y);
		return self.bytes[i..i + depth]; } };

/// An image buffer.
pub const Buffer = struct {
	/// The channels of this buffer.
	channels:   [4]Channel,
	/// The number of channels of this buffer. Can have up to 4.
	n_channels: u8 = 0,
	/// The width in pixels of this buffer.
	width:      u16 = 0,
	/// The height in pixels of this buffer.
	height:     u16 = 0,
	/// The color-depth of the channels of this buffer.
	depth:      u8 = 0,

	pub fn print(self: *const Buffer) !void {
		std.debug.print("Buffer: [ n_channels = {d}, width = {d}, height = {d}, depth = {d} ]\n", .{ self.n_channels, self.width, self.height, self.depth }); }

	/// Allocate and initialize a new `Buffer`.
	pub fn new(width: u16, height: u16, n_channels: u8, depth: u8, allocator: std.mem.Allocator) !Buffer {
		var buffer: Buffer = .{
			.channels = [4]Channel{
				try Channel.empty(),
				try Channel.empty(),
				try Channel.empty(),
				try Channel.empty() },
			.n_channels = n_channels,
			.width = width,
			.height = height,
			.depth = depth };
		for (0..4) |i| {
			buffer.channels[i] = try Channel.new(width, height, depth, allocator); }
		return buffer; }

	/// Fill the given `Buffer` uniformly with a given value.
	pub fn fill(self: *const Buffer, value: []u8) noreturn {
		std.debug.assert(value.len == self.depth * self.n_channels);
		for (0..self.n_channels) |i| {
			self.channels[i].fill(self.depth, value[self.depth * i..self.depth * (i + 1)]); } }

	/// Get the index of the pixel at the given coordinates.
	pub fn pixelIndex(depth: u8, width: u16, x: u16, y: u16) u32 {
		return Channel.pixelIndex(depth, width, x, y); }

	/// Set the color/value of the pixel at the given coordinates.
	pub fn setPixelColor(self: *const Buffer, x: u16, y: u16, color: Color) !void {
		for (0..self.n_channels) |i| {
			self.channels[i].set_pixel(self.depth, self.width, self.height, x, y, color.bytes[i * self.depth..(i + 1) * self.depth]); } }

	/// Get the color/value of the pixel at the given coordinates.
	pub fn getPixelColor(self: *const Buffer, x: u16, y: u16) !Color {
		var color: Color = .{ };
		for (0..self.n_channels) |i| {
			@memcpy(color.bytes[i * self.depth..(i + 1) * self.depth], self.channels[i].get_pixel(self.depth, self.width, self.height, x, y)); }
		return color; }

	const QOI_HEADER_SIZE: u32 = 14;
	const QOI_PADDING: [8]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 1};
	const QOI_MAGIC: u32 = (@as(u32, 'q') << 24 | @as(u32, 'o') << 16 | @as(u32, 'i') <<  8 | @as(u32, 'f'));
	const QOI_PIXELS_MAX: u32 = 400000000;
	const QOI_MASK_2: u8   = 0xc0;
	const QOI_OP_INDEX: u8 = 0x00;
	const QOI_OP_DIFF: u8  = 0x40;
	const QOI_OP_LUMA: u8  = 0x80;
	const QOI_OP_RUN: u8   = 0xc0;
	const QOI_OP_RGB: u8   = 0xfe;
	const QOI_OP_RGBA: u8  = 0xff;

	fn qoiRead32(bytes: []u8, p: *u32) u32 {
		const result: u32 = (@as(u32, bytes[p.*]) << 24) | (@as(u32, bytes[p.* + 1]) << 16) | (@as(u32, bytes[p.* + 2]) << 8) | bytes[p.* + 3];
		p.* += 4;
		return result; }

	fn qoiColorHash(color: [4]u8) u8 {
		return color[R] *% 3 +% color[G] *% 5 +% color[B] *% 7 +% color[A] *% 11; }

	/// Initialize a new buffer from a QOI image.
	pub fn newFromQOI(bytes: []u8, allocator: std.mem.Allocator) !Buffer {
		var buffer: Buffer = .{
			.channels = [4]Channel{
				try Channel.empty(),
				try Channel.empty(),
				try Channel.empty(),
				try Channel.empty() } };
		if ((bytes.len == 0) or (bytes.len < QOI_HEADER_SIZE + QOI_PADDING.len)) { return error.InvalidQOI; }
		var p: u32 = 0;
		const header_magic: u32 = qoiRead32(bytes, &p);
		if (header_magic != QOI_MAGIC) { return error.InvalidQOI; }
		const width: u32 = qoiRead32(bytes, &p);
		const height: u32 = qoiRead32(bytes, &p);
		if ((width == 0) or (height == 0) or (height >= QOI_PIXELS_MAX / width)) { return error.InvalidQOI; }
		const n_channels: u8 = bytes[p]; p += 1;
		if (nChannelsIsValid(n_channels) == false) { return error.InvalidQOI; }
		for (0..n_channels) |i| {
			buffer.channels[i] = try Channel.new(@intCast(width), @intCast(height), 1, allocator); }
		const colorspace: u8 = bytes[p]; p += 1;
		if (colorspace > 1) { return error.InvalidQOI; }
		const max_size: u32 = width * height * (n_channels + 1) + QOI_HEADER_SIZE + @as(u32, QOI_PADDING.len);
		_ = max_size;
		const px_len: u32 = width * height * n_channels;
		std.debug.print("Allocated {d} bytes for a {d} x {d} x {d} QOI image.\n", .{px_len, width, height, n_channels});
		var px: [4]u8 = .{ 0, 0, 0, 255 };
		var index: [64][4]u8 = .{ .{ 0 } ** 4 } ** 64; // A record of previously seen pixels.
		const chunks_len: u32 = @intCast(bytes.len - QOI_PADDING.len);
		var px_pos: u32 = 0;
		var run: u32 = 0; // How many times the previous pixel is repeated.
		var i: u32 = 0;
		while (px_pos < px_len) : (px_pos += n_channels) {
			if (run > 0) { run -= 1; }
			else if (p < chunks_len) {
				const b1: u8 = bytes[p]; p += 1;
				if (b1 == QOI_OP_RGB) {
					px[R] = bytes[p]; p += 1;
					px[G] = bytes[p]; p += 1;
					px[B] = bytes[p]; p += 1; }
				else if (b1 == QOI_OP_RGBA) {
					px[R] = bytes[p]; p += 1;
					px[G] = bytes[p]; p += 1;
					px[B] = bytes[p]; p += 1;
					px[A] = bytes[p]; p += 1; }
				else if ((b1 & QOI_MASK_2) == QOI_OP_INDEX) {
					px = index[@intCast(b1)]; }
				else if ((b1 & QOI_MASK_2) == QOI_OP_DIFF) {
					px[R] = px[R] +% ((b1 >> 4) & 0x03) -% 2;
					px[G] = px[G] +% ((b1 >> 2) & 0x03) -% 2;
					px[B] = px[B] +% ( b1       & 0x03) -% 2; }
				else if ((b1 & QOI_MASK_2) == QOI_OP_LUMA) {
					const b2: u8 = bytes[p]; p += 1;
					const vg: u8 = (b1 & 0x3f) - 32;
					px[R] = px[R] +% vg - 8 + ((b2 >> 4) & 0x0f);
					px[G] = px[G] +% vg;
					px[B] = px[B] +% vg - 8 +  (b2       & 0x0f); }
				else if ((b1 & QOI_MASK_2) == QOI_OP_RUN) {
					run = @intCast(b1 & 0x3f); }
				index[qoiColorHash(px) & (64 - 1)] = px; }
			buffer.channels[R].bytes[i] = px[R];
			buffer.channels[G].bytes[i] = px[G];
			buffer.channels[B].bytes[i] = px[B];
			if (n_channels == 4) { buffer.channels[A].bytes[i] = px[A]; }
			i += 1; }
		return error.ValidQOI; } };


fn windowProc(hwnd: win32.HWND, uMsg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.c) win32.LRESULT {
	switch (uMsg) {
		win32.WM_DESTROY => {
			win32.PostQuitMessage(0);
			return 0; },
		else => {}, }
	return win32.DefWindowProcA(hwnd, uMsg, wParam, lParam); }

// fn win32GetErrorString() []u8 {
//  var message: []u8 = &[0]u8{};
//  win32.FormatMessage(
//      win32.FORMAT_MESSAGE_ALLOCATE_BUFFER |
//      win32.FORMAT_MESSAGE_FROM_SYSTEM |
//      win32.FORMAT_MESSAGE_IGNORE_INSERTS,
//      null,
//      win32.GetLastError(),
//      0,
//      @as(win32.LPTSTR, &message),
//      0,
//      null);
//  return message; }

/// A set of parameters for configuring `Window`. Passed to `newWindow`.
pub const WindowConfig = struct {
	name:      [*]const u8 = "Flint Application\x00",
	width:     u16 = 1280,
	height:    u16 = 720,
	depth:     u8 = 1,
	allocator: std.mem.Allocator };

/// A window with a buffer.
pub const Window = struct {
	h_wnd:     win32.HWND = 0,
	width:     u16,
	height:    u16,
	depth:     u8,
	allocator: std.mem.Allocator,
	buffer:    Buffer,

	/// Allocate and initialize a new `Window`.
	pub fn new(config: WindowConfig) !Window {
		var window: Window = .{
			.width = config.width,
			.height = config.height,
			.depth = config.depth,
			.allocator = config.allocator,
			.buffer = try Buffer.new(config.width, config.height, 4, config.depth, config.allocator) };
		const h_instance: win32.HINSTANCE = @ptrCast(win32.GetModuleHandleA(null));
		if (h_instance == null) { return error.NullHandle; }
		const wnd_class_name: [*]const u8 = "Flint Window\x00";
		var wnd_class: win32.WNDCLASSEXA = .{
			.cbSize = @sizeOf(win32.WNDCLASSEX),
			.style = win32.CS_HREDRAW | win32.CS_VREDRAW,
			.lpfnWndProc = windowProc,
			.cbClsExtra = 0,
			.cbWndExtra = 0,
			.hInstance = h_instance,
			.hIcon = null,
			.hCursor = null,
			.hbrBackground = null,
			.lpszMenuName = null,
			.lpszClassName = wnd_class_name,
			.hIconSm = null };
		if (win32.RegisterClassExA(&wnd_class) == 0) { return error.RegisterClassFailed; }
		window.h_wnd = win32.CreateWindowExA(
			0,
			wnd_class_name,
			config.name,
			win32.WS_CAPTION |
			win32.WS_MAXIMIZEBOX |
			win32.WS_MINIMIZEBOX |
			win32.WS_SYSMENU |
			win32.WS_THICKFRAME |
			win32.WS_VISIBLE,
			win32.CW_USEDEFAULT,
			win32.CW_USEDEFAULT,
			@as(i32, config.width),
			@as(i32, config.height),
			null,
			null,
			h_instance,
			null);
		if (window.h_wnd == null) {
			std.debug.print("ERROR: {d}\n", .{ win32.GetLastError() });
			return error.CreateWindowFailed; }
		return window; }

	/// Collect events from the given `Window`. Returns `false` when the `Window` is closed.
	pub fn poll(_: *const Window) bool {
		var msg: win32.MSG = std.mem.zeroes(win32.MSG);
		const window_opened: i32 = win32.GetMessageA(&msg, null, 0, 0);
		if (window_opened == 0) { return false; }
		_ = win32.TranslateMessage(&msg);
		_ = win32.DispatchMessageA(&msg);
		return true; }
};



/// A blending mode determines how the results of a render function (the *foreground*) is combined with the current contents of the selected buffer (the *background*) on a per-pixel basis.
pub const BlendMode = enum {
	/// The *foreground* overrides the *background*.
	COPY,
	/// The *foreground* is added to the *background*.
	ADD,
	/// The *foreground* is subtracted from the *background*.
	SUBTRACT,
	/// The *foreground* and the *background* are multiplied.
	MULTIPLY,
	/// The higher value among the *foreground* and the *background* is taken.
	MAX,
	/// The lower value among the *foreground* and the *background* is taken.
	MIN };
