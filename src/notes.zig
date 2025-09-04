
// This file is not processed by the build function so I can write whatever I want here.
// What do I need to know about ZIG to make a simple board game in it?

// Some functions such as the one below require that you handle their result.
// Maybe this is for every function that returns an error union?
std.fs.File.stdout().writeAll("Hello, World!\n");

// If you prepend `try` to this expression, it will return the error, if there is one.
try std.fs.File.stdout().writeAll("Hello, World!\n");

// The above expression is very long. Instead, you can use:
std.debug.print("Hello, World!\n");
// I don't know what the downside of this is, but the fact that it's from `std.debug` suggests that it's not meant to be used in release builds.

// Syntax of value assignment:
(const|var) identifier[: type] = value
// * A value is either variable (mutable) or constant (immutable).
// * Typing is optional, types can be inferred.
// * Values are not optional. Every variable must be explicitly assigned a value.

// If you want to cast a variable to another type, use function @as. You might be tempted to wonder why the @ prefix. That is irrelevant!
const inferred_constant = @as(i32, 5);
var inferred_variable = @as(u32, 5000);

// Zig does not implicitly assign default values to identifiers.
// You are not allowed to use an identifier before you have explicitly assigned a value to it.
// If you want to declare an identifier and assign a value to it later, you can explicitly declare it as undefined.
const a: i32 = undefined;
var b: u32 = undefined;

// Arrays:
const a = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
const b = [_]u8{ 'w', 'o', 'r', 'l', 'd' };

[5]u8 // Explicit length.
[_]u8 // Inferred length.

const length = array.len; // Arrays have a length field.

// If-else statements seem to work just like in C:
if (a) {
	x += 1; }
else {
	x += 2; }
// You can omit the braces if you have just one expression (and no semicolons):
if (a)
	x += 1
else
	x += 2

// If you have a single expression, if behaves as an expression, equal to the result of the evaluated branch:
x += if (a)
	1
else
	2

x += if (a) 1 else 2
// This is very compact, but I think a bit unreadable. Avoid doing this. Instead wrap the branches in parentheses, like this:
x += if (a) { 1 } else { 2 }


