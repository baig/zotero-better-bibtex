---
layout: default
title: Citation Keys
---
BBT offers you control over your citation keys.

# Set your own, fixed citation keys

You can fix the citation key for a reference by adding the text "bibtex: [your citekey]" (sans quotes) anywhere in the
"extra" field of the reference, or by using biblatexcitekey[my_key]. You can generate a fixed citation key by
selecting references, right-clicking, and selecting "Generate BibTeX key".

# Drag and drop/hotkey citations

You can drag and drop citations into your LaTeX editor, and it will add a proper \cite{citekey}. The actual command is
configurable by setting the config option in the BBT preferences (see below). Do not include the leading backslash. This
feature requires a one-time setup: go to zotero preferences, tab Export, under Default Output Format, select "LaTeX Citation".

If you want even more convenience (and you're on Windows), install [AutoHotKey](http://www.autohotkey.com/), modify the
[Zotero sample macro](https://raw.github.com/ZotPlus/zotero-better-bibtex/master/FastCite.ahk), and add it to your AutoHotKey.ahk. If you use this macro unmodified, when you select one or more entries in Zotero, it will copy them, bring TeXMaker to the forground, and paste your citation at the cursor. Caution: this macro does *not* check that you are in Zotero when you activate it, nor that TeXMaker is actually running.

# Find duplicate keys through integration with [Report Customizer](https://github.com/ZotPlus/zotero-report-customizer)

The plugin will generate BibTeX comments to show whether a key conflicts and with which entry. BBT integrates with
[Zotero: Report Customizer](https://github.com/ZotPlus/zotero-report-customizer) to display the BibTeX key plus any
conflicts between them in the zotero report.

# Configurable citekey generator

BBT also implements a new citekey generator for those entries that don't have one set explicitly; the formatter
follows the [JabRef key formatting syntax](http://jabref.sourceforge.net/help/LabelPatterns.php), with a twist; you can
set multiple patterns separated by a vertical bar, of which the first will be applied that yields a non-empty string. If
all return a empty string, a random key will be generated. Note that in addition to the 'special' fields listed JabRef
also allows all 'native' fields as key values; the plugin does the same but allows for *Zotero* native fields (case
sensitive!) not Bib(La)TeX native fields. The possible fields are:

|                      |                      |                      |                      |
| -------------------- | -------------------- | -------------------- | -------------------- |
| AbstractNote         | AccessDate           | ApplicationNumber    | Archive              |
| ArchiveLocation      | ArtworkMedium        | ArtworkSize          | Assignee             |
| Attachments          | AudioFileType        | AudioRecordingFormat | BillNumber           |
| BlogTitle            | BookTitle            | CallNumber           | CaseName             |
| Code                 | CodeNumber           | CodePages            | CodeVolume           |
| Committee            | Company              | ConferenceName       | Country              |
| Court                | Date                 | DateAdded            | DateDecided          |
| DateEnacted          | DateModified         | DictionaryTitle      | Distributor          |
| DocketNumber         | DocumentNumber       | DOI                  | Edition              |
| EncyclopediaTitle    | EpisodeNumber        | Extra                | FilingDate           |
| FirstPage            | ForumTitle           | Genre                | History              |
| Institution          | InterviewMedium      | ISBN                 | ISSN                 |
| Issue                | IssueDate            | IssuingAuthority     | ItemType             |
| JournalAbbreviation  | Label                | Language             | LegalStatus          |
| LegislativeBody      | LetterType           | LibraryCatalog       | ManuscriptType       |
| MapType              | Medium               | MeetingName          | Month                |
| NameOfAct            | Network              | Notes                | Number               |
| NumberOfVolumes      | NumPages             | Pages                | PatentNumber         |
| Place                | PostType             | PresentationType     | PriorityNumbers      |
| ProceedingsTitle     | ProgrammingLanguage  | ProgramTitle         | PublicationTitle     |
| PublicLawNumber      | Publisher            | References           | Related              |
| Reporter             | ReporterVolume       | ReportNumber         | ReportType           |
| Rights               | RunningTime          | Scale                | Section              |
| Series               | SeriesNumber         | SeriesTeXt           | SeriesTitle          |
| Session              | ShortTitle           | Source               | Studio               |
| Subject              | System               | Tags                 | ThesisType           |
| Title                | University           | Url                  | Version              |
| VideoRecordingFormat | Volume               | WebsiteTitle         | WebsiteType          |

## Advanced usage

BBT adds a few fields, flags and filter functions that JabRef (perhaps wisely) doesn't. These are:

### Functions

- `journal`: returns the journal *abbreviation* (I know, counterintuitive, but best mimics JabRef). If you want the
  full journal title, use `PublicationTitle`. `journal` returns the same as `JournalAbbreviation`, if set; if not
  set, and 'automatic journal abbreviation' is enabled in the BBT settings, will use the same abbreviation filter Zotero
  uses in the wordprocessor integration. You might want to use the `nopunct` filter (see below) on this.

### Flags

- `+initials` adds initials to any author name function. Specify using e.g. [auth+initials]

### Filters

- `nopunct`: removes punctuation
- `condense`: this replaces spaces in the value passed in. You can specify what to replace it with by adding it as a
  parameter, e.g `condense,_` will replace spaces with underscores. **Parameters should not contain spaces** unless you
  want the spaces in the value passed in to be replaced with those spaces in the parameter
- `skipwords`: filters out common words like 'of', 'the', ...
- `select`: selects words from the value passed in. The format is `select,start,number` (1-based), so `select,1,4`
  would select the first four words. It is important to note that `select' works only on values that have the words
  separated by whitespace, so the caveat below applies.
- `ascii`: removes all non-ascii characters
- `fold`: tries to replace diacritics with ascii look-alikes.
- `capitalize`: uppercases the first letter of each word

*Usage note*: the functions `skipwords`, `capitalize` and `select` rely on whitespaces for word handling. The JabRef functions strip
whitespace and thereby make these filter functions sort of useless. You will in general want to use the fields from the
table above, which give you the values from Zotero without any changes.

Example: mimicking zotero's original key generation, but replacing underscores with points (e.g. because LaTeX may choke
on underscores):

Given authors and titles

- Mercier (2013) The function of reasoning [...]
- de Groot & van Hell (2005) Handbook of Bilingualism [...]

`[author].[year].[Title:skipwords:select,1,1]` results in

- "Mercier.2013.function" and
- "deGroot.2005.Handbook"

Note that when the word from the `Title` field that ends up at the beginning after the `skipwords` treatment is a
lowercase word, it remains just that. You can change that with the `capitalize` function if so desired.

# Generation of stable keys, and syncing

Better BibTeX versions after 0.6.8 generate stable citation keys across your entire library. These stable keys come in
two flavors:

1. 'soft' keys, which auto-update whenever the relevant data from the reference does, and
2. 'pinned' or 'fixed' keys, which don't.

The pinned keys show up in the 'extra' field of your references, and sync across libraries. You cannot see the soft keys
(yet; being worked on), and the soft keys **do not sync** (yet; being worked on), but they're present in a separate
database so partial exports will know to generate keys not already in use (even if that is a 'soft' use), and so these
soft keys will reliably survive restarts of Zotero.

Quite a bit of trickery is involved in generating these stable keys, and some of this trickery could cause an undue burden
on the Zotero sync infrastructure. To prevent such strain on the Zotero sync servers, the following restrictions are in
place:

* By default, BBT only generates soft keys. You can generate a pinned key by right-clicking the reference and choosing
  'Generate BibTeX key'. You can clear this key either by editing the extra field, or right-clicking the reference and
  selecting 'clear BibTeX key'.
* If you want to make sure all your exported BibTeX files have pinned keys (very useful if you have a shared library, or
  you work from multiple workstations), go into the BBT preferences and select 'on export'. This option will be greyed out
  unless you have Zotero sync off, or, if enabled, have set it to auto-sync. Each pinned key change (or clearing of a
  pinned key) means a change to the reference, and that means the item will be synced if you have that set up. Massive
  amounts of key changes (which can easily happen if you have on-export and you export your full library) could
  overwhelm the Zotero sync service if presented in sudden bulk; automatic syncing ameliorates that problem. I'm working
  on a change so you can make this a per-library setting, and a change that syncs citekeys outside the Zotero servers.
* If you always want pinned keys, go into the BBT preferences and select 'on change'.

I am terribly sorry having to do this, but not doing this would risk sync being permanently impossible, as the Zotero
server will kick you out if a sync takes too long.
