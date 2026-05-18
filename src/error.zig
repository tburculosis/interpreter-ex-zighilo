const std = @import("std");
const bugPrint = std.debug.print;




const Error = struct {
    line: u64,
    where: u8,
    message: []const u8,

    pub fn init(l: u64, m: []const u8) Error {
        report(l, "", m);
        
        return .{
            .line = l,
            .message = m,
        };
    }

    fn report(l: u64, w: u8, m: []const u8) void {
        bugPrint("[Line: {d}] Error {s}: {m}", .{l, w, m});
    }
};
