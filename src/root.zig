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

fn nChannelsIsValid(n_channels: u8) bool {
	return (n_channels == 1) or (n_channels == 3) or (n_channels == 4); }

/// An RGB, RGBA, or grayscale color value with unknown cardinality.
pub const Color     = [4]u8;

/// An RGBA color value.
pub const ColorRGBA = [4]u8;

/// An RGB color value.
pub const ColorRGB  = [3]u8;

/// A grayscale color value.
pub const ColorGray = [1]u8;

/// Support structure for defining RGBA, RGB, or Grayscale colors.
pub const AnyColor = struct {
	color:      Color = .{ 0 } ** 4,
	n_channels: u8    = 1,

	/// Create an RGBA `AnyColor`.
	pub fn newRGBA(r: f32, g: f32, b: f32, a: f32) !AnyColor {
		return .{
			.color = .{
				@intFromFloat(r * 0xFF),
				@intFromFloat(g * 0xFF),
				@intFromFloat(b * 0xFF),
				@intFromFloat(a * 0xFF) },
			.n_channels = 4 }; }

	/// Create an RGB `AnyColor`.
	pub fn newRGB(r: f32, g: f32, b: f32) !AnyColor {
		return .{
			.color = .{
				@intFromFloat(r * 0xFF),
				@intFromFloat(g * 0xFF),
				@intFromFloat(b * 0xFF),
				0 },
			.n_channels = 3 }; }

	/// Create a grayscale `AnyColor`.
	pub fn newGray(gray: f32) !AnyColor {
		return .{
			.color = .{
				@intFromFloat(gray * 0xFF),
				0,
				0,
				0 },
			.n_channels = 1 }; }

	pub fn mix(self: AnyColor, other: AnyColor, t: f32) AnyColor {
		return .{
			.color = .{
				@intFromFloat(@as(f32, @floatFromInt(self.color[R])) * (1 - t) + @as(f32, @floatFromInt(other.color[R])) * t),
				@intFromFloat(@as(f32, @floatFromInt(self.color[G])) * (1 - t) + @as(f32, @floatFromInt(other.color[G])) * t),
				@intFromFloat(@as(f32, @floatFromInt(self.color[B])) * (1 - t) + @as(f32, @floatFromInt(other.color[B])) * t),
				@intFromFloat(@as(f32, @floatFromInt(self.color[A])) * (1 - t) + @as(f32, @floatFromInt(other.color[A])) * t) },
			.n_channels = self.n_channels }; }

	pub fn blend(self: AnyColor, other: AnyColor, blendMode: BlendMode) AnyColor {
		return switch (blendMode) {
			.COPY => self.blendCopy(other),
			.ADD  => self.blendAdd(other),
			.SUB  => self.blendSub(other),
			.MUL  => self.blendMul(other),
			.MAX  => self.blendMax(other),
			.MIN  => self.blendMin(other) }; }

	pub fn blendCopy(self: AnyColor, other: AnyColor) AnyColor {
		_ = self;
		return other; }

	pub fn blendAdd(self: AnyColor, other: AnyColor) AnyColor {
		var result: AnyColor = .{};
		for (0..self.n_channels) |i| {
			// TODO Convert to float first.
			result.color[i] = self.color[i] +% other.color[i]; }
		return result; }

	pub fn blendSub(self: AnyColor, other: AnyColor) AnyColor {
		var result: AnyColor = .{};
		for (0..self.n_channels) |i| {
			// TODO Convert to float first.
			result.color[i] = self.color[i] - other.color[i]; }
		return result; }

	pub fn blendMul(self: AnyColor, other: AnyColor) AnyColor {
		var result: AnyColor = .{};
		for (0..self.n_channels) |i| {
			// TODO Convert to float first.
			result.color[i] = self.color[i] * other.color[i]; }
		return result; }

	pub fn blendDiv(self: AnyColor, other: AnyColor) AnyColor {
		var result: AnyColor = .{};
		for (0..self.n_channels) |i| {
			// TODO Convert to float first.
			result.color[i] = self.color[i] / other.color[i]; }
		return result; }
};

