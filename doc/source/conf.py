# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Laser310/VZ300 DOS 1.2'
copyright = '1985, Gerhard Wolf (translation 2023, Casper)'
author = 'Gerhard Wolf (translated by Casper)'
release = '1.0'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.todo',
    'sphinx.ext.coverage',
	'sphinx_rtd_theme',
]

templates_path = ['_templates']
exclude_patterns = []

source_suffix = '.rst'

# The master toctree document.
master_doc = 'index'

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

from pygments.lexer import RegexLexer, include
from pygments.token import Text, Name, Number, String, Comment, Punctuation
from sphinx.highlighting import lexers

class Z80Lexer(RegexLexer):
    name = 'Z80'
    aliases = ['z80', 'asm']
    filenames = ['*.z80', '.asm']

    string = r'"(\\"|[^"])*"'
    sstring = r"'(\\'|[^'])*'"
    char = r'[\w$.@-]'
    identifier = r'(?:[a-zA-Z$_]' + char + '*|\.' + char + '+)'
    number = r'(?:0[xX][a-fA-F0-9]+|[a-fA-F0-9]+[hH]|\$[a-fA-F0-9]+|\d+)'
    register = r'\b(?i:[abcdefhlir]|ix|iy|af\'?|bc|de|hl|pc|sp|ix[luh]|iy[luh]|[lh]x|x[lh]|[lh]y|y[lh])\b'
    opcode_jmp = r'(?i:(j[pr]|call|ret)+(\s+n[zc]+|\s+[zc]|\s+p[eo]|\s+[pm])?)'
    tokens = {
        'root': [
            include('whitespace'),
            (identifier + ':', Name.Label),
            (number + ':', Name.Label),
            (r'\.' + identifier, Name.Attribute, 'directive-args'),
            (identifier, Name.Function, 'instruction-args'),
            (r'[\r\n]+', Text)
        ],
        'directive-args': [
            (identifier, Name.Constant),
            (sstring, String),
            (string, String),
            (number, Number.Integer),
            (r'[\r\n]+', Text, '#pop'),
            include('punctuation'),
            include('whitespace')
        ],
        'instruction-args': [
            (identifier, Name.Constant),
            (sstring, String),
			(string, String),
            (number, Number.Integer),
            # Registers
            (register, Name.Variable),
            (r"'(.|\\')'?", String.Char),
            (r'[\r\n]+', Text, '#pop'),
            include('punctuation'),
            include('whitespace')
        ],
        'whitespace': [
            (r'[ \t]', Text),
            (r'//[\w\W]*?(?=\n)', Comment.Single),
            (r'/[*][\w\W]*?[*]/', Comment.Multiline),
            (r'[;@].*?(?=\n)', Comment.Single)
        ],
        'punctuation': [
            (r'[-*,.()\[\]!:{}^=#\+\\]+', Punctuation)
        ],
        'eol': [
            (r'[\r\n]+', Text)
        ],
    }

lexers['Z80'] = Z80Lexer(startinline=True)


    
