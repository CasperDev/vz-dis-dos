# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Laser310/VZ300 DOS 1.2'
copyright = '1984, Gerhard Wolf (translation 2023, Casper)'
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

from pygments.lexer import RegexLexer
from pygments import token
from sphinx.highlighting import lexers

class MyLangLexer(RegexLexer):
    name = 'MYLANG'

    tokens = {
        'root': [
            (r'MyKeyword', token.Keyword),
            (r'[a-zA-Z]', token.Name),
            (r'\s', token.Text)
        ]
    }

lexers['MYLANG'] = MyLangLexer(startinline=True)


    