/// Decompose a slice of bytes representing a color
// pub fn decomposeColor(color: []u8, n_channels: u8) [][]u8 {
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
	pub fn new(width: u16, height: u16, allocator: std.mem.Allocator) !Channel {
		const channel: Channel = .{
			.bytes = try allocator.alloc(u8, @as(u32, width) * @as(u32, height)) };
		return channel; }

	/// Fill the given `Channel` uniformly with a given value.
	pub fn fill(channel: *const Channel, value: u8) !void {
		for (0..channel.bytes.len) |i| {
			channel.bytes[i] = value; } }

	/// Fill the given `Channel` with zeroes.
	pub fn clear(channel: *const Channel) noreturn {
		for (0..channel.bytes.len) |i| {
			channel.bytes[i] = 0; } }

	/// Get the index of the pixel at the given coordinates.
	pub fn pixelIndex(width: u16, _: u16, x: u16, y: u16) u32 {
		return @as(u32, y) * @as(u32, width) + @as(u32, x); }

	/// Set the value of the pixel at the given coordinates.
	pub fn setPixel(self: *const Channel, width: u16, height: u16, x: u16, y: u16, value: u8) !void {
		const i: u32 = Channel.pixelIndex(width, height, x, y);
		self.bytes[i] = value; }

	/// Get the value of the pixel at the given coordinates.
	pub fn getPixel(self: *const Channel, width: u16, height: u16, x: u16, y: u16) !u8 {
		const i: u32 = Channel.pixelIndex(width, height, x, y);
		return self.bytes[i]; } };

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

	pub fn print(self: *const Buffer) !void {
		std.debug.print("Buffer: [ n_channels = {d}, width = {d}, height = {d} ]\n", .{ self.n_channels, self.width, self.height }); }

	/// Allocate and initialize a new `Buffer`.
	pub fn new(width: u16, height: u16, n_channels: u8, allocator: std.mem.Allocator) !Buffer {
		var buffer: Buffer = .{
			.channels = [4]Channel{
				try Channel.empty(),
				try Channel.empty(),
				try Channel.empty(),
				try Channel.empty() },
			.n_channels = n_channels,
			.width = width,
			.height = height };
		for (0..4) |i| {
			buffer.channels[i] = try Channel.new(width, height, allocator); }
		// DICK
		const fillcolor_array: [4]u8 = .{ 255, 0, 0, 255 };
		const fillcolor_slice: []u8 = @constCast(&fillcolor_array);
		try buffer.fill(fillcolor_slice);
		return buffer; }

	/// Fill the given `Buffer` uniformly with a given value.
	pub fn fill(self: *const Buffer, value: []u8) !void {
		std.debug.assert(value.len == self.n_channels);
		for (0..self.n_channels) |i| {
			try self.channels[i].fill(value[i]); } }

	/// Get the index of the pixel at the given coordinates.
	pub fn pixelIndex(width: u16, _: u16, x: u16, y: u16) u32 {
		return Channel.pixelIndex(width, x, y); }

	/// Set the color/value of the pixel at the given coordinates.
	pub fn setPixelColor(self: *const Buffer, x: u16, y: u16, anycolor: AnyColor) !void {
		for (0..self.n_channels) |i| {
			try self.channels[i].setPixel(self.width, self.height, x, y, anycolor.color[i]); } }

	/// Get the color/value of the pixel at the given coordinates.
	pub fn getPixelColor(self: *const Buffer, x: u16, y: u16) !AnyColor {
		var anycolor: AnyColor = .{ };
		for (0..self.n_channels) |i| {
			anycolor.color[i] = try self.channels[i].getPixel(self.width, self.height, x, y); }
			// @memcpy(anycolor.color[i], self.channels[i].getPixel(self.width, self.height, x, y)); }
		anycolor.n_channels = self.n_channels;
		return anycolor; }

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
			buffer.channels[i] = try Channel.new(@intCast(width), @intCast(height), allocator); }
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
					const vg: u8 = (b1 & 0x3f) -% 32;
					px[R] = px[R] +% vg -% 8 +% ((b2 >> 4) & 0x0f);
					px[G] = px[G] +% vg;
					px[B] = px[B] +% vg -% 8 +%  (b2       & 0x0f); }
				else if ((b1 & QOI_MASK_2) == QOI_OP_RUN) {
					run = @intCast(b1 & 0x3f); }
				index[qoiColorHash(px) & (64 - 1)] = px; }
			buffer.channels[R].bytes[i] = px[R];
			buffer.channels[G].bytes[i] = px[G];
			buffer.channels[B].bytes[i] = px[B];
			if (n_channels == 4) { buffer.channels[A].bytes[i] = px[A]; }
			i += 1; }
		buffer.width = @intCast(width);
		buffer.height = @intCast(height);
		buffer.n_channels = n_channels;
		return buffer; }

	/// Draw a `Buffer` over the given `Buffer`. The two buffers must have the same dimensions.
	pub fn drawBuffer(self: *const Buffer, buffer: *const Buffer, blend_mode: BlendMode) !void {
		if (blend_mode != .COPY) { return error.Unimplemented; }
		std.debug.print("SELF: {d} {d} {d}\nOTHER: {d} {d} {d}\n", .{ self.width, self.height, self.n_channels, buffer.width, buffer.height, buffer.n_channels });
		if ((self.width != buffer.width) or
			(self.height != buffer.height) or
			(self.n_channels != buffer.n_channels)) { return error.BufferMismatch; }
		for (0..self.width) |y| { for (0..self.width) |x| {
			try self.setPixelColor(
				@intCast(x), @intCast(y),
				(try self.getPixelColor(@intCast(x), @intCast(y))).blendAdd(try buffer.getPixelColor(@intCast(x), @intCast(y)))); } } } };

