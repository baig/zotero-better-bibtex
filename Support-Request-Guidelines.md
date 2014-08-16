#  Support Request Guidelines

Before all else, ***thank you for taking the time for submitting an issue***, and I'm sorry that I've probably
interrupted your flow.

## Known problems

Before submitting an issue, please make sure this isn't a known problem. Known problems are either already on my radar,
or there are problems preventing me from implementing a fix.

* **You see the BBT translator listed twice**. If you see a duplicate translator for Better BibLaTeX, go to
  "preferences/advanced/files", reset translators and restart.
* **Odd characters after import**. Zotero doesn't seem to handle importing of non-utf8 files particularly gracefully. If
  you're coming from JabRef, please verify in JabRef using file-database properties that your bibliography is saved in utf-8
  format before importing.

## Submitting an issue - please read carefully

If you have any questions on the use of the plugin, please do not hesitate to file a GitHub issue to ask for help. If
you're reporting a bug in the plugin, please take a moment to glance through the Support Request Guidelines; it will
make sure I get your problem fixed as quick as possible. Clear bug reports commonly have time-to-fix of 10 minutes. The
guidelines are very detailed, perhaps to the point of being off-putting, but please do not fret; these guidelines
simply express my ideal bug submission. I of course prefer very clearly documented issue reports over fuzzy ones, but I
prefer fuzzy ones over missed ones.

My time is extremely limited for a number of very great reasons (you shall have to trust me on this). Because of this, I
cannot accept bug reports or support requests on anything but the latest version, currently at **0.6.10**.

If you submit an issue report,

* **Please make *sure* you are on the latest version**, currently **0.6.10**. Auto-update will usually take care of it.
* **Please include *specifics* of what doesn't work**. I use this plugin every day myself, so "it doesn't work" is trivially
  false. Please tell me what you expected and what you see happening, and the relevant difference between them.
* **Please don't file a jumble of problems in one issue**. Posting a slew of separate issues is much preferred, as I can
  more easily tackle them one by one.
* **Do not hijack existing issues**. You can chime in on existing issues if you're close to certain it is the same problem,
  otherwise, open a new issue. I rather have duplicate issues than issues I cannot close because they are in fact two or
  more issues.
* **If your problem pertains to *importing BibTeX files*,** you ***must*** put up a sample for me to reproduce the issue with.
  *Do not* paste the sample in the issue, as the issue tracker will format it into oblivion. Instead, choose one of
  these options:
  * Post an URL in the issue where I can download your sample, or
  * Put the sample in a [gist](https://gist.github.com/) and post the URL of the gist into the issue, or 
  * upload your files to [dbinbox](http://dbinbox.com/allthatisthecase) -- please use descriptive file names (at least
    the issue number), as I can't see who uploaded what.
* **If your problem pertains to *exporting BibTeX files*,** you ***must*** put up a sample for me to reproduce the issue
  with, exported in `Zotero TestCase` format. For making the sample available to me: see 'import issues' in the
  point directly above.
* **If your problem pertains to BBT interfering with other plugins** (which wouldn't be the first time), and this interference
  has something to do with importing, you ***must*** include a sample file that triggers the issue. I know it may seem
  that "any file triggers it" -- I need a *specific* file that does so I know we're looking at the same problem.

