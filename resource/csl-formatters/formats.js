/**
 * Markdown output format specification.
 */
CSL.Output.Formats.markdown = {
  //
  // text_escape: Format-specific function for escaping text destined
  // for output.  Takes the text to be escaped as sole argument.  Function
  // will be run only once across each portion of text to be escaped, it
  // need not be idempotent.
  //
  text_escape: function (text) {
    // Numeric entities, in case the output is processed as
    // xml in an environment in which HTML named entities are
    // not declared.
    if (!text) { text = ""; }
    return text.replace(/</g, "&lt;")
               .replace(/>/g, "&gt;")
               .replace(/[_\\\*#`]/g, function(ch) { return '\\' + ch; })
               .replace(/\u00a9/g, '(c)')
               .replace(/\u00ae/g, '(r)')
               .replace(/\u2122/g, '(tm)')
               .replace(/\u00a0/g, ' ')
               .replace(/\u00b7/g, '\\*')
               .replace(/[\u2002\u2003\u2009]/g, ' ')
               .replace(/[\u2018\u2019]/g, '\'')
               .replace(/[\u201c\u201d]/g, '"')
               .replace(/\u2026/g, '...')
               .replace(/\u2013/g, '--')
               .replace(/\u2014/g, '---')
               .replace(CSL.SUPERSCRIPTS_REGEXP, function(ch) { return "<sup>" + CSL.SUPERSCRIPTS[ch] + "</sup>"; });
    },

    bibstart: '<div class=\'csl-bib-body\'>\n',
    bibend: '</div>',

    '@font-style/italic': '_%%STRING%%_',
    '@font-style/oblique': '_%%STRING%%_',
    '@font-style/normal': false,
    '@font-variant/small-caps': '<span style=\'font-variant:small-caps;\'>%%STRING%%</span>',
    '@passthrough/true': CSL.Output.Formatters.passthrough,
    '@font-variant/normal': false,
    '@font-weight/bold': false,
    '@font-weight/normal': false,
    '@font-weight/light': false,
    '@text-decoration/none': false,
    '@text-decoration/underline': false,
    '@vertical-align/sup': '<sup>%%STRING%%</sup>',
    '@vertical-align/sub': '<sub>%%STRING%%</sub>',
    '@vertical-align/baseline': false,
    '@strip-periods/true': CSL.Output.Formatters.passthrough,
    '@strip-periods/false': CSL.Output.Formatters.passthrough,
    '@quotes/true': function (state, str) {
        if ('undefined' === typeof str) {
            return state.getTerm('open-quote');
        }
        return state.getTerm('open-quote') + str + state.getTerm('close-quote');
    },
    '@quotes/inner': function (state, str) {
        if ('undefined' === typeof str) {
            //
            // Mostly right by being wrong (for apostrophes)
            //
            return '\u2019';
        }
        return state.getTerm('open-inner-quote') + str + state.getTerm('close-inner-quote');
    },
    '@quotes/false': false,
    //'@bibliography/body': function (state,str){
    //    return '<div class=\'csl-bib-body\'>\n'+str+'</div>';
    //},
    '@cite/entry': function (state, str) {
        return state.sys.wrapCitationEntry(str, this.item_id, this.locator_txt, this.suffix_txt);
	  },
    '@bibliography/entry': function (state, str) {
        // Test for this.item_id to add decorations to
        // bibliography output of individual entries.
        //
        // Full item content can be obtained from
        // state.registry.registry[id].ref, using
        // CSL variable keys.
        //
        // Example:
        //
        //   print(state.registry.registry[this.item_id].ref['title']);
        //
        // At present, for parallel citations, only the
        // id of the master item is supplied on this.item_id.
        var insert = '';
        if (state.sys.embedBibliographyEntry) {
            insert = state.sys.embedBibliographyEntry(this.item_id) + '\n';
        }
        return '  <div class=\'csl-entry\'>' + str + '</div>\n' + insert;
    },
    '@display/block': function (state, str) {
        return '\n\n    <div class=\'csl-block\'>' + str + '</div>\n';
    },
    '@display/left-margin': function (state, str) {
        return '\n    <div class=\'csl-left-margin\'>' + str + '</div>';
    },
    '@display/right-inline': function (state, str) {
        return '<div class=\'csl-right-inline\'>' + str + '</div>\n  ';
    },
    '@display/indent': function (state, str) {
        return '<div class=\'csl-indent\'>' + str + '</div>\n  ';
    },
    '@showid/true': function (state, str, cslid) {
        if (!state.tmp.just_looking && ! state.tmp.suppress_decorations) {
            if (cslid) {
                return '<span class=\'' + state.opt.nodenames[cslid] + '\' cslid=\'' + cslid + '\'>' + str + '</span>';
            } else if ('string' === typeof str) {
                var prePunct = '';
                if (str) {
                    var m = str.match(CSL.VARIABLE_WRAPPER_PREPUNCT_REX);
                    prePunct = m[1];
                    str = m[2];
                }
                var postPunct = '';
                if (str && CSL.SWAPPING_PUNCTUATION.indexOf(str.slice(-1)) > -1) {
                    postPunct = str.slice(-1);
                    str = str.slice(0,-1);
                }
                return state.sys.variableWrapper(this.params, prePunct, str, postPunct);
            } else {
                return str;
            }
        } else {
            return str;
        }
    },
    '@URL/true': function (state, str) {
        return '<a href=\'' + str + '\'>' + str + '</a>';
    },
    '@DOI/true': function (state, str) {
        return '<a href=\'http://dx.doi.org/' + str + '\'>' + str + '</a>';
    }
};

CSL.Output.Formats = new CSL.Output.Formats();