/// Array-of-structs pixel data, in BGRA order.
pub const Bitmap = struct {
	/// The contents of this bitmap.
	bytes:      []u8,
	/// The width in pixels of this bitmap.
	width:      u16 = 0,
	/// The height in pixels of this bitmap.
	height:     u16 = 0,
	/// The number of channels of this bitmap. Can have up to 4.
	n_channels: u8 = 0,

	pub fn new(width: u16, height: u16, n_channels: u8, allocator: std.mem.Allocator) !Bitmap {
		return .{
			.bytes = try allocator.alloc(u8, @as(usize, width) * @as(usize, height) * @as(usize, n_channels)),
			.width = width, .height = height, .n_channels = n_channels }; }

	pub fn newFromBuffer(buffer: *const Buffer, allocator: std.mem.Allocator) !Bitmap {
		var bitmap: Bitmap = try Bitmap.new(buffer.width, buffer.height, buffer.n_channels, allocator);
		var i: u32 = 0;
		for (0..bitmap.height) |y| { for (0..bitmap.width) |x| {
			const anycolor = try buffer.getPixelColor(@intCast(x), @intCast(y));
			switch (bitmap.n_channels) {
				1 => {
					bitmap.bytes[i + 0] = anycolor.color[0];
					i += 1; },
				3 => {
					bitmap.bytes[i + 0] = anycolor.color[B];
					bitmap.bytes[i + 1] = anycolor.color[G];
					bitmap.bytes[i + 2] = anycolor.color[R];
					i += 3; },
				4 => {
					bitmap.bytes[i + 0] = anycolor.color[B];
					bitmap.bytes[i + 1] = anycolor.color[G];
					bitmap.bytes[i + 2] = anycolor.color[R];
					bitmap.bytes[i + 3] = anycolor.color[A];
					i += 4; },
				else => return error.UnsupportedChannelCount } } }
		return bitmap; }
};

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
	allocator: std.mem.Allocator };

