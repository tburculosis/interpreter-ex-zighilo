const std = @import("std");
const bugPrint = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Error = @import("error.zig").Error;

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
    tokens: ArrayList(Token), //re-impliment arrayLists as multiArrayLists (from arrays of structs to structs of arrays)
    errors: ArrayList(Error),
    alloc: Allocator,    

    pub fn init(alloc: Allocator, source: []const u8) Scanner {
        return .{
            .source = source,
            .tokens = ArrayList(Token).empty,
            .errors = ArrayList(Error).empty,
            .alloc = alloc,
        };
    }

    pub fn grabTokens(self: *Scanner) !void  {
        var start: u64 = 0;
        var current: u64 = 0;
        var line: u64 = 1;

        while (current < self.source.len) {
            start = current;
            if (self.source[current] == '\n')  {
                line += 1;
                current += 1;
            } else { 
                try scanToken(self, &current, line);
                current += 1; 
            }
        }
        try self.tokens.append(self.alloc, Token.init(TokenType.EOF, "",line));
    }

    //token engine
    fn scanToken(self: *Scanner, current: *u64, line: u64) !void {
        const index = @as(usize, current.*);
        const cur: u8 = self.source[index];

        switch (cur) {
            //ignore cases
            '\t' => { },
            '\r' => { },
            ' '  => { },

            //single char tokens 
            '(' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.LEFT_PAREN,
                    "",
                    line)); },
            ')' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.RIGHT_PAREN,
                    "",
                    line)); },
            '{' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.LEFT_BRACE,
                    "",
                    line)); },
            '}' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.RIGHT_BRACE,
                    "",
                    line)); },
            ',' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.COMMA,
                    "",
                    line)); },
            '.' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.DOT,
                    "",
                    line)); },
            '-' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.MINUS,
                    "",
                    line)); },
            '+' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.PLUS,
                    "",
                    line)); },
            ';' => { try self.tokens.append(
                self.alloc, 
                Token.init(
                    TokenType.SEMICOLON,
                    "",
                    line)); },
            '*' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.STAR,
                    "",
                    line)); },

            //double char tokens
            '!' => { 
                    if ( self.source[index + 1] == '=' ) { 
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.BANG_EQUAL,
                            "",
                            line));
                        current.* += 1;
                    } else {
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.BANG,
                            "",
                            line));
                    }
                },
            '=' =>  { 
                    if ( self.source[index + 1] == '=' ) { 
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.EQUAL_EQUAL,
                            "",
                            line));
                        current.* += 1;
                    } else {
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.EQUAL,
                            "",
                            line));
                    }
                },
            '<' => { 
                    if ( self.source[index + 1] == '=' ) { 
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.LESS_EQUAL,
                            "",
                            line));
                        current.* += 1;
                    } else {
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.LESS,
                            "",
                            line));
                    }
                },
            '>' => { 
                    if ( self.source[index + 1] == '=' ) { 
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.GREATER_EQUAL,
                            "",
                            line));
                        current.* += 1;
                    } else {
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.GREATER,
                            "",
                            line));
                    }
                },

            //dealing with the divide operator and the comment symbol
            '/' => {
                if (self.source[index + 1] == '/') {
                    var n: u8 = 2;
                    while (self.source[index + n] != '\n') { n += 1; }
                    //minus 1 to trigger the newline conditional
                    //in the calling while loop (a bit clumsy)
                    current.* += n - 1; 
                } else {
                    try self.tokens.append(
                    self.alloc,
                    Token.init(
                        TokenType.SLASH,
                        "",
                        line));
                }
            },
            
            //unrecognised token
            else => {
                try self.errors.append(
                self.alloc,
                Error.init(
                    line,
                    "Unrecognised token",
                    cur));
            }
        }
    }

    pub fn printTokens(self: *Scanner) void {
        bugPrint("Tokens in list: \n", .{});
        for (self.tokens.items) |i|
            bugPrint("{any}\n", .{i});
    }

    pub fn deinit_TokenList(self: *Scanner, alloc: Allocator) void {
        self.tokens.deinit(alloc);
    }

    pub fn deinit_ErrorList(self: *Scanner, alloc: Allocator) void {
        self.errors.deinit(alloc);
    }
};
