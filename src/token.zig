const std = @import("std");
const bugPrint = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const TokenType = enum {
    
    //single-char tokens
    LEFT_PAREN, RIGHT_PAREN,
    LEFT_BRACE, RIGHT_BRACE, 
    COMMA, DOT, MINUS, PLUS,
    SEMICOLON, SLASH, STAR,

    //one or two char tokens
    BANG, BANG_EQUAL,
    EQUAL, EQUAL_EQUAL,
    GREATER, GREATER_EQUAL,
    LESS, LESS_EQUAL,

    //literals
    IDENTIFIER, STRING, NUMBER,

    //keywords
    AND, CLASS, ELSE, FALSE,
    FUN, FOR, IF, NIL, OR,
    PRINT, RETURN, SUPER, THIS,
    TRUE, VAR, WHILE,

    EOF
};

const Token = struct {
    
    tok_type: TokenType,
    lexeme: []const u8,
    //literal: type,
    line: u64,

    pub fn init(tok_type: TokenType, lex: []const u8, line: u64) Token {
        return .{
            .tok_type = tok_type,
            .lexeme = lex, 
            .line = line,
        };
    }

    pub fn toString() []const u8 {
        //i doubt this will work
        var buff: [512]u8 = undefined;
        return std.fmt.bufPrint(
        &buff, 
        "{any} {any} {any}",
        .{.tok_type, .lexeme, .literal});
    }
};

pub const Scanner = struct {
    source: []const u8,
    tokens: ArrayList(Token),
    alloc: Allocator,    

    pub fn init(alloc: Allocator, sour: []const u8) Scanner {
        return .{
            .source = sour,
            .tokens = ArrayList(Token).empty,
            .alloc = alloc,
        };
    }

    pub fn grabTokens(self: *Scanner) !void  {
        var start: u64 = 0;
        var current: u64 = 0;
        var line: u64 = 1;

        while (current < self.source.len) {
            start = current;
            bugPrint("{c}", .{self.source[current]});
            if (self.source[current] == '\n')  {
                line += 1;
                current += 1;
            } else { 
                try scanToken(self, current, line);
                current += 1; 
            }
        }
        try self.tokens.append(self.alloc, Token.init(TokenType.EOF, "",line));
    }

    fn scanToken(self: *Scanner, current: u64, line: u64) !void {
        const cur: u8 = self.source[current];

        switch (cur) {
            '(' => { try self.tokens.append(self.alloc, Token.init(TokenType.LEFT_PAREN, "", line)); },
            ')' => { try self.tokens.append(self.alloc, Token.init(TokenType.RIGHT_PAREN, "", line)); },
            '{' => { try self.tokens.append(self.alloc, Token.init(TokenType.LEFT_BRACE, "", line)); },
            '}' => { try self.tokens.append(self.alloc, Token.init(TokenType.RIGHT_BRACE, "", line)); },
            ',' => { try self.tokens.append(self.alloc, Token.init(TokenType.COMMA, "", line)); },
            '.' => { try self.tokens.append(self.alloc, Token.init(TokenType.DOT, "", line)); },
            '-' => { try self.tokens.append(self.alloc, Token.init(TokenType.MINUS, "", line)); },
            '+' => { try self.tokens.append(self.alloc, Token.init(TokenType.PLUS, "", line)); },
            ';' => { try self.tokens.append(self.alloc, Token.init(TokenType.SEMICOLON, "",line)); },
            '*' => { try self.tokens.append(self.alloc, Token.init(TokenType.STAR, "",line)); },
            else => {
                bugPrint("Unexpected token: {c}\n", .{cur});
            }
        }
    }

    pub fn printTokens(self: *Scanner) void {
        bugPrint("Tokens in list: \n", .{});
        for (self.tokens.items) |i|
            bugPrint("{any}\n", .{i});
    }

    pub fn deinit_arrayList(self: *Scanner, alloc: Allocator) void {
        self.tokens.deinit(alloc);
    }
};
