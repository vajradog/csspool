module CSSPool
module CSS
class Tokenizer < Parser

macro
  nl        \n|\r\n|\r|\f
  w         [\s\r\n\f]*
  nonascii  [^\0-\177]
  num       ([0-9]*\.[0-9]+|[0-9]+)
  unicode   \\[0-9A-Fa-f]{1,6}(\r\n|[\s\n\r\t\f])?

  escape    {unicode}|\\[^\n\r\f0-9A-Fa-f]
  nmchar    [_A-Za-z0-9-]|{nonascii}|{escape}
  nmstart   [_A-Za-z]|{nonascii}|{escape}
  ident     [-@]?({nmstart})({nmchar})*
  name      ({nmchar})+
  string1   "([^\n\r\f"]|{nl}|{nonascii}|{escape})*"
  string2   '([^\n\r\f']|{nl}|{nonascii}|{escape})*'
  string    ({string1}|{string2})
  invalid1  "([^\n\r\f"]|{nl}|{nonascii}|{escape})*
  invalid2  '([^\n\r\f']|{nl}|{nonascii}|{escape})*
  invalid   ({invalid1}|{invalid2})
  comment   \/\*(.|{w})*?\*\/

rule

# [:state]  pattern  [actions]

            url\({w}{string}{w}\) { [:URI, text] }
            url\({w}([!#\$%&*-~]|{nonascii}|{escape})*{w}\) { [:URI, text] }
            U\+[0-9a-fA-F?]{1,6}(-[0-9a-fA-F]{1,6})?  {[:UNICODE_RANGE, text] }
            {w}{comment}{w}  { next_token }

            {ident}\(\s*     { [:FUNCTION, text] }
            {w}@import{w}    { [:IMPORT_SYM, text] }
            {w}@page{w}      { [:PAGE_SYM, text] }
            {w}@charset{w}   { [:CHARSET_SYM, text] }
            {w}@media{w}     { [:MEDIA_SYM, text] }
            {w}!({w}|{w}{comment}{w})important{w}  { [:IMPORTANT_SYM, text] }
            {ident}          { [:IDENT, text] }
            \#{name}         { [:HASH, text] }
            {w}~={w}         { [:INCLUDES, text] }
            {w}\|={w}        { [:DASHMATCH, text] }
            {w}\^={w}        { [:PREFIXMATCH, text] }
            {w}\$={w}        { [:SUFFIXMATCH, text] }
            {w}\*={w}        { [:SUBSTRINGMATCH, text] }
            {w}!={w}         { [:NOT_EQUAL, text] }
            {w}={w}          { [:EQUAL, text] }
            {w}\)            { [:RPAREN, text] }
            {w}\[{w}         { [:LSQUARE, text] }
            {w}\]            { [:RSQUARE, text] }
            {w}\+{w}         { [:PLUS, text] }
            {w}\{{w}         { [:LBRACE, text] }
            {w}\}{w}         { [:RBRACE, text] }
            {w}>{w}          { [:GREATER, text] }
            {w},{w}          { [:COMMA, ','] }
            {w};{w}          { [:SEMI, ';'] }
            {w}\*{w}         { [:STAR, text] }
            {w}~{w}          { [:TILDE, text] }
            \:not\({w}       { [:NOT, text]  }
            {w}{num}em{w}    { [:EMS, text] }
            {w}{num}ex{w}    { [:EXS, text] }

            {w}{num}(px|cm|mm|in|pt|pc){w}    { [:LENGTH, text] }
            {w}{num}(deg|rad|grad){w} { [:ANGLE, text] }
            {w}{num}(ms|s){w} { [:TIME, text] }
            {w}{num}[kK]?[hH][zZ]{w} { [:FREQ, text] }

            {w}{num}%{w}     { [:PERCENTAGE, text] }
            {w}{num}{w}      { [:NUMBER, text] }
            {w}\/\/{w}       { [:DOUBLESLASH, text] }
            {w}\/{w}         { [:SLASH, '/'] }
            <!--             { [:CDO, text] }
            -->              { [:CDC, text] }
            {w}\-{w}         { [:MINUS, text] }
            {w}\+{w}         { [:PLUS, text] }
            
            
            [\s\t\r\n\f]+    { [:S, text] }
            {string}         { [:STRING, text] }
            {invalid}        { [:INVALID, text] }
            .                { [text, text] }
end
end
end

# vim: syntax=lex
