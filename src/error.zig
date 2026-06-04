const std = @import("std");
const bugPrint = std.debug.print;


const ErrorType = enum {
    UNKNOWN_TOKEN,
};

pub const Error = struct {
    line: u64,
    where: u8,
    message: []const u8,
    token: u8,

    pub fn init(l: u64, m: []const u8, t: u8) Error {
        report(l, 0, m, t);
        
        return .{
            .line = l,
            .where = 0,
            .message = m,
            .token = t,
        };
    }

    fn report(l: u64, w: u8, m: []const u8, t: u8) void {
        bugPrint("[Line: {d}] Error {d}: {s} => '{c}'\n", .{l, w, m, t});
    }
};
