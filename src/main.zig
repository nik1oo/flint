const std = @import("std");

pub fn main() !void {
	var x: i32 = 14;
	x += 1;
	if (true)
		x = 99
	else {
		x = 2; }
	std.debug.print("This is Board Game {s} {d}.\n", .{"1", x});
}
