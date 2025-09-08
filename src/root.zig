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
pub const X = 0;
pub const Y = 1;
pub const Z = 2;
pub const W = 3;
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
			.DIV  => self.blendDiv(other),
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

	pub fn blendMax(self: AnyColor, other: AnyColor) AnyColor {
		var result: AnyColor = .{};
		for (0..self.n_channels) |i| {
			result.color[i] = @max(self.color[i], other.color[i]); }
		return result; }

	pub fn blendMin(self: AnyColor, other: AnyColor) AnyColor {
		var result: AnyColor = .{};
		for (0..self.n_channels) |i| {
			result.color[i] = @min(self.color[i], other.color[i]); }
		return result; }
};

/// Rectangle.
pub const Rect = struct {
	position: [2]u16,
	size: [2]u16 };

pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);
pub const Vec4 = @Vector(4, f32);

/// A 2x2 matrix, stored in column-major order.
pub const Mat2x2 = [2]Vec2;

/// Construct a 2x2 matrix, defined in row-major order.
pub fn mat2x2(a00: f32, a10: f32, a01: f32, a11: f32) Mat2x2 {
	return .{
		.{ a00, a10 },
		.{ a01, a11 } }; }

/// Vector-matrix product of a 2-vector and a 2x2 matrix.
fn vecMatMul2x2(v: Vec2, m: Mat2x2) Vec2 {
	return Vec2{ dot(v, m[0]), dot(v, m[1]) }; }

/// Rotate a 2x2 matrix.
pub fn rotateMat2x2(m: Mat2x2) Mat2x2 {
	return mat2x2(
		m[0][0], m[1][0],
		m[0][1], m[1][1]); }

/// Matrix product of a 2x2 matrix and a 2x2 matrix.
pub fn matMul2x2(m1: Mat2x2, m2: Mat2x2) Mat2x2 {
	const m1rot = rotateMat2x2(m1);
	return mat2x2(
		m1rot[0] * m2[0], m1rot[0] * m2[0],
		m1rot[1] * m2[1], m1rot[1] * m2[1]); }

/// A 2x3 matrix, stored in column-major order.
pub const Mat2x3 = [2]@Vector(3, f32);

/// Construct a 2x3 matrix, defined in column-major order.
pub fn mat2x3(a00: f32, a10: f32, a20: f32, a01: f32, a11: f32, a21: f32) Mat2x3 {
	return .{
		.{ a00, a10, a20 },
		.{ a01, a11, a21 } }; }

/// Vector-matrix product of a 3-vector and a 2x3 matrix.
fn vecMatMul2x3(v: Vec3, m: Mat2x3) Vec2 {
	return Vec3{ dot(v, m[0]), dot(v, m[1]) }; }

/// Rotate a 2x3 matrix.
pub fn rotateMat2x3(m: Mat2x3) Mat3x2 {
	return mat3x2(
		m[0][0], m[1][0],
		m[0][1], m[1][1],
		m[0][2], m[1][2]); }

/// Matrix product of a 2x3 matrix and a 3x2 matrix.
pub fn matMul2x3(m1: Mat2x3, m2: Mat3x2) Mat3x3 {
	const m1rot = rotateMat2x3(m1);
	return mat3x3(
		try dot(m1rot[0], m2[0]), try dot(m1rot[0], m2[1]), try dot(m1rot[0], m2[2]),
		try dot(m1rot[1], m2[0]), try dot(m1rot[1], m2[1]), try dot(m1rot[1], m2[2]),
		try dot(m1rot[2], m2[0]), try dot(m1rot[2], m2[1]), try dot(m1rot[2], m2[2])); }

/// A 2x4 matrix, stored in column-major order.
pub const Mat2x4 = [2]@Vector(4, f32);

/// Construct a 2x4 matrix, defined in column-major order.
pub fn mat2x4(a00: f32, a10: f32, a20: f32, a30: f32, a01: f32, a11: f32, a21: f32, a31: f32) Mat2x4 {
	return .{
		.{ a00, a10, a20, a30 },
		.{ a01, a11, a21, a31 } }; }

/// Vector-matrix product of a 4-vector and a 2x4 matrix.
fn vecMatMul2x4(v: Vec4, m: Mat2x4) Vec2 {
	return Vec2{ dot(v, m[0]), dot(v, m[1]) }; }

/// Rotate a 2x4 matrix.
pub fn rotateMat2x4(m: Mat2x4) Mat4x2 {
	return mat4x2(
		m[0][0], m[1][0],
		m[0][1], m[1][1],
		m[0][2], m[1][2],
		m[0][3], m[1][3]); }

/// Matrix product of a 2x4 matrix and a 4x2 matrix.
pub fn matMul2x4(m1: Mat2x4, m2: Mat4x2) Mat4x4 {
	const m1rot = rotateMat2x4(m1);
	return mat4x4(
		try dot(m1rot[0], m2[0]), try dot(m1rot[0], m2[1]), try dot(m1rot[0], m2[2]), try dot(m1rot[0], m2[3]),
		try dot(m1rot[1], m2[0]), try dot(m1rot[1], m2[1]), try dot(m1rot[1], m2[2]), try dot(m1rot[1], m2[3]),
		try dot(m1rot[2], m2[0]), try dot(m1rot[2], m2[1]), try dot(m1rot[2], m2[2]), try dot(m1rot[2], m2[3]),
		try dot(m1rot[3], m2[0]), try dot(m1rot[3], m2[1]), try dot(m1rot[3], m2[2]), try dot(m1rot[3], m2[3])); }

/// A 3x2 matrix, stored in column-major order.
pub const Mat3x2 = [3]@Vector(2, f32);

/// Construct a 3x2 matrix, defined in column-major order.
pub fn mat3x2(a00: f32, a10: f32, a01: f32, a11: f32, a02: f32, a12: f32) Mat3x2 {
	return .{
		.{ a00, a10 },
		.{ a01, a11 },
		.{ a02, a12 } }; }

/// Vector-matrix product of a 2-vector and a 3x2 matrix.
fn vecMatMul3x2(v: Vec2, m: Mat3x2) Vec3 {
	return Vec3{ dot(v, m[0]), dot(v, m[1]), dot(v, m[2]) }; }

/// Rotate a 3x2 matrix.
pub fn rotateMat3x2(m: Mat3x2) Mat2x3 {
	return mat2x3(
		m[0][0], m[1][0], m[2][0],
		m[0][1], m[1][1], m[2][1]); }

/// Matrix product of a 3x2 matrix and a 2x3 matrix.
pub fn matMul3x2(m1: Mat3x2, m2: Mat2x3) Mat2x2 {
	const m1rot = rotateMat3x2(m1);
	return mat2x2(
		try dot(m1rot[0], m2[0]), try dot(m1rot[0], m2[1]),
		try dot(m1rot[1], m2[0]), try dot(m1rot[1], m2[1])); }

/// A 3x3 matrix, stored in column-major order.
pub const Mat3x3 = [3]@Vector(3, f32);

/// Construct a 3x3 matrix, defined in column-major order.
pub fn mat3x3(a00: f32, a10: f32, a20: f32, a01: f32, a11: f32, a21: f32, a02: f32, a12: f32, a22: f32) Mat3x3 {
	return .{
		.{ a00, a10, a20 },
		.{ a01, a11, a21 },
		.{ a02, a12, a22 } }; }

