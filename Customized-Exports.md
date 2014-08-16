The Better BibTeX configuration pane can be found under the regular Zotero preferences pane, tab 'Better Bib(La)TeX'.
Through the configuration pane of BBT you can customize the BibTeX file that will be exported:

* **Unicode conversion**: the default is to retain unicode characters on export for BibLaTeX, and to convert to LaTeX
  commands (where possible) for BibTeX. You can specify whether you want to retain this default, or whether you want BBT
  to always export translating to LaTeX commands, or never to do this translation.
* **Recursive collection export**: when exporting a collection, recursive export will include all child collections.
  Note that this also sets Zotero to display collection contents recursively.
* **Omit fields from export**: Should you so wish, you can prevent fields of your choosing from being exported. In the
  configuration screen, add a comma-separated list of BibTeX fields you do not want to see in your export. The fields
  are case-sensitive, separated by a comma *only*, no spaces.
* **[[Configurable citekey generator|Citation-Keys]]**
* **Pull export**: You can fetch your library as part of your build, using curl (for example by using the included
  zoterobib.yaml arara rule), or with a BiblaTeX remote statement like
  \addbibresource[location=remote]{http://localhost:23119/better-bibtex/collection?/0/8CV58ZVD.biblatex}.  For Zotero
  standalone this is enabled by default; for Zotero embedded, this enables the embedded webserver.

BBT http export uses the general Zotero HTTP facility; please note that disabling this will disable ALL http
facilities in zotero -- including the non-Firefox plugins provided by Zotero.

# Add your own BibLaTeX fields

You can add any field you like by using something like biblatexdata[origdate=1856;origtitle=An Old Title].  You can fix
the citation key for a reference by adding the text "bibtex: [your citekey]" (sans quotes) anywhere in the "extra" field
of the reference.
