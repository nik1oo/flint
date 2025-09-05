//! Flint is a simple and easy to use 2D software renderer.

const std = @import("std");
const win32 = @cImport({
	@cInclude("windows.h");
	@cInclude("windowsx.h");
	@cInclude("wchar.h");
	@cInclude("combaseapi.h");
	@cInclude("commdlg.h");
	@cInclude("shellapi.h");
});

fn depthIsValid(depth: u8) !bool {
	return (depth == 1) or (depth == 2) or (depth == 4); }

pub const Color = struct {
	bytes: []u8 = null,

	/// Fill the given `Channel` uniformly with a given value.
	pub fn rgbaU8(depth: u8, r: u8, g: u8, b: u8, allocator: std.mem.Allocator) Color {
		const color: Color = .{ .bytes = allocator.alloc(u8, depth) };

	}
};
pub const RGBAU16 = struct { r: u16, g: u16, b: u16, a: u16 };
pub const RGBAU32 = struct { r: u32, g: u32, b: u32, a: u32 };
pub const RGBU8 = struct { r: u8, g: u8, b: u8 };
pub const RGBU16 = struct { r: u16, g: u16, b: u16 };
pub const RGBU32 = struct { r: u32, g: u32, b: u32 };
pub const ValueU8 = u8;
pub const ValueU16 = u16;
pub const ValueU32 = u32;

/// Decompose a slice of bytes representing a color
// pub fn decomposeColor(color: []u8, n_channels: u8, depth: u8) [][]u8 {
// }

/// A single channel of an image buffer. Contains the red, green, blue, or alpha values of a color image, or the gray values of a grayscale image. Contains no meta-data about dimensions, channels, or encoding. Those are determined by the parent `Buffer`.
pub const Channel = struct {
	const Self = @This();

	/// The contents of the channel.
	bytes: []u8 = null,

	/// Allocate and initialize a new `Channel`.
	pub fn new(width: u16, height: u16, depth: u8, allocator: std.mem.Allocator) !Channel {
		const channel: Channel = .{
			.bytes = allocator.alloc(u8, width * height * depth) };
		return channel; }

	/// Fill the given `Channel` uniformly with a given value.
	pub fn fill(channel: *const Channel, depth: u8, value: []u8) noreturn {
		for (0..channel.bytes.len) |i| {
			channel.bytes[i] = value[i % depth]; } }

	/// Fill the given `Channel` with zeroes.
	pub fn clear(channel: *const Channel) noreturn {
		for (0..channel.bytes.len) |i| {
			channel.bytes[i] = 0; } }

	/// Get the index of the pixel at the given coordinates.
	pub fn pixel_index(depth: u8, width: u16, x: u16, y: u16) u32 {
		return y * width * depth + x * depth; }

	/// Set the value of the pixel at the given coordinates.
	pub fn set_pixel(self: *const Channel, depth: u8, width: u16, height: u16, x: u16, y: u16, value: []u8) !void {
		if (depthIsValid(depth) == false) { return error.InvalidColorDepth; }
		const i: u32 = self.pixel_index(depth, width, height, x, y);
		@memcpy(self.bytes[i..i + depth], value[0..depth]); }

	/// Get the value of the pixel at the given coordinates.
	pub fn get_pixel(self: *const Channel, depth: u8, width: u16, height: u16, x: u16, y: u16) ![]u8 {
		if (depthIsValid(depth) == false) { return error.InvalidColorDepth; }
		const i: u32 = self.pixel_index(depth, width, height, x, y);
		return self.bytes[i..i + depth]; } };

/// An image buffer.
pub const Buffer = struct {
	/// The channels of this buffer.
	channels:   [4]Channel,
	/// The number of channels of this buffer. Can have up to 4.
	n_channels: u8,
	/// The width in pixels of this buffer.
	width:      u16,
	/// The height in pixels of this buffer.
	height:     u16,
	/// The color-depth of the channels of this buffer.
	depth:      u8,

	/// Allocate and initialize a new `Buffer`.
	pub fn new(width: u16, height: u16, n_channels: u8, depth: u8, allocator: std.mem.Allocator) !Buffer {
		var buffer: Buffer = .{
			.channels = [4]Channel{ .{}, .{}, .{}, .{} },
			.n_channels = n_channels,
			.width = width,
			.height = height,
			.depth = depth };
		for (0..4) |i| {
			buffer.channels[i] = Channel.new(width, height, depth, allocator); }
		return buffer; }

	/// Fill the given `Buffer` uniformly with a given value.
	pub fn fill(self: *const Buffer, value: []u8) noreturn {
		std.debug.assert(value.len == self.depth * self.n_channels);
		for (0..self.n_channels) |i| {
			self.channels[i].fill(self.depth, value[self.depth * i..self.depth * (i + 1)]); } }

	/// Set the color/value of the pixel at the given coordinates.
	pub fn set_pixel(self: *const Buffer, x: u16, y: u16, value: []u8) !void { }

	/// Get the color/value of the pixel at the given coordinates.
	pub fn get_pixel(self: *const Channel, x: u16, y: u16) ![]u8 { } };


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
	name: [*]const u8 = "Flint Application\x00",
	width: u16 = 1280,
	height: u16 = 720 };

/// A window with a buffer.
pub const Window = struct {
	h_wnd:  win32.HWND = 0,
	width:  u16,
	height: u16 };

/// Allocate and initialize a new `Window`.
pub fn newWindow(config: WindowConfig) !Window {
	var window: Window = .{
		.width = config.width,
		.height = config.height };
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
pub fn pollWindow(_: *const Window) bool {
	var msg: win32.MSG = std.mem.zeroes(win32.MSG);
	const window_opened: i32 = win32.GetMessageA(&msg, null, 0, 0);
	if (window_opened == 0) { return false; }
	_ = win32.TranslateMessage(&msg);
	_ = win32.DispatchMessageA(&msg);
	return true; }

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