/// Vector-matrix product of a 3-vector and a 3x3 matrix.
fn vecMatMul3x3(v: Vec3, m: Mat3x3) Vec3 {
	return Vec3{ dot(v, m[0]), dot(v, m[1]), dot(v, m[2]) }; }

/// Rotate a 3x3 matrix.
pub fn rotateMat3x3(m: Mat3x3) Mat3x3 {
	return mat3x3(
		m[0][0], m[1][0], m[2][0],
		m[0][1], m[1][1], m[2][1],
		m[0][2], m[1][2], m[2][2]); }

/// Matrix product of a 3x3 matrix and a 3x3 matrix.
pub fn matMul3x3(m1: Mat3x3, m2: Mat3x3) Mat3x3 {
	const m1rot = rotateMat3x3(m1);
	return mat3x3(
		try dot(m1rot[0], m2[0]), try dot(m1rot[0], m2[1]), try dot(m1rot[0], m2[2]),
		try dot(m1rot[1], m2[0]), try dot(m1rot[1], m2[1]), try dot(m1rot[1], m2[2]),
		try dot(m1rot[2], m2[0]), try dot(m1rot[2], m2[1]), try dot(m1rot[2], m2[2])); }

/// A 3x4 matrix, stored in column-major order.
pub const Mat3x4 = [3]@Vector(4, f32);

/// Construct a 3x4 matrix, defined in column-major order.
pub fn mat3x4(a00: f32, a10: f32, a20: f32, a30: f32, a01: f32, a11: f32, a21: f32, a31: f32, a02: f32, a12: f32, a22: f32, a32: f32) Mat3x4 {
	return .{
		.{ a00, a10, a20, a30 },
		.{ a01, a11, a21, a31 },
		.{ a02, a12, a22, a32 } }; }

/// Vector-matrix product of a 4-vector and a 3x4 matrix.
fn vecMatMul3x4(v: Vec4, m: Mat3x4) Vec3 {
	return Vec3{ dot(v, m[0]), dot(v, m[1]), dot(v, m[2]) }; }

/// Rotate a 3x4 matrix.
pub fn rotateMat3x4(m: Mat3x4) Mat4x3 {
	return mat4x3(
		m[0][0], m[1][0], m[2][0],
		m[0][1], m[1][1], m[2][1],
		m[0][2], m[1][2], m[2][2],
		m[0][3], m[1][3], m[2][3]); }

/// Matrix product of a 3x4 matrix and a 4x3 matrix.
pub fn matMul3x4(m1: Mat3x4, m2: Mat4x3) Mat4x4 {
	const m1rot = rotateMat3x4(m1);
	return mat4x4(
		try dot(m1rot[0], m2[0]), try dot(m1rot[0], m2[1]), try dot(m1rot[0], m2[2]), try dot(m1rot[0], m2[3]),
		try dot(m1rot[1], m2[0]), try dot(m1rot[1], m2[1]), try dot(m1rot[1], m2[2]), try dot(m1rot[1], m2[3]),
		try dot(m1rot[2], m2[0]), try dot(m1rot[2], m2[1]), try dot(m1rot[2], m2[2]), try dot(m1rot[2], m2[3]),
		try dot(m1rot[3], m2[0]), try dot(m1rot[3], m2[1]), try dot(m1rot[3], m2[2]), try dot(m1rot[3], m2[3])); }

/// A 4x2 matrix, stored in column-major order.
pub const Mat4x2 = [4]@Vector(2, f32);

/// Construct a 4x2 matrix, defined in column-major order.
pub fn mat4x2(a00: f32, a10: f32, a01: f32, a11: f32, a02: f32, a12: f32, a03: f32, a13: f32) Mat4x2 {
	return .{
		.{ a00, a10 },
		.{ a01, a11 },
		.{ a02, a12 },
		.{ a03, a13 } }; }

/// Vector-matrix product of a 2-vector and a 4x2 matrix.
fn vecMatMul4x2(v: Vec2, m: Mat4x2) Vec4 {
	return Vec4{ dot(v, m[0]), dot(v, m[1]), dot(v, m[2]), dot(v, m[3]) }; }

/// Rotate a 4x2 matrix.
pub fn rotateMat4x2(m: Mat4x2) Mat2x4 {
	return mat2x4(
		m[0][0], m[1][0], m[2][0], m[3][0],
		m[0][1], m[1][1], m[2][1], m[3][1]); }

/// Matrix product of a 4x2 matrix and a 2x4 matrix.
pub fn matMul4x2(m1: Mat4x2, m2: Mat2x4) Mat2x2 {
	const m1rot = rotateMat4x2(m1);
	return mat2x2(
		try dot(m1rot[0], m2[0]), try dot(m1rot[0], m2[1]),
		try dot(m1rot[1], m2[0]), try dot(m1rot[1], m2[1])); }

/// A 4x3 matrix, stored in column-major order.
pub const Mat4x3 = [4]@Vector(3, f32);

/// Construct a 4x3 matrix, defined in column-major order.
pub fn mat4x3(a00: f32, a10: f32, a20: f32, a01: f32, a11: f32, a21: f32, a02: f32, a12: f32, a22: f32, a03: f32, a13: f32, a23: f32) Mat4x3 {
	return .{
		.{ a00, a10, a20 },
		.{ a01, a11, a21 },
		.{ a02, a12, a22 },
		.{ a03, a13, a23 } }; }

/// Vector-matrix product of a 3-vector and a 4x3 matrix.
fn vecMatMul4x3(v: Vec3, m: Mat4x3) Vec4 {
	return Vec4{ dot(v, m[0]), dot(v, m[1]), dot(v, m[2]), dot(v, m[3]) }; }

/// Rotate a 4x3 matrix.
pub fn rotateMat4x3(m: Mat4x3) Mat3x4 {
	return mat3x4(
		m[0][0], m[1][0], m[2][0], m[3][0],
		m[0][1], m[1][1], m[2][1], m[3][1],
		m[0][2], m[1][2], m[2][2], m[3][2]); }

/// Matrix product of a 4x3 matrix and a 3x4 matrix.
pub fn matMul4x3(m1: Mat4x3, m2: Mat3x4) Mat3x3 {
	const m1rot = rotateMat4x3(m1);
	return mat3x3(
		try dot(m1rot[0], m2[0]), try dot(m1rot[0], m2[1]), try dot(m1rot[0], m2[2]),
		try dot(m1rot[1], m2[0]), try dot(m1rot[1], m2[1]), try dot(m1rot[1], m2[2]),
		try dot(m1rot[2], m2[0]), try dot(m1rot[2], m2[1]), try dot(m1rot[2], m2[2])); }

/// A 4x4 matrix, stored in column-major order.
pub const Mat4x4 = [4]@Vector(4, f32);

/// Construct a 4x4 matrix, defined in column-major order.
pub fn mat4x4(a00: f32, a10: f32, a20: f32, a30: f32, a01: f32, a11: f32, a21: f32, a31: f32, a02: f32, a12: f32, a22: f32, a32: f32, a03: f32, a13: f32, a23: f32, a33: f32) Mat4x4 {
	return .{
		.{ a00, a10, a20, a30 },
		.{ a01, a11, a21, a31 },
		.{ a02, a12, a22, a32 },
		.{ a03, a13, a23, a33 } }; }

