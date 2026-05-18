const std = @import("std");
const Error = @import("error.zig");
const Token = @import("token.zig");

const bugPrint = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

//TODO - create a scanner(tokeniser)

const lox = struct {
   
    fn scan(filename: [:0]const u8, alloc: Allocator) !void {
        if (filename.len < 1) {
            try runPrompt(alloc);
        } else {
            try runFile(filename, alloc);
        }     
    }

    fn runFile(filename: []const u8, alloc: Allocator) !void {
        bugPrint("scanning {s}\n", .{filename});
        
        const file = try std.fs.cwd().openFile(
        filename, 
        .{ .mode = .read_only }
        );
        
        defer file.close();
        const file_size = (try file.stat()).size;

        const buffer = try alloc.alloc(u8, file_size);
        defer alloc.free(buffer);

        var reader = file.reader(buffer);
        try reader.interface.fill(@as(usize, file_size));

        bugPrint("file size: {any}\n", .{file_size});
        
        for (0..buffer.len) |i| {
            if (i == file_size - 1) {
                bugPrint("{c}\n", .{buffer[i]});
            } else {
                bugPrint("{c}", .{buffer[i]});
            }
        }

    }

    fn runPrompt(alloc: Allocator) !void {
        bugPrint("Running prompt\n", .{});

        while (true) { 
            var stdin_buffer: [1024]u8 = undefined;
            var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
            const line = try stdin_reader.interface.takeDelimiterExclusive('\n');

            if (line.len == 0) { break; }
            else { runLine(line, alloc); } 
        }

        bugPrint("broke out of runPrompt loop\n", .{});
    }


    fn runLine(line: []const u8, alloc: Allocator) void {
        bugPrint("Running line\n", .{});

        for (0..line.len) |i| {
            if (i == line.len - 1) {
                bugPrint("{c}\n", .{line[i]});
            } else { 
                bugPrint("{c}", .{line[i]}); 
            }
        }
            
        //grab tokens and print
        //const tokens = try Scanner.grabTokens(line, alloc);
        //tokens.spew();
    }
};


pub fn main() !void {
    
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var argv = try std.process.argsWithAllocator(alloc); 
    defer argv.deinit();

    _ = argv.next();
    const filename = if (argv.next()) |a|   
                                    std.mem.sliceTo(a, 0) 
                                    else "";
    
    try lox.scan(filename, alloc);
}
