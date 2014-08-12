@export
Feature: Export

@bbltx-e-1 @e-1
Scenario: Better BibLaTeX Export 1
  When I import 'export/Better BibLaTeX.001.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.001.bib'

@btxck-e-1 @e-2
Scenario: BibTeX Citation Keys Export 1
  When I import 'export/BibTeX Citation Keys.001.json'
  Then I should find the following citation keys:
    | key       |
    | Adams2001 |

@pc-e-1
Scenario: Pandoc Citation Export 1
  When I import 'export/Pandoc Citation.001.json'
  Then A library export using 'Pandoc Citation' should match 'export/Pandoc Citation.001.txt'

@bbltx-e-2
Scenario: Better BibLaTeX Export 2
  When I import 'export/Better BibLaTeX.002.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.002.bib'

@bbltx-e-3
Scenario: Better BibLaTeX Export 3
  When I import 'export/Better BibLaTeX.003.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.003.bib'

@bbltx-e-4
Scenario: Better BibLaTeX Export 4
  When I import 'export/Better BibLaTeX.004.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.004.bib'

@bbltx-e-5
Scenario: Better BibLaTeX Export 5
  When I import 'export/Better BibLaTeX.005.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.005.bib'

@bbltx-e-6
Scenario: Better BibLaTeX Export 6
  When I import 'export/Better BibLaTeX.006.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.006.bib'

@bbltx-e-7
Scenario: Better BibLaTeX Export 7
  When I import 'export/Better BibLaTeX.007.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.007.bib'

@bbltx-e-8
Scenario: Better BibLaTeX Export 8
  When I import 'export/Better BibLaTeX.008.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.008.bib'

@bbltx-e-9
Scenario: Better BibLaTeX Export 9
  When I import 'export/Better BibLaTeX.009.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.009.bib'

@bbltx-e-10
Scenario: Better BibLaTeX Export 10
  When I import 'export/Better BibLaTeX.010.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.010.bib'

@bbltx-e-11
Scenario: Better BibLaTeX Export 11
  When I import 'export/Better BibLaTeX.011.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.011.bib'

@advanced-keygen
Scenario: Advanced key generator usage
  When I import 'export/Better BibLaTeX.012.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[DOI]+[Title:fold:ascii:skipwords:select,1,4:condense,_]'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.012.bib'

@bbltx-e-13
Scenario: Better BibLaTeX Export 13
  When I import 'export/Better BibLaTeX.013.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[shorttitle]'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.013.bib'

@bbltx-e-14
Scenario: Better BibLaTeX Export 14
  When I import 'export/Better BibLaTeX.014.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[shorttitle]'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.014.bib'

@bbltx-e-15
Scenario: Better BibLaTeX Export 15
  When I import 'export/Better BibLaTeX.015.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[shorttitle]'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.015.bib'

@bbltx-e-16
Scenario: Better BibLaTeX Export 16
  When I import 'export/Better BibLaTeX.016.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[auth:lower][year]'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.016.bib'

@bbltx-e-17
Scenario: Better BibLaTeX Export 17
  When I import 'export/Better BibLaTeX.017.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[auth:lower][year]'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.017.bib'

@bbtx-e-18
Scenario: Better BibTeX Export 18
  When I import 'export/Better BibTeX.018.json'
  Then A library export using 'Better BibTeX' should match 'export/Better BibTeX.018.bib'

@bbltx-e-19
Scenario: Better BibLaTeX Export 19
  When I import 'export/Better BibLaTeX.019.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.019.bib'

@bbltx-e-20
Scenario: Better BibLaTeX Export 20
  When I import 'export/Better BibLaTeX.020.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.020.bib'

@bbltx-e-21
Scenario: Better BibLaTeX Export 21
  When I import 'export/Better BibLaTeX.021.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.021.bib'

@bbltx-e-22
Scenario: Better BibLaTeX Export 22
  When I import 'export/Better BibLaTeX.022.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[auth][year]-[shorttitle]'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.022.bib'

@bbltx-e-23
Scenario: Better BibLaTeX Export 23
  When I import 'export/Better BibLaTeX.023.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.023.bib'

@btxck-e-24
Scenario: BibTeX Citation Keys Export 24
  When I import 'export/BibTeX Citation Keys.024.json'
  Then I should find the following citation keys:
    | key        |
    | Adams2001  |
    | Adams2001a |

@bbtx-e-26
Scenario: Better BibTeX Export 26
  When I import 'export/Better BibTeX.026.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[auth:lower][year:(ND)][shorttitle:lower]'
  Then A library export using 'Better BibTeX' should match 'export/Better BibTeX.026.bib'

@bbtx-e-27
Scenario: Better BibTeX Export 27
  When I import 'export/Better BibTeX.027.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[authors][year]'
  Then A library export using 'Better BibTeX' should match 'export/Better BibTeX.027.bib'

@journal-abbrev
Scenario: Journal abbreviations
  When I import 'export/Better BibTeX.029.json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[authors][year][journal]'
   And I set preference extensions.zotero.translators.better-bibtex.auto-abbrev to true
   And I set preference extensions.zotero.translators.better-bibtex.auto-abbrev.style to 'http://www.zotero.org/styles/cell'
   And I set export option useJournalAbbreviation to true
  Then A library export using 'Better BibTeX' should match 'export/Better BibTeX.029.bib'

@stable-keys
Scenario: Stable citation keys
  When I import 'export/Better BibLaTeX.stable-keys.json'
   And I import 'export/Better BibLaTeX.stable-keys.json'
  Then A library export using 'Better BibLaTeX' should match 'export/Better BibLaTeX.stable-keys.2.bib'

@81
Scenario: Journal abbreviations exported in bibtex (81)
  When I import 'export/Journal abbreviations exported in bibtex (81).json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[authors2][year][journal:nopunct]'
   And I set preference extensions.zotero.translators.better-bibtex.auto-abbrev to true
   And I set preference extensions.zotero.translators.better-bibtex.auto-abbrev.style to 'http://www.zotero.org/styles/cell'
   And I set export option useJournalAbbreviation to true
  Then A library export using 'Better BibTeX' should match 'export/Journal abbreviations exported in bibtex (81).bib'

@85
Scenario: Square brackets in Publication field (85)
  When I import 'export/Square brackets in Publication field (85).json'
  Then A library export using 'Better BibTeX' should match 'export/Square brackets in Publication field (85).bib'

@86
Scenario: Include first name initial(s) in cite key generation pattern (86)
  When I import 'export/Include first name initial(s) in cite key generation pattern (86).json'
   And I set preference extensions.zotero.translators.better-bibtex.citeKeyFormat to '[auth+initials][year]'
  Then A library export using 'Better BibTeX' should match 'export/Include first name initial(s) in cite key generation pattern (86).bib'