/// Vector-matrix product of a 4-vector and a 4x4 matrix.
fn vecMatMul4x4(v: Vec4, m: Mat4x4) Vec4 {
	return Vec4{ dot(v, m[0]), dot(v, m[1]), dot(v, m[2]), dot(v, m[3]) }; }

/// Rotate a 4x4 matrix.
pub fn rotateMat4x4(m: Mat4x4) Mat4x4 {
	return mat4x4(
		m[0][0], m[1][0], m[2][0], m[3][0],
		m[0][1], m[1][1], m[2][1], m[3][1],
		m[0][2], m[1][2], m[2][2], m[3][2],
		m[0][3], m[1][3], m[2][3], m[3][3]); }

/// Matrix product of a 4x4 matrix and a 4x4 matrix.
pub fn matMul4x4(m1: Mat4x4, m2: Mat4x4) Mat4x4 {
	const m1rot = rotateMat4x4(m1);
	return mat4x4(
		try dot(m1rot[0], m2[0]), try dot(m1rot[0], m2[1]), try dot(m1rot[0], m2[2]), try dot(m1rot[0], m2[3]),
		try dot(m1rot[1], m2[0]), try dot(m1rot[1], m2[1]), try dot(m1rot[1], m2[2]), try dot(m1rot[1], m2[3]),
		try dot(m1rot[2], m2[0]), try dot(m1rot[2], m2[1]), try dot(m1rot[2], m2[2]), try dot(m1rot[2], m2[3]),
		try dot(m1rot[3], m2[0]), try dot(m1rot[3], m2[1]), try dot(m1rot[3], m2[2]), try dot(m1rot[3], m2[3])); }

/// Vector-matrix product.
pub fn vecMatMul(v: anytype, m: anytype) @Vector(@typeInfo(@TypeOf(m)).len, f32) {
	switch (@TypeOf(m)) {
		Mat2x2 => switch (@TypeOf(v)) {
			Vec2 => return vecMatMul2x2(v, m),
			else => unreachable },
		Mat2x3 => switch (@TypeOf(v)) {
			Vec3 => return vecMatMul2x3(v, m),
			else => unreachable },
		Mat2x4 => switch (@TypeOf(v)) {
			Vec4 => return vecMatMul2x4(v, m),
			else => unreachable },
		Mat3x2 => switch (@TypeOf(v)) {
			Vec2 => return vecMatMul3x2(v, m),
			else => unreachable },
		Mat3x3 => switch (@TypeOf(v)) {
			Vec3 => return vecMatMul3x3(v, m),
			else => unreachable },
		Mat3x4 => switch (@TypeOf(v)) {
			Vec4 => return vecMatMul3x4(v, m),
			else => unreachable },
		Mat4x2 => switch (@TypeOf(v)) {
			Vec2 => return vecMatMul4x2(v, m),
			else => unreachable },
		Mat4x3 => switch (@TypeOf(v)) {
			Vec3 => return vecMatMul4x3(v, m),
			else => unreachable },
		Mat4x4 => switch (@TypeOf(v)) {
			Vec4 => return vecMatMul4x4(v, m),
			else => unreachable },
		else => unreachable } }

/// Vector-matrix product.
// pub fn rotateMat(m: anytype) [@typeInfo(@TypeOf(m)).array.child.len]@Vector(@typeInfo(@TypeOf(m)).array.len, f32) {
//     switch (@TypeOf(m)) {
//         Mat2x2 => return rotateMat2x2(m),
//         Mat2x3 => return rotateMat2x3(m),
//         Mat2x4 => return rotateMat2x4(m),
//         Mat3x2 => return rotateMat3x2(m),
//         Mat3x3 => return rotateMat3x3(m),
//         Mat3x4 => return rotateMat3x4(m),
//         Mat4x2 => return rotateMat4x2(m),
//         Mat4x3 => return rotateMat4x3(m),
//         Mat4x4 => return rotateMat4x4(m),
//         else => unreachable } }

/// Substitute for GLSL `abs(x)`.
pub fn abs(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float, .vector => { return @abs(a); },
		else => switch (@TypeOf(a)) {
			[2]f32 => { return @abs(@Vector(2, f32){ a[X], a[Y] }); },
			[2]i32 => { return @abs(@Vector(2, i32){ a[X], a[Y] }); },
			[3]f32 => { return @abs(@Vector(3, f32){ a[X], a[Y], a[Z] }); },
			[3]i32 => { return @abs(@Vector(3, i32){ a[X], a[Y], a[Z] }); },
			[4]f32 => { return @abs(@Vector(4, f32){ a[X], a[Y], a[Z], a[W] }); },
			[4]i32 => { return @abs(@Vector(4, i32){ a[X], a[Y], a[Z], a[W] }); },
			else => unreachable } } }

