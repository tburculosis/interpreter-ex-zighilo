const std = @import("std");

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
    literal: type,
    line: u64,

    pub fn init(tok_type: TokenType, lex: []const u8, lit: type, line: u64) Token {
        return .{
            .tok_type = tok_type,
            .lexeme = lex, 
            .literal = lit, 
            .line = line,
        };
    }

    pub fn toString() []const u8 {
        //i doubt this will work
        var buff: [512]u8 = undefined;
        return std.fmt.bufPrint(
        &buff, 
        "{s} {s} {s}",
        .{.tok_type, .lexeme, .literal});
    }
};