/// A window with a buffer. This is the only platform-dependent component of Flint.
pub const Window = struct {
	h_wnd:     win32.HWND = 0,
	h_dc:      win32.HDC = 0,
	width:     u16,
	height:    u16,
	allocator: std.mem.Allocator,
	buffer:    Buffer,

	/// Allocate and initialize a new `Window`.
	pub fn new(config: WindowConfig) !Window {
		var window: Window = .{
			.width = config.width,
			.height = config.height,
			.allocator = config.allocator,
			.buffer = try Buffer.new(config.width, config.height, 4, config.allocator) };
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
		window.h_dc = win32.GetDC(window.h_wnd);
		if (window.h_dc == null) { return error.CreateWindowFailed; }
		return window; }

	/// Collect events from the given `Window`. Returns `false` when the `Window` is closed.
	pub fn poll(_: *const Window) bool {
		var msg: win32.MSG = std.mem.zeroes(win32.MSG);
		const window_opened: i32 = win32.GetMessageA(&msg, null, 0, 0);
		if (window_opened == 0) { return false; }
		_ = win32.TranslateMessage(&msg);
		_ = win32.DispatchMessageA(&msg);
		return true; }

	/// Draw the window `Buffer` to the window. The window is not updated automatically, you must call `draw` whenever you update the buffer and want the changes to take effect.
	pub fn draw(self: *const Window) !void {
		// TODO Move all this stuff inside the WM_PAINT message, and here just call `RedrawWindow`.
		const bitmap: Bitmap = try Bitmap.newFromBuffer(&self.buffer, self.allocator);
		const info_header = win32.BITMAPINFOHEADER{
			.biSize = @sizeOf(win32.BITMAPINFOHEADER),
			.biWidth = bitmap.width,
			.biHeight = -@as(i32, bitmap.height), // make negative for top-down ordering.
			.biPlanes = 1,
			.biBitCount = 8 * bitmap.n_channels,
			.biCompression = win32.BI_RGB,
			.biSizeImage = 0,
			.biXPelsPerMeter = 0,
			.biYPelsPerMeter = 0,
			.biClrUsed = 0,
			.biClrImportant = 0 };
		const n_bytes: usize = @as(usize, bitmap.width) * @as(usize, bitmap.height) * @as(usize, bitmap.n_channels);
		const h_dc_mem: win32.HDC = win32.CreateCompatibleDC(self.h_dc);
		defer _ = win32.DeleteDC(h_dc_mem);
		if (h_dc_mem == null) { return error.BAD; }
		var bitmap_ptr: ?*anyopaque = null; // *void
		const h_bitmap = win32.CreateDIBSection(self.h_dc, @ptrCast(&info_header), win32.DIB_RGB_COLORS, &bitmap_ptr, null, 0);
		const nonnull_bitmap_ptr: *anyopaque = bitmap_ptr orelse return error.NullPtr;
		const bitmap_bytes: []u8 = @as([*]u8, @ptrCast(nonnull_bitmap_ptr))[0..n_bytes];
		defer _ = win32.DeleteObject(h_bitmap);
		if (h_bitmap == null) { return error.BAD; }
		@memcpy(bitmap_bytes, bitmap.bytes[0..n_bytes]);
		const h_old_bitmap = win32.SelectObject(h_dc_mem, h_bitmap);
		defer _ = win32.SelectObject(h_dc_mem, h_old_bitmap);
		_ = win32.StretchBlt(self.h_dc, 0, 0, self.width, self.height, h_dc_mem, 0, 0, bitmap.width, bitmap.height, win32.SRCCOPY);
	}
};



/// A blending mode determines how the results of a render function (the *foreground*) is combined with the current contents of the selected buffer (the *background*) on a per-pixel basis.
pub const BlendMode = enum {
	/// The *foreground* overrides the *background*.
	COPY,
	/// The *foreground* is added to the *background*.
	ADD,
	/// The *foreground* is subtracted from the *background*.
	SUB,
	/// The *foreground* and the *background* are multiplied.
	MUL,
	/// The higher value among the *foreground* and the *background* is taken.
	MAX,
	/// The lower value among the *foreground* and the *background* is taken.
	MIN };
