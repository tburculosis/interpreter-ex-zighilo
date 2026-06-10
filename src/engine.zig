const std = @import("std");
const bugPrint = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Error = @import("error.zig").Error;
const StringHashMap = std.StringHashMap;
const isDigit = std.ascii.isDigit;
const isAplha = std.ascii.isAlphabetic;
const isAlphaNum = std.ascii.isAlphanumeric;

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

    //end of file
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
    keywords: StringHashMap(TokenType),

    pub fn init(alloc: Allocator, source: []const u8) Scanner {
        return .{
            .source = source,
            .tokens = ArrayList(Token).empty,
            .errors = ArrayList(Error).empty,
            .alloc = alloc,
            .keywords = StringHashMap(TokenType).init(alloc),
        };
    }
    
    fn keywords_init(self: *Scanner) !void {
        try self.keywords.put("and", TokenType.AND);
        try self.keywords.put("class", TokenType.CLASS);
        try self.keywords.put("else", TokenType.ELSE);
        try self.keywords.put("false", TokenType.FALSE);
        try self.keywords.put("for", TokenType.FOR);
        try self.keywords.put("fun", TokenType.FUN);
        try self.keywords.put("if", TokenType.IF);
        try self.keywords.put("nil", TokenType.NIL);
        try self.keywords.put("or", TokenType.OR);
        try self.keywords.put("print", TokenType.PRINT);
        try self.keywords.put("return", TokenType.RETURN);
        try self.keywords.put("super", TokenType.SUPER);
        try self.keywords.put("this", TokenType.THIS);
        try self.keywords.put("true", TokenType.TRUE);
        try self.keywords.put("var", TokenType.VAR);
        try self.keywords.put("while", TokenType.WHILE);
    }

    //grabTokens stores current position of token engine
    pub fn grabTokens(self: *Scanner) !void  {
        //filling hashmap with keywords
        try keywords_init(self);

        var start: u64 = 0;
        var current: u64 = 0;
        var line: u64 = 1;
        
        while (!(current >= self.source.len)) {
            start = current;
            //calling token engine
            try scanToken(self, &current, &line);
            current += 1; 
        }

        try self.tokens.append(
            self.alloc,
            Token.init(
                TokenType.EOF,
                "EOF",
                line));
    }

    //token engine
    fn scanToken(self: *Scanner, current: *u64, line: *u64) !void {
        const index = @as(usize, current.*);
        const cur: u8 = self.source[index];

        bugPrint("Current symbol under scanner: {c}\n", .{cur});

        switch (cur) {
            //ignore cases
            '\t' => { },
            '\r' => { },
            ' '  => { },
            '\n' => { line.* += 1; },
            
            //single char tokens 
            '(' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.LEFT_PAREN,
                    "(",
                    line.*)); },
            ')' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.RIGHT_PAREN,
                    ")",
                    line.*)); },
            '{' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.LEFT_BRACE,
                    "{",
                    line.*)); },
            '}' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.RIGHT_BRACE,
                    "}",
                    line.*)); },
            ',' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.COMMA,
                    ",",
                    line.*)); },
            '.' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.DOT,
                    ".",
                    line.*)); },
            '-' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.MINUS,
                    "-",
                    line.*)); },
            '+' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.PLUS,
                    "=",
                    line.*)); },
            ';' => { try self.tokens.append(
                self.alloc, 
                Token.init(
                    TokenType.SEMICOLON,
                    ";",
                    line.*)); },
            '*' => { try self.tokens.append(
                self.alloc,
                Token.init(
                    TokenType.STAR,
                    "*",
                    line.*)); },

            //double char tokens
            '!' => { 
                    if ( self.source[index + 1] == '=' ) { 
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.BANG_EQUAL,
                            "!=",
                            line.*));
                        current.* += 1;
                    } else {
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.BANG,
                            "!",
                            line.*));
                    }
                },
            '=' =>  { 
                    if ( self.source[index + 1] == '=' ) { 
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.EQUAL_EQUAL,
                            self.source[index..index + 1],
                            line.*));
                        current.* += 1;
                    } else {
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.EQUAL,
                            "=",
                            line.*));
                    }
                },
            '<' => { 
                    if ( self.source[index + 1] == '=' ) { 
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.LESS_EQUAL,
                            self.source[index..index + 2],
                            line.*));
                        current.* += 1;
                    } else {
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.LESS,
                            "<",
                            line.*));
                    }
                },
            '>' => { 
                    if ( self.source[index + 1] == '=' ) { 
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.GREATER_EQUAL,
                            self.source[index..index + 1],
                            line.*));
                        current.* += 1;
                    } else {
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.GREATER,
                            ">",
                            line.*));
                    }
                },

            //dealing with the divide operator and the comment symbol
            '/' => {
                if (self.source[index + 1] == '/') {
                    var n: u8 = 2;
                    while (self.source[index + n] != '\n') { n += 1; }
                    current.* += n; 
                } else {
                    try self.tokens.append(
                    self.alloc,
                    Token.init(
                        TokenType.SLASH,
                        "/",
                        line.*));
                }
            },

            //string literals
           '"' => {
                    var n: usize = 1;
                    var lineCount: u8 = 0;
                    while ((index + n) < self.source.len and self.source[index + n] != '"') {
                        if (self.source[index + n] == '\n') {
                            //track if string spans multiple lines 
                            lineCount += 1;
                        }
                        n += 1;
                    }
                    
                    //unterminated string case
                    if (index + n == self.source.len) {
                        try self.errors.append(
                            self.alloc,
                            Error.init(
                                //unix files typically end with a \n
                                //minus 1 gives a better line count
                                line.* + lineCount - 1, 
                                "Unterminated string",
                                cur));
                    } else {
                        current.* += n;
                        // plus 1 to grab the closing quotation mark
                        const string: []const u8 = self.source[index..index + (n + 1)]; 
                        try self.tokens.append(
                            self.alloc,
                            Token.init(
                                TokenType.STRING,
                                string,
                                line.*));
                        //store the line the string starts on in token
                        //then update the scanner's line data
                        line.* += lineCount;
                    }
                }, 

            //number literal, keyword, identifier, or unrecognised tokens (dubious)
            else => {

                //number literals
                if (isDigit(self.source[index])) {
                    var n: u8 = if (self.source[index + 1] == '.') 2 else 1;
                    while (isDigit(self.source[index  + n])) {
                        if (self.source[index + n + 1] == '.') {
                            n += 2;
                        } else {
                            n += 1;
                        }
                    }
                    
                    const number: []const u8 = self.source[index..index + n];
                    //minus 1 to trigger the line counter on the next scan
                    current.* += (n - 1); 

                    try self.tokens.append(
                        self.alloc,
                        Token.init(
                            TokenType.NUMBER,
                            number,
                            line.*));

                //identifiers and keywords
                } else if (isAplha(self.source[index])) {
                    var n: u8 = 1;
                    while(isAlphaNum(self.source[index + n])) {
                        n += 1;
                    }

                    const identifier: []const u8 = self.source[index..index + n];
                    //minus 1 to trigger new line counter
                    current.* += (n - 1);

                    const is_keyword = self.keywords.get(identifier);
                        
                    //if null, not a keyword
                    if (is_keyword) |t| { 
                        try self.tokens.append(
                        self.alloc,
                        Token.init(
                            t,
                            identifier,
                            line.*)); 
                    } else {
                        try self.tokens.append(
                            self.alloc,
                            Token.init(
                                TokenType.IDENTIFIER,
                                identifier,
                                line.*));
                    }

                //unrecognised token error
                } else {
                    try self.errors.append(
                    self.alloc,
                    Error.init(
                        line.*,
                        "Unrecognised token",
                        cur)); 
                }
            }
        }
    }

    pub fn printTokens(self: *Scanner) void {
        bugPrint("Tokens in list: \n", .{});
        for (self.tokens.items) |i|
            bugPrint("{any} => lexeme: {s}\n", .{i, i.lexeme});
    }

    //call defer on this immediately after initialising scanner
    pub fn deinit_scanner(self: *Scanner, alloc: Allocator) void {
        self.tokens.deinit(alloc);
        self.errors.deinit(alloc);
        self.keywords.deinit();
    }
};