/// Substitute for GLSL `acos(x)`.
pub fn acos(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.acos(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.acos(a[X]), std.math.acos(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.acos(a[X]), std.math.acos(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.acos(a[X]), std.math.acos(a[Y]), std.math.acos(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.acos(a[X]), std.math.acos(a[Y]), std.math.acos(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.acos(a[X]), std.math.acos(a[Y]), std.math.acos(a[Z]), std.math.acos(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.acos(a[X]), std.math.acos(a[Y]), std.math.acos(a[Z]), std.math.acos(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `acosh(x)`.
pub fn acosh(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.acosh(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.acosh(a[X]), std.math.acosh(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.acosh(a[X]), std.math.acosh(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.acosh(a[X]), std.math.acosh(a[Y]), std.math.acosh(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.acosh(a[X]), std.math.acosh(a[Y]), std.math.acosh(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.acosh(a[X]), std.math.acosh(a[Y]), std.math.acosh(a[Z]), std.math.acosh(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.acosh(a[X]), std.math.acosh(a[Y]), std.math.acosh(a[Z]), std.math.acosh(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `all(x)`.
pub fn all(a: anytype) !bool {
	switch (@TypeOf(a)) {
		[2]bool, @Vector(2, bool) => { return a[X] and a[Y]; },
		[3]bool, @Vector(3, bool) => { return a[X] and a[Y] and a[Z]; },
		[4]bool, @Vector(4, bool) => { return a[X] and a[Y] and a[Z] and a[W]; },
		else => unreachable } }

/// Substitute for GLSL `any(x)`.
pub fn any(a: anytype) !bool {
	switch (@TypeOf(a)) {
		[2]bool, @Vector(2, bool) => { return a[X] or a[Y]; },
		[3]bool, @Vector(3, bool) => { return a[X] or a[Y] or a[Z]; },
		[4]bool, @Vector(4, bool) => { return a[X] or a[Y] or a[Z] or a[W]; },
		else => unreachable } }

/// Substitute for GLSL `asin(x)`.
pub fn asin(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.asin(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.asin(a[X]), std.math.asin(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.asin(a[X]), std.math.asin(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.asin(a[X]), std.math.asin(a[Y]), std.math.asin(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.asin(a[X]), std.math.asin(a[Y]), std.math.asin(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.asin(a[X]), std.math.asin(a[Y]), std.math.asin(a[Z]), std.math.asin(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.asin(a[X]), std.math.asin(a[Y]), std.math.asin(a[Z]), std.math.asin(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `asinh(x)`.
pub fn asinh(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.asinh(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.asinh(a[X]), std.math.asinh(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.asinh(a[X]), std.math.asinh(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.asinh(a[X]), std.math.asinh(a[Y]), std.math.asinh(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.asinh(a[X]), std.math.asinh(a[Y]), std.math.asinh(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.asinh(a[X]), std.math.asinh(a[Y]), std.math.asinh(a[Z]), std.math.asinh(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.asinh(a[X]), std.math.asinh(a[Y]), std.math.asinh(a[Z]), std.math.asinh(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `atan(y_over_x)`.
pub fn atan(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.atan(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.atan(a[X]), std.math.atan(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.atan(a[X]), std.math.atan(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.atan(a[X]), std.math.atan(a[Y]), std.math.atan(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.atan(a[X]), std.math.atan(a[Y]), std.math.atan(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.atan(a[X]), std.math.atan(a[Y]), std.math.atan(a[Z]), std.math.atan(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.atan(a[X]), std.math.atan(a[Y]), std.math.atan(a[Z]), std.math.atan(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `atan(y, x)`.
pub fn atan2(y: anytype, x: anytype) !@TypeOf(y) {
	switch (@typeInfo(@TypeOf(y))) {
		.float => { return std.math.atan2(y, x); },
		else => unreachable } }

/// Substitute for GLSL `atanh(x)`.
pub fn atanh(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.atanh(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.atanh(a[X]), std.math.atanh(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.atanh(a[X]), std.math.atanh(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.atanh(a[X]), std.math.atanh(a[Y]), std.math.atanh(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.atanh(a[X]), std.math.atanh(a[Y]), std.math.atanh(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.atanh(a[X]), std.math.atanh(a[Y]), std.math.atanh(a[Z]), std.math.atanh(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.atanh(a[X]), std.math.atanh(a[Y]), std.math.atanh(a[Z]), std.math.atanh(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `ceil(x)`.
pub fn ceil(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.ceil(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.ceil(a[X]), std.math.ceil(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.ceil(a[X]), std.math.ceil(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.ceil(a[X]), std.math.ceil(a[Y]), std.math.ceil(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.ceil(a[X]), std.math.ceil(a[Y]), std.math.ceil(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.ceil(a[X]), std.math.ceil(a[Y]), std.math.ceil(a[Z]), std.math.ceil(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.ceil(a[X]), std.math.ceil(a[Y]), std.math.ceil(a[Z]), std.math.ceil(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `clamp(x)`.
pub fn clamp(x: anytype, minVal: @TypeOf(x), maxVal: @TypeOf(x)) !@TypeOf(x) {
	switch (@typeInfo(@TypeOf(x))) {
		.int, .float, .vector => { return std.math.clamp(x, minVal, maxVal); },
		else => switch (@TypeOf(x)) {
			[2]f32 => { return @as([2]f32, std.math.clamp(@as(@Vector(2, f32), x), @as(@Vector(2, f32), minVal), @as(@Vector(2, f32), maxVal))); },
			[2]i32 => { return @as([2]i32, std.math.clamp(@as(@Vector(2, i32), x), @as(@Vector(2, i32), minVal), @as(@Vector(2, i32), maxVal))); },
			[3]f32 => { return @as([3]f32, std.math.clamp(@as(@Vector(3, f32), x), @as(@Vector(3, f32), minVal), @as(@Vector(3, f32), maxVal))); },
			[3]i32 => { return @as([3]i32, std.math.clamp(@as(@Vector(3, i32), x), @as(@Vector(3, i32), minVal), @as(@Vector(3, i32), maxVal))); },
			[4]f32 => { return @as([4]f32, std.math.clamp(@as(@Vector(4, f32), x), @as(@Vector(4, f32), minVal), @as(@Vector(4, f32), maxVal))); },
			[4]i32 => { return @as([4]i32, std.math.clamp(@as(@Vector(4, i32), x), @as(@Vector(4, i32), minVal), @as(@Vector(4, i32), maxVal))); },
			else => unreachable } } }

/// Substitute for GLSL `cos(x)`.
pub fn cos(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.cos(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.cos(a[X]), std.math.cos(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.cos(a[X]), std.math.cos(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.cos(a[X]), std.math.cos(a[Y]), std.math.cos(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.cos(a[X]), std.math.cos(a[Y]), std.math.cos(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.cos(a[X]), std.math.cos(a[Y]), std.math.cos(a[Z]), std.math.cos(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.cos(a[X]), std.math.cos(a[Y]), std.math.cos(a[Z]), std.math.cos(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `cosh(x)`.
pub fn cosh(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.cosh(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.cosh(a[X]), std.math.cosh(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.cosh(a[X]), std.math.cosh(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.cosh(a[X]), std.math.cosh(a[Y]), std.math.cosh(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.cosh(a[X]), std.math.cosh(a[Y]), std.math.cosh(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.cosh(a[X]), std.math.cosh(a[Y]), std.math.cosh(a[Z]), std.math.cosh(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.cosh(a[X]), std.math.cosh(a[Y]), std.math.cosh(a[Z]), std.math.cosh(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `cross(x, y)`.
pub fn cross(x: anytype, y: @TypeOf(x)) !@TypeOf(x) {
	switch (@TypeOf(x)) {
		[3]f32, @Vector(3, f32) => { return .{ x[1] * y[2] - x[2] * y[1], x[2] * y[0] - x[0] * y[2], x[0] * y[1] - x[1] * y[0] }; },
		else => unreachable } }

/// Substitute for GLSL `degrees(radians)`.
pub fn degrees(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.float => { return (180 * a) / std.math.pi; },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ (180 * a[X]) / std.math.pi, (180 * a[Y]) / std.math.pi }; },
			[3]f32, @Vector(3, f32) => { return .{ (180 * a[X]) / std.math.pi, (180 * a[Y]) / std.math.pi, (180 * a[Z]) / std.math.pi }; },
			[4]f32, @Vector(4, f32) => { return .{ (180 * a[X]) / std.math.pi, (180 * a[Y]) / std.math.pi, (180 * a[Z]) / std.math.pi, (180 * a[W]) / std.math.pi }; },
			else => unreachable } } }

// TODO determinant

/// Substitute for GLSL `distance(p0, p1)`.
pub fn distance(a: anytype, b: @TypeOf(a)) !@TypeOf(a) {
	return length(a - b); }

/// Substitute for GLSL `dot(x, y)`.
pub fn dot(a: anytype, b: @TypeOf(a)) !@typeInfo(@TypeOf(a)).vector.child {
	switch (@TypeOf(a)) {
		[2]f32, @Vector(2, f32) => { return a[X] * b[X] + a[Y] * b[Y]; },
		[3]f32, @Vector(3, f32) => { return a[X] * b[X] + a[Y] * b[Y] + a[Z] * b[Z]; },
		[4]f32, @Vector(4, f32) => { return a[X] * b[X] + a[Y] * b[Y] + a[Z] * b[Z] + a[W] * b[W]; },
		else => unreachable } }

/// Substitute for GLSL `floor(x)`.
pub fn floor(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.floor(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.floor(a[X]), std.math.floor(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.floor(a[X]), std.math.floor(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.floor(a[X]), std.math.floor(a[Y]), std.math.floor(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.floor(a[X]), std.math.floor(a[Y]), std.math.floor(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.floor(a[X]), std.math.floor(a[Y]), std.math.floor(a[Z]), std.math.floor(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.floor(a[X]), std.math.floor(a[Y]), std.math.floor(a[Z]), std.math.floor(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `fract(x)`.
pub fn fract(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return a - std.math.floor(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ a - std.math.floor(a[X]), a - std.math.floor(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ a - std.math.floor(a[X]), a - std.math.floor(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ a - std.math.floor(a[X]), a - std.math.floor(a[Y]), a - std.math.floor(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ a - std.math.floor(a[X]), a - std.math.floor(a[Y]), a - std.math.floor(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ a - std.math.floor(a[X]), a - std.math.floor(a[Y]), a - std.math.floor(a[Z]), a - std.math.floor(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ a - std.math.floor(a[X]), a - std.math.floor(a[Y]), a - std.math.floor(a[Z]), a - std.math.floor(a[W]) }; },
			else => unreachable } } }

// TODO inverse
// TODO inversesqrt
// TODO isinf
// TODO isnan

/// Substitute for GLSL `length(x)`.
pub fn length(a: anytype) !@typeInfo(@TypeOf(a)) {
	switch (@TypeOf(a)) {
		[2]f32, @Vector(2, f32) => { return std.math.sqrt(a[X] * a[X] + a[Y] * a[Y]); },
		[3]f32, @Vector(3, f32) => { return std.math.sqrt(a[X] * a[X] + a[Y] * a[Y] + a[Z] * a[Z]); },
		[4]f32, @Vector(4, f32) => { return std.math.sqrt(a[X] * a[X] + a[Y] * a[Y] + a[Z] * a[Z] + a[W] * a[W]); },
		else => unreachable } }

/// Substitute for GLSL `log(x)`.
pub fn log(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.float => { return std.math.log(f32, std.math.e, a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.log(f32, std.math.e, a[X]), std.math.log(f32, std.math.e, a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.log(f32, std.math.e, a[X]), std.math.log(f32, std.math.e, a[Y]), std.math.log(f32, std.math.e, a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.log(f32, std.math.e, a[X]), std.math.log(f32, std.math.e, a[Y]), std.math.log(f32, std.math.e, a[Z]), std.math.log(f32, std.math.e, a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `log2(x, y)`.
pub fn log2(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.float => { return std.math.log2(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.log2(a[X]), std.math.log2(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.log2(a[X]), std.math.log2(a[Y]), std.math.log2(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.log2(a[X]), std.math.log2(a[Y]), std.math.log2(a[Z]), std.math.log2(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `max(x)`.
pub fn max(a: anytype, b: anytype) !@TypeOf(a) {
	return @max(a, b); }

/// Substitute for GLSL `min(x)`.
pub fn min(a: anytype, b: anytype) !@TypeOf(a) {
	return @min(a, b); }

/// Substitute for GLSL `mix(x)`.
pub fn mix(a: anytype, b: anytype, c: f32) !@TypeOf(a) {
	return (1 - c) * a + c * b; }

// TODO mod
// TODO modf
// TODO noise1
// TODO noise2
// TODO noise3
// TODO noise4

/// Substitute for GLSL `normalize(x)`.
pub fn normalize(a: anytype) !@typeInfo(@TypeOf(a)) {
	return a / length(a); }

// TODO outerProduct

/// Substitute for GLSL `pow(x, y)`.
pub fn pow(a: anytype, b: f32) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.float => { return std.math.pow(a, b); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.pow(a[X], b), std.math.pow(a[Y], b) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.pow(a[X], b), std.math.pow(a[Y], b), std.math.pow(a[Z], b) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.pow(a[X], b), std.math.pow(a[Y], b), std.math.pow(a[Z], b), std.math.pow(a[W], b) }; },
			else => unreachable } } }

/// Substitute for GLSL `radians(degrees)`.
pub fn radians(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.float => { return (std.math.pi * a) / 180; },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ (std.math.pi * a[X]) / 180, (std.math.pi * a[Y]) / 180 }; },
			[3]f32, @Vector(3, f32) => { return .{ (std.math.pi * a[X]) / 180, (std.math.pi * a[Y]) / 180, (std.math.pi * a[Z]) / 180 }; },
			[4]f32, @Vector(4, f32) => { return .{ (std.math.pi * a[X]) / 180, (std.math.pi * a[Y]) / 180, (std.math.pi * a[Z]) / 180, (std.math.pi * a[W]) / 180 }; },
			else => unreachable } } }

// TODO reflect
// TODO refract
// TODO round
// TODO sign

/// Substitute for GLSL `sin(x)`.
pub fn sin(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.sin(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.sin(a[X]), std.math.sin(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.sin(a[X]), std.math.sin(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.sin(a[X]), std.math.sin(a[Y]), std.math.sin(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.sin(a[X]), std.math.sin(a[Y]), std.math.sin(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.sin(a[X]), std.math.sin(a[Y]), std.math.sin(a[Z]), std.math.sin(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.sin(a[X]), std.math.sin(a[Y]), std.math.sin(a[Z]), std.math.sin(a[W]) }; },
			else => unreachable } } }

/// Substitute for GLSL `sinh(x)`.
pub fn sinh(a: anytype) !@TypeOf(a) {
	switch (@typeInfo(@TypeOf(a))) {
		.int, .float => { return std.math.sinh(a); },
		else => switch (@TypeOf(a)) {
			[2]f32, @Vector(2, f32) => { return .{ std.math.sinh(a[X]), std.math.sinh(a[Y]) }; },
			[2]i32, @Vector(2, i32) => { return .{ std.math.sinh(a[X]), std.math.sinh(a[Y]) }; },
			[3]f32, @Vector(3, f32) => { return .{ std.math.sinh(a[X]), std.math.sinh(a[Y]), std.math.sinh(a[Z]) }; },
			[3]i32, @Vector(3, i32) => { return .{ std.math.sinh(a[X]), std.math.sinh(a[Y]), std.math.sinh(a[Z]) }; },
			[4]f32, @Vector(4, f32) => { return .{ std.math.sinh(a[X]), std.math.sinh(a[Y]), std.math.sinh(a[Z]), std.math.sinh(a[W]) }; },
			[4]i32, @Vector(4, i32) => { return .{ std.math.sinh(a[X]), std.math.sinh(a[Y]), std.math.sinh(a[Z]), std.math.sinh(a[W]) }; },
			else => unreachable } } }

// TODO sqrt
// TODO step
// TODO tan
// TODO tanh
// TODO transpose
// TODO trunc

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
		@memset(channel.bytes, 0);
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
	pub fn pixelIndex(width: u16, height: u16, x: u16, y: u16) u32 {
		std.debug.assert((x < width) and (y < height));
		// std.debug.print("INDEX: {d} x {d} -> {d}\n", .{ x, y, @as(u32, y) * @as(u32, width) + @as(u32, x) });
		return @as(u32, y) * @as(u32, width) + @as(u32, x); }

	/// Set the value of the pixel at the given coordinates.
	pub fn setPixel(self: *const Channel, width: u16, height: u16, x: u16, y: u16, value: u8) !void {
		std.debug.assert((x < width) and (y < height));
		const i: u32 = Channel.pixelIndex(width, height, x, y);
		self.bytes[i] = value; }

	/// Get the value of the pixel at the given coordinates.
	pub fn getPixel(self: *const Channel, width: u16, height: u16, x: u16, y: u16) !u8 {
		std.debug.assert((x < width) and (y < height));
		const i: u32 = Channel.pixelIndex(width, height, x, y);
		return self.bytes[i]; } };

const PixelShader = *const fn (x: u16, y: u16, userPtr: ?*anyopaque) AnyColor;

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

	pub fn empty() !Buffer {
		const buffer: Buffer = .{
			.channels = [4]Channel{
				try Channel.empty(),
				try Channel.empty(),
				try Channel.empty(),
				try Channel.empty() },
			.n_channels = 0,
			.width = 0,
			.height = 0 };
		return buffer; }

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
		for (0..n_channels) |i| {
			// std.debug.print("I = {d}\n", .{i});
			buffer.channels[i] = try Channel.new(width, height, allocator); }
		return buffer; }

	/// Get the index of the pixel at the given coordinates.
	pub fn pixelIndex(self: *const Buffer, x: u16, y: u16) u32 {
		return Channel.pixelIndex(self.width, self.height, x, y); }

	/// Set the color/value of the pixel at the given coordinates.
	pub fn setPixelColor(self: *const Buffer, x: u16, y: u16, anycolor: AnyColor) !void {
		for (0..self.n_channels) |i| {
			try self.channels[i].setPixel(self.width, self.height, x, y, anycolor.color[i]); } }

	/// Get the color/value of the pixel at the given coordinates.
	pub fn getPixelColor(self: *const Buffer, x: u16, y: u16) !AnyColor {
		std.debug.assert((x < self.width) and (y < self.height));
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
		// std.debug.print("Allocated {d} bytes for a {d} x {d} x {d} QOI image.\n", .{px_len, width, height, n_channels});
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
					px[B] = bytes[p]; p += 1;
					if (i <= 64) { std.debug.print("QOI_OP_RGB: {d} {d} {d}\n", .{px[R], px[G], px[B]}); } }
				else if (b1 == QOI_OP_RGBA) {
					px[R] = bytes[p]; p += 1;
					px[G] = bytes[p]; p += 1;
					px[B] = bytes[p]; p += 1;
					px[A] = bytes[p]; p += 1;
					if (i <= 64) { std.debug.print("QOI_OP_RGBA: {d} {d} {d} {d}\n", .{px[R], px[G], px[B], px[A]}); } }
				else if ((b1 & QOI_MASK_2) == QOI_OP_INDEX) {
					px = index[@as(u32, @intCast(b1))];
					if (i <= 64) { std.debug.print("QOI_OP_INDEX: {d} {d} {d}\n", .{px[R], px[G], px[B]}); } }
				else if ((b1 & QOI_MASK_2) == QOI_OP_DIFF) {
					px[R] = (px[R] +% ((b1 >> 4) & 0b11)) -% 2;
					px[G] = (px[G] +% ((b1 >> 2) & 0b11)) -% 2;
					px[B] = (px[B] +% ((b1 >> 0) & 0b11)) -% 2;
					if (i <= 64) { std.debug.print("QOI_OP_DIFF: {d} {d} {d}\n", .{px[R], px[G], px[B]}); } }
				else if ((b1 & QOI_MASK_2) == QOI_OP_LUMA) {
					const b2: u8 = bytes[p]; p += 1;
					const vg: u8 = (b1 & 0b111111);
					px[R] = px[R] +% vg;
					px[R] = px[R] +% ((b2 >> 4) & 0b1111);
					px[R] = px[R] -% 40;
					px[G] = px[G] +% vg;
					px[G] = px[G] -% 32;
					px[B] = px[B] +% vg;
					px[B] = px[B] +% ((b2 >> 0) & 0b1111);
					px[B] = px[B] -% 40;
					if (i <= 64) { std.debug.print("QOI_OP_LUMA: {d} {d} {d}\n", .{px[R], px[G], px[B]}); } }
				else if ((b1 & QOI_MASK_2) == QOI_OP_RUN) {
					run = @intCast(b1 & 0x3f);
					if (i <= 64) { std.debug.print("QOI_OP_RUN: {d} {d} {d}\n", .{px[R], px[G], px[B]}); } }
				index[qoiColorHash(px) & 0b111111] = px; }
			buffer.channels[R].bytes[i] = px[R];
			buffer.channels[G].bytes[i] = px[G];
			buffer.channels[B].bytes[i] = px[B];
			if (n_channels == 4) { buffer.channels[A].bytes[i] = px[A]; }
			// if ((i == 0) or (i == 4) or (i == 8) or (i == 12)) { std.debug.print("PX: {d} {d} {d} {d}\n", .{px[R], px[G], px[B], px[A]}); }
			i += 1; }
		buffer.width = @intCast(width);
		buffer.height = @intCast(height);
		buffer.n_channels = n_channels;
		return buffer; }

	/// Fill the given `Buffer` uniformly with a given value.
	pub fn fillA(self: *const Buffer, anycolor: AnyColor) !void {
		std.debug.assert(anycolor.n_channels == self.n_channels);
		for (0..self.n_channels) |i| {
			try self.channels[i].fill(anycolor.color[i]); } }

	pub fn fillS(self: *const Buffer, shader: PixelShader, userPtr: ?*anyopaque) !void {
		for (0..self.height) |y| { for (0..self.width) |x| {
			const point: [2]u16 = .{ @intCast(x), @intCast(y) };
			try self.setPixelColor(point[X], point[Y], shader(point[X], point[Y], userPtr)); } } }

	/// Draw a `Buffer` over the given `Buffer`. The two buffers must have the same dimensions.
	pub fn drawBuffer(self: *const Buffer, buffer: *const Buffer, blend_mode: BlendMode) !void {
		std.debug.print("SELF: {d} {d} {d}\nOTHER: {d} {d} {d}\n", .{ self.width, self.height, self.n_channels, buffer.width, buffer.height, buffer.n_channels });
		if ((self.width != buffer.width) or
			(self.height != buffer.height) or
			(self.n_channels != buffer.n_channels)) { return error.BufferMismatch; }
		for (0..self.height) |y| { for (0..self.width) |x| {
			// std.debug.print("{d} x {d}\n", .{ x, y });
			try self.setPixelColor(
				@intCast(x), @intCast(y),
				(try self.getPixelColor(@intCast(x), @intCast(y))).blend(try buffer.getPixelColor(@intCast(x), @intCast(y)), blend_mode)); } } }

	/// Draw a single point.
	pub fn drawPoint(self: *const Buffer, point: [2]u16, anycolor: AnyColor, blend_mode: BlendMode) !void {
		try self.setPixelColor(
			point[X], point[Y],
			(try self.getPixelColor(point[X], point[Y])).blend(anycolor, blend_mode)); }

	/// Draw an number of points.
	pub fn drawPoints(self: *const Buffer, points: [][2]u16, anycolor: AnyColor, blend_mode: BlendMode) !void {
		for (points) |point| {
			try self.setPixelColor(
				point[X], point[Y],
				(try self.getPixelColor(point[X], point[Y])).blend(anycolor, blend_mode)); } }

	/// Draw a uniformly-colored rectangle.
	pub fn drawRect(self: *const Buffer, rect: Rect, anycolor: AnyColor, blend_mode: BlendMode) !void {
		const x0 = std.math.clamp(rect.position[X] - rect.size[X] / 2, 0, self.width);
		const x1 = std.math.clamp(rect.position[X] + rect.size[X] / 2, 0, self.width);
		const y0 = std.math.clamp(rect.position[Y] - rect.size[Y] / 2, 0, self.height);
		const y1 = std.math.clamp(rect.position[Y] + rect.size[Y] / 2, 0, self.height);
		for (x0..x1) |x| { for (y0..y1) |y| {
			const point: [2]u16 = .{ @intCast(x), @intCast(y) };
			try self.setPixelColor(
				point[X], point[Y],
				(try self.getPixelColor(point[X], point[Y])).blend(anycolor, blend_mode)); } } }

	// TODO: Make multiple versions of each function, give them arbitrary names like drawRectsK, then make a bunch of games using this API, and then
	// analyze which ones were most useful and focus on making those good. This is evidence-driven API design.
	/// Draw a number of uniformly-colored rectangles.
	pub fn drawRects(self: *const Buffer, rects: []Rect, anycolor: AnyColor, blend_mode: BlendMode) !void {
		for (rects) |rect| {
			try self.drawRect(rect, anycolor, blend_mode); } }

};

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
		const bitmap: Bitmap = .{
			.bytes = try allocator.alloc(u8, @as(usize, width) * @as(usize, height) * @as(usize, n_channels)),
			.width = width, .height = height, .n_channels = n_channels };
		@memset(bitmap.bytes, 0);
		return bitmap; }

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

const IDC_ARROW:   [*c]const u8 = @ptrFromInt(32512);
const IDC_HAND:    [*c]const u8 = @ptrFromInt(32649);
const IDC_IBEAM:   [*c]const u8 = @ptrFromInt(32513);
const IDC_WAIT:    [*c]const u8 = @ptrFromInt(32514);
const IDC_NO:      [*c]const u8 = @ptrFromInt(32648);
const IDC_CROSS:   [*c]const u8 = @ptrFromInt(32515);
const IDC_UPARROW: [*c]const u8 = @ptrFromInt(32516);

fn windowProc(hwnd: win32.HWND, uMsg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.c) win32.LRESULT {
	// This pointer should be non-null only if windowProc is called after the creation, ie if the event is different from WM_CREATE
	const window_ptr: ?*Window = @ptrFromInt(@as(usize, @intCast(win32.GetWindowLongPtrA(hwnd, win32.GWLP_USERDATA))));
	const window: *Window = window_ptr orelse {
	   return win32.DefWindowProcA(hwnd, uMsg, wParam, lParam); };
	switch (uMsg) {
		win32.WM_DESTROY => {
			win32.PostQuitMessage(0); return 0; },
		win32.WM_LBUTTONDOWN => {
			window.mouseState.leftButton = 1; return 0; },
		win32.WM_LBUTTONUP => {
			window.mouseState.leftButton = 0; return 0; },
		win32.WM_MBUTTONDOWN => {
			window.mouseState.middleButton = 1; return 0; },
		win32.WM_MBUTTONUP => {
			window.mouseState.middleButton = 0; return 0; },
		win32.WM_MOUSEHOVER => {
			window.mouseState.hover = 1; return 0; },
		win32.WM_MOUSELEAVE => {
			window.mouseState.hover = 0; return 0; },
		win32.WM_MOUSEMOVE => {
			window.mouseState.positionX = @as(u16, @intCast(lParam & 0xFFFF));
			window.mouseState.positionY = @as(u16, @intCast((lParam >> 16) & 0xFFFF)); return 0; },
		win32.WM_MOUSEWHEEL => {
			window.mouseState.wheelDelta = @as(u16, @intCast((wParam >> 16) & 0xFFFF)); return 0; },
		win32.WM_SETCURSOR => {
			if (@as(u16, @intCast(lParam & 0xFFFF)) == win32.HTCLIENT) {
				_ = win32.SetCursor(win32.LoadCursorA(null, IDC_CROSS));
				return 0; }
			return win32.DefWindowProcA(hwnd, uMsg, wParam, lParam); },
		// std.meta.fieldIndex(flint.KeyboardState, "d") orelse 0
		win32.WM_KEYDOWN, win32.WM_KEYUP => {
			const keyState: u1 = if (uMsg == win32.WM_KEYDOWN) 1 else 0;
			switch (wParam) {
				'A'               => window.keyboardState.a          = keyState,
				'B'               => window.keyboardState.b          = keyState,
				'C'               => window.keyboardState.c          = keyState,
				'D'               => window.keyboardState.d          = keyState,
				'E'               => window.keyboardState.e          = keyState,
				'F'               => window.keyboardState.f          = keyState,
				'G'               => window.keyboardState.g          = keyState,
				'H'               => window.keyboardState.h          = keyState,
				'I'               => window.keyboardState.i          = keyState,
				'J'               => window.keyboardState.j          = keyState,
				'K'               => window.keyboardState.k          = keyState,
				'L'               => window.keyboardState.l          = keyState,
				'M'               => window.keyboardState.m          = keyState,
				'N'               => window.keyboardState.n          = keyState,
				'O'               => window.keyboardState.o          = keyState,
				'P'               => window.keyboardState.p          = keyState,
				'Q'               => window.keyboardState.q          = keyState,
				'R'               => window.keyboardState.r          = keyState,
				'S'               => window.keyboardState.s          = keyState,
				'T'               => window.keyboardState.t          = keyState,
				'U'               => window.keyboardState.u          = keyState,
				'V'               => window.keyboardState.v          = keyState,
				'W'               => window.keyboardState.w          = keyState,
				'X'               => window.keyboardState.x          = keyState,
				'Y'               => window.keyboardState.y          = keyState,
				'Z'               => window.keyboardState.z          = keyState,
				'0'               => window.keyboardState.n0         = keyState,
				'1'               => window.keyboardState.n1         = keyState,
				'2'               => window.keyboardState.n2         = keyState,
				'3'               => window.keyboardState.n3         = keyState,
				'4'               => window.keyboardState.n4         = keyState,
				'5'               => window.keyboardState.n5         = keyState,
				'6'               => window.keyboardState.n6         = keyState,
				'7'               => window.keyboardState.n7         = keyState,
				'8'               => window.keyboardState.n8         = keyState,
				'9'               => window.keyboardState.n9         = keyState,
				win32.VK_LCONTROL => window.keyboardState.leftCtrl   = keyState,
				win32.VK_LWIN     => window.keyboardState.leftSuper  = keyState,
				win32.VK_LMENU    => window.keyboardState.leftAlt    = keyState,
				win32.VK_LSHIFT   => window.keyboardState.leftShift  = keyState,
				win32.VK_RCONTROL => window.keyboardState.rightCtrl  = keyState,
				win32.VK_RWIN     => window.keyboardState.rightSuper = keyState,
				win32.VK_RMENU    => window.keyboardState.rightAlt   = keyState,
				win32.VK_RSHIFT   => window.keyboardState.rightShift = keyState,
				win32.VK_SPACE    => window.keyboardState.space      = keyState,
				win32.VK_TAB      => window.keyboardState.tab        = keyState,
				win32.VK_CAPITAL  => window.keyboardState.capsLock   = keyState,
				win32.VK_ESCAPE   => window.keyboardState.escape     = keyState,
				win32.VK_RETURN   => window.keyboardState.enter      = keyState,
				win32.VK_BACK     => window.keyboardState.backspace  = keyState,
				win32.VK_F1       => window.keyboardState.f1         = keyState,
				win32.VK_F2       => window.keyboardState.f2         = keyState,
				win32.VK_F3       => window.keyboardState.f3         = keyState,
				win32.VK_F4       => window.keyboardState.f4         = keyState,
				win32.VK_F5       => window.keyboardState.f5         = keyState,
				win32.VK_F6       => window.keyboardState.f6         = keyState,
				win32.VK_F7       => window.keyboardState.f7         = keyState,
				win32.VK_F8       => window.keyboardState.f8         = keyState,
				win32.VK_F9       => window.keyboardState.f9         = keyState,
				win32.VK_F10      => window.keyboardState.f10        = keyState,
				win32.VK_F11      => window.keyboardState.f11        = keyState,
				win32.VK_F12      => window.keyboardState.f12        = keyState,
				else => {} }
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

pub const MouseState = packed struct {
	leftButton:   u1 = 0,
	middleButton: u1 = 0,
	rightButton:  u1 = 0,
	hover:        u1 = 0,
	positionX:    u16 = 0,
	positionY:    u16 = 0,
	wheelDelta:   u32 = 0 };

pub const KeyboardState = packed struct {
	a:          u1 = 0,
	b:          u1 = 0,
	c:          u1 = 0,
	d:          u1 = 0,
	e:          u1 = 0,
	f:          u1 = 0,
	g:          u1 = 0,
	h:          u1 = 0,
	i:          u1 = 0,
	j:          u1 = 0,
	k:          u1 = 0,
	l:          u1 = 0,
	m:          u1 = 0,
	n:          u1 = 0,
	o:          u1 = 0,
	p:          u1 = 0,
	q:          u1 = 0,
	r:          u1 = 0,
	s:          u1 = 0,
	t:          u1 = 0,
	u:          u1 = 0,
	v:          u1 = 0,
	w:          u1 = 0,
	x:          u1 = 0,
	y:          u1 = 0,
	z:          u1 = 0,
	n0:         u1 = 0,
	n1:         u1 = 0,
	n2:         u1 = 0,
	n3:         u1 = 0,
	n4:         u1 = 0,
	n5:         u1 = 0,
	n6:         u1 = 0,
	n7:         u1 = 0,
	n8:         u1 = 0,
	n9:         u1 = 0,
	leftCtrl:   u1 = 0,
	leftSuper:  u1 = 0,
	leftAlt:    u1 = 0,
	leftShift:  u1 = 0,
	rightCtrl:  u1 = 0,
	rightSuper: u1 = 0,
	rightAlt:   u1 = 0,
	rightShift: u1 = 0,
	space:      u1 = 0,
	tab:        u1 = 0,
	capsLock:   u1 = 0,
	escape:     u1 = 0,
	enter:      u1 = 0,
	backspace:  u1 = 0,
	f1:         u1 = 0,
	f2:         u1 = 0,
	f3:         u1 = 0,
	f4:         u1 = 0,
	f5:         u1 = 0,
	f6:         u1 = 0,
	f7:         u1 = 0,
	f8:         u1 = 0,
	f9:         u1 = 0,
	f10:        u1 = 0,
	f11:        u1 = 0,
	f12:        u1 = 0 };

/// A window with a buffer. This is the only platform-dependent component of Flint.
pub const Window = struct {
	h_wnd:         win32.HWND = 0,
	h_dc:          win32.HDC = 0,
	width:         u16 = 1280,
	height:        u16 = 729,
	allocator:     std.mem.Allocator,
	buffer:        Buffer,
	mouseState:    MouseState = .{},
	keyboardState: KeyboardState = .{},

	/// Allocate and initialize a new `Window`.
	pub fn new(config: WindowConfig, allocator: std.mem.Allocator) !*Window {
		var window: *Window = try allocator.create(Window);
		window.* = .{
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
		_ = win32.SetWindowLongPtrA(window.h_wnd, win32.GWLP_USERDATA, @intCast(@as(usize, @intFromPtr(window))));
		const window_ptr: *Window = @ptrFromInt(@as(usize, @intCast(win32.GetWindowLongPtrA(window.h_wnd, win32.GWLP_USERDATA))));
		std.debug.assert(window_ptr == window);
		window.h_dc = win32.GetDC(window.h_wnd);
		std.debug.print("________________________________________\n", .{});
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

	/// Get the color of the pixel hovered by the cursor.
	pub fn getHoveredPixelColor(self: *const Window) !AnyColor {
		return self.buffer.getPixelColor(self.mouseState.positionX, self.mouseState.positionY); }

	pub fn getHoveredPixelIndex(self: *const Window) !u32 {
		return self.buffer.pixelIndex(self.mouseState.positionX, self.mouseState.positionY); }

	/// Draw the window `Buffer` to the window. The window is not updated automatically, you must call `draw` whenever you update the buffer and want the changes to take effect.
	pub fn draw(self: *const Window) !void {
		// TODO Move all this stuff inside the WM_PAINT message, and here just call `RedrawWindow`.

		// std.debug.print("BLACK: {d} {d} {d}\n", .{
		// self.buffer.channels[0].bytes[0],
		// self.buffer.channels[1].bytes[0],
		// self.buffer.channels[2].bytes[0] });

		// std.debug.print("RED: {d} {d} {d}\n", .{
		// self.buffer.channels[0].bytes[4],
		// self.buffer.channels[1].bytes[4],
		// self.buffer.channels[2].bytes[4] });

		// std.debug.print("GREEN: {d} {d} {d}\n", .{
		// self.buffer.channels[0].bytes[8],
		// self.buffer.channels[1].bytes[8],
		// self.buffer.channels[2].bytes[8] });

		// std.debug.print("BLUE: {d} {d} {d}\n", .{
		// self.buffer.channels[0].bytes[12],
		// self.buffer.channels[1].bytes[12],
		// self.buffer.channels[2].bytes[12] });
					// if ((i == 0) or (i == 4) or (i == 8) or (i == 12)) { std.debug.print("PX: {d} {d} {d} {d}\n", .{px[R], px[G], px[B], px[A]}); }


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
	/// The *foreground* and the *background* are divided.
	DIV,
	/// The higher value among the *foreground* and the *background* is taken.
	MAX,
	/// The lower value among the *foreground* and the *background* is taken.
	MIN };
