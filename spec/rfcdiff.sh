#!/bin/bash
#
# Synopsis:
#	Show changes between 2 internet-drafts using changebars or html
#	side-by-side diff.
#	
# Usage:
#	rfcdiff [options] file1 file2
#	
#	rfcdiff takes two RFCs or Internet-Drafts in text form as input, and
#	produces output which indicates the differences found in one of various
#	forms, controlled by the options listed below. In all cases, page
#	headers and page footers are stripped before looking for changes.
#	
#	--html		Produce side-by-side .html diff (default)
#	
#	--chbars	Produce changebar marked .txt output
#	
#	--diff		Produce a regular diff output
#	
#	--wdiff		Produce paged wdiff output
#	
#	--hwdiff	Produce html-wrapped coloured wdiff output
#	
#	--browse	Show html output in browser
#	
#	--keep		Don't delete temporary workfiles
#	
#	--version	Show version
#	
#	--help		Show this help
#	
#	--info "Synopsis|Usage|Copyright|Description|Log"
#			Show various info
#	
#	--width	N	Set a maximum width of N characters for the
#			display of each half of the old/new html diff
#	
#	--linenum	Show linenumbers for each line, not only at the
#			start of each change section
#	
#	--body		Strip document preamble (title, boilerplate and
#			table of contents) and postamble (Intellectual
#			Property Statement, Disclaimer etc)
#	
#	--nostrip	Don't strip headers and footers (or body)
#	
#	--ab-diff	Before/After diff, suitable for rfc-editor
#	--abdiff
#	
#	--stdout	Send output to stdout instead to a file
#	
#
# Copyright:
#	-----------------------------------------------------------------
#	
#	Copyright 2002 Henrik Levkowetz
#	
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#	
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#	
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#	-----------------------------------------------------------------
#
# Description:
#
#	The purpose of this program is to compare two versions of an
#	internet-draft, and as output produce a diff in one of several
#	formats:
#	
#		- side-by-side html diff
#		- paged wdiff output in a text terminal
#		- a text file with changebars in the left margin
#		- a simple unified diff output
#	
#	In all cases, internet-draft headers and footers are stripped before
#	generating the diff, to produce a cleaner diff.
#	
#	It is called as
#	
#		rfcdiff first-file second-file
#	
#	The latest version is available from
#		http://tools.ietf.org/tools/rfcdiff/
#
# Log:
#			
#	01 Jun 2006	v1.32 - changed 'para.' to 'paragraph' in abdiff.
#			Added new regexps for page headers in strip.		
#			
#	12 May 2006	v1.31 - Fixed a bug where the last diff in
#			--abdiff mode would not be output.  Tweaked the
#			regexp which recognizes section headers in
#			abdiff().
#			
#	05 May 2006	v1.30 - Changed -U<nnn> to -U <nnn> to work on Macs
#			
#	20 Dec 2005	v1.29 - Added --hwdiff switch, to give single-
#			columnt html output, as in Bill Fenner's htmlwdiff
#	
#	20 Dec 2005	v1.28 - Changed font-size units from pt to em.
#			Made white-space ignoring somewhat less aggressive.
#	
#	04 Aug 2005	v1.27 - Added -f option to some mv commands to
#			handle read-only input files.  Added statistics
#			output.
#			
#	29 Jul 2005	v1.26 - Removed spurious empty output line.
#			Added guard against files beginning with "-"
#			for mv.
#			
#	11 Jul 2005	v1.25 - Tweaked the regexps for --bodystrip and
#			recognition of wdiff version, both thanks to
#			Bruce Lilly.  Tweak to handle directory names
#			with whitespace, thanks to Thomas Morin.
#			
#	16 Jun 2005	v1.24 - changed to use uppercase "-U" option to
#			diff, for MacOS X compatibility. (Thanks to
#			Lars Eggert.)
#			
#	24 Jan 2005	v1.23 - Fixed a bug where html entity codes was
#			broken up by diff markup.
#			
#	06 Jan 2005	v1.22 - Tweaked a style setting	
#			
#	10 Dec 2004	v1.21 - Added anchor for each diff, in order	
#			for it to be possible to create URLs refering
#			to individual diffs.
#			
#	09 Dec 2004	v1.20 -	fixed the same bug again, a bit better
#			this time :-)
#			
#	06 Dec 2004	v1.19 - fixed a bug introduced in v1.18, where	
#			lines of diffs with linebreaks would not be
#			shown when using the --width option.
#			
#	02 Dec 2004	v1.18 - On some systems, awk is the original		
#			Aho, Weinberger, Kernighan awk. We need gawk
#			or at least nawk, so now we look for those.
#			If not found, we try to run with awk anyway,
#			but that will probably not work...
#			Nawk won't accept continuation lines inside
#			strings, so all multiline strings broken up.
#			Also changed the linebreaking and page 
#			formatting somewhat.
#			
#	16 Nov 2004	v1.17 - Minor bugfix for cygwin - "cd -" was
#			reported not to work; working around that.
#	
#	10 Nov 2004	v1.16 - Minor bugfix - properly removing temp
#			outfile when using --stdout
#	
#	20 Sep 2004	v1.15 - Improved the page header/footer
#			stripping to handle more cases of paragraphs
#			split over page breaks, and a greater variety
#			of whitespace in the page break.  Added some
#			diagnostic information to the generated html
#			diff, in comments.  Added --stdout option.
#	
#	04 Sep 2004	v1.14 - Cleaned up html in a few places so it's
#			now clean again.
#	
#	11 Jun 2004	v1.13 - Tweaked the regexp to match section
#			numbers slightly.  Added -wd option to diff
#			also for the ab (rfc-editor before/after) diff.
#	
#	07 Jun 2004	v1.12 - Added --abdiff option, to produce
#			OLD/NEW output suitable for the RFC-Editor
#	
#	03 Apr 2004	v1.11 - Added --nostrip option.  Fixed a bug
#			where a diff on the very first line would not
#			be shown.
#	
#	17 Mar 2004	v1.10 - Minor tweaks to handle malformed drafts
#			better.  Added firefox to browser list.
#	
#	23 Feb 2004	v1.09 - Started work on an Old/New diff mode,
#			suitable for diff summaries to mailing lists,
#			issue trackers, reviewers & rfc-editor.  Not
#			complete yet.
#	
#	22 Feb 2004	v1.08 - Added --body option to exclude
#			boilerplate and table of contents changes.
#	
#	21 Feb 2004	v1.07 - Added diagnostic message when wdiff not
#			found or wdiff version not recognised
#	
#	01 Feb 2004	v1.06 - Added --linenum option to provide line numbers
#			on each line. Simplified linebreaking markup.
#			Some mild refactoring.
#	
#	29 Jan 2004	v1.05 - Now providing page and line numbers for
#			both old and new document versions at the start
#			of each change section.
#			The line-breaking code is still buggy...
#	
#	25 Jan 2004	v1.04 - Added line numbers for the case when no page
#			numbers are available
#	
#	24 Jan 2004	v1.03 - Fixed a line coloring bug introduced in v1.02
#	
#	22 Jan 2004	v1.02 - Added line-breaking functionality through
#			the --width option.  Experimental -- may be
#			buggy.
#	
#	17 Dec 2003	v1.01 - Fixed a bug where diffs with no text
#			occurring after the last change would be shown
#			without the last change. Added some debug
#			functionality to be able to track this one down.
#	
#	14 Dec 2003	v1.00 - Bumped version number to 1.00
#	
#	 6 Dec 2003	v0.42 - Added html diff output for the
#			identical files case.
#	
#	 5 Dec 2003	v0.41 - Added --info option
#	
#	25 Nov 2003	v0.40 - Added the use of wget (if available) to
#			pull down remote source files (http: or ftp:)
#	
#	20 Nov 2003	v0.39 - Added 'End of changes' line at the end
#			of html diff. Added a test on wdiff producing
#			reasonable output with --version option, to
#			avoid old broken wdiff versions.
#	
#	20 Nov 2003	v0.38 - Added --keep option, to keep temporary
#			files.
#	
#	20 Nov 2003	v0.37 - Added --nowdiff option, to make --html
#			*not* use wdiff even if it is available.
#	
#	20 Nov 2003	v0.36 - Added --browse option, to optionally
#			start a browser to show html diff output.
#			Refined how we look for a wdiff binary.
#	
#	18 Nov 2003	v0.35 - minor tweaks to header/footer stripping
#			regexps. Changed color marking of differences.
#			Other minor tweaks and comment updates.
#	
#	16 Nov 2003	v0.34 - removed listing of environment when no
#			files were given on the command line. Added
#			help text. Added the possibility of using wdiff to get
#			the changed words in a change block highlighted.
#	
#	23 Oct 2003	v0.33 - using different dir's for the stripped
#			files, to be able to diff files with the same
#			basename.
#	
#	 2 Sep 2003	v0.32 - fixed spurious error message when using
#			--wdiff option
#	
#	 1 Sep 2003	v0.31 - not touching the original files, using
#			temporary directory for work files.
#	
#	29 Aug 2003	v0.30 - Removed explicit font size for output.
#			Changed regexp for page start (now accepting space
#			in "Internet Draft".
#	
#	16 Apr 2003	v0.29 - added wdiff support
#	
#	 6 Mar 2003	v0.28 - added --html, --chbars and --diff switches
#	
#	 3 Mar 2003	v0.27 - Changed page regexp to accept lowercase
#				'p'.
#	
#	 2 Feb 2003	Expanded to provide side-by-side html diff, in
#			addition to changebars in .txt files
#
# End:
#

export version="1.33"
export progdate="(20 Sep 2006)"
export prelines="10"
export basename=$(basename $0)
export workdir="/tmp/$basename-$$"
export pagecache1="$workdir/pagecache1"
export pagecache2="$workdir/pagecache2"

# ----------------------------------------------------------------------
# Utility to find an executable
# ----------------------------------------------------------------------
lookfor() {
    for b in "$@"; do
	found=$(which "$b" 2>/dev/null)
	if [ -n "$found" ]; then
	    if [ -x "$found" ]; then
		echo "$found"
		return
	    fi
	fi
    done
}

AWK=$(lookfor gawk nawk awk)

# ----------------------------------------------------------------------
# Strip headers footers and formfeeds from infile to stdout
# ----------------------------------------------------------------------
strip() {
  $AWK '
				{ gsub(/\r/, ""); }
				{ gsub(/[ \t]+$/, ""); }

/\[?[Pp]age [0-9ivx]+\]?[ \t\f]*$/{ 
				  match($0, /\[?[Pp]age [0-9ivx]+\]?/);
				  print substr($0, RSTART+6, RLENGTH-7), outline > ENVIRON["pagecache" ENVIRON["which"]]
				  next;
				}
/^[ \t]*\f/			{ newpage=1; next; }
/^ *Internet.Draft.+[12][0-9][0-9][0-9] *$/	{ newpage=1; next; }
/^ *INTERNET.DRAFT.+[12][0-9][0-9][0-9] *$/	{ newpage=1; next; }
/^ *Draft.+[12][0-9][0-9][0-9] *$/		{ newpage=1; next; }
/^RFC.+[0-9]+$/			{ newpage=1; next; }
/^draft-[-a-z0-9_.]+.*[0-9][0-9][0-9][0-9]$/ { newpage=1; next; }
/(Jan|Feb|Mar|March|Apr|April|May|Jun|June|Jul|July|Aug|Sep|Oct|Nov|Dec) (19[89][0-9]|20[0-9][0-9]) *$/ && pagelength < 3  { newpage=1; next; }
newpage && $0 ~ /^ *draft-[-a-z0-9_.]+ *$/ { newpage=1; next; }
/^[^ \t]/			{ sentence=1; }
/[^ \t]/			{
				   if (newpage) {
				      if (sentence) {
					 outline++; print "";
				      }
				   } else {
				      if (haveblank) {
					  outline++; print "";
				      }
				   }
				   haveblank=0;
				   sentence=0;
				   newpage=0;
				}
/[.:][ \t]*$/			{ sentence=1; }
/^[ \t]*$/			{ haveblank=1; next; }
				{ outline++; print; }
' $1
}


# ----------------------------------------------------------------------
# Strip preamble (title, boilerplate and table of contents) and
# postamble (Intellectual Property Statement, Disclaimer etc)
# ----------------------------------------------------------------------
bodystrip() {
    $AWK '
    /^[ \t]*Acknowledgment/		{ inbody = 0; }
    /^(Full )*Copyright Statement$/	{ inbody = 0; }
    /^[ \t]*Disclaimer of Validid/	{ inbody = 0; }
    /^[ \t]*Intellectual Property/	{ inbody = 0; }
    /^Abstract$/			{ inbody = 0; }
    /^Table of Contents$/		{ inbody = 0; }
    /^1.[ \t]*Introduction$/	{ inbody = 1; }

    inbody			{ print; }
    ' $1
}


# ----------------------------------------------------------------------
# From two words, find common prefix and differing part, join descriptively
# ----------------------------------------------------------------------
worddiff() {
   $AWK '
BEGIN	{
		w1 = ARGV[1]
		w2 = ARGV[2]
		format = ARGV[3]

		do {
			if (substr(w1,1,1) == substr(w2,1,1)) {
				w1 = substr(w1,2)
				w2 = substr(w2,2)
			} else {
				break;
			}
			prefixlen++;
		} while (length(w1) && length(w2))

		prefix = substr(ARGV[1],1,prefixlen);

		do {
			l1 = length(w1);
			l2 = length(w2);
			if (substr(w1,l1,1) == substr(w2,l2,1)) {
				w1 = substr(w1,1,l1-1)
				w2 = substr(w2,1,l2-1)
			} else {
				break;
			}
		} while (l1 && l2)

		suffix = substr(ARGV[1], prefixlen+length(w1))

		printf format, prefix, w1, w2, suffix;
	}
' $1 $2 $3
}

# ----------------------------------------------------------------------
# Generate a html page with side-by-side diff from a unified diff
# ----------------------------------------------------------------------
htmldiff() {
   $AWK '
BEGIN	{
           FS = "[ \t,]";

	   # Read pagecache1
	   maxpage[1] = 1
	   pageend[1,0] = 2;
	   while ( getline < ENVIRON["pagecache1"] > 0) {
	      pageend[1,$1] = $2;
	      if ($1+0 > maxpage[1]) maxpage[1] = $1+0;
	   }

	   # Read pagecache2
	   maxpage[2] = 1
	   pageend[2,0] = 2;
	   while ( getline < ENVIRON["pagecache2"] > 0) {
	      pageend[2,$1] = $2;
	      if ($1+0 > maxpage[2]) maxpage[2] = $1+0;
	   }

	   wdiff = ENVIRON["wdiffbin"]
	   base1 = ENVIRON["base1"]
	   base2 = ENVIRON["base2"]
	   optwidth = ENVIRON["optwidth"]
	   optnums =  ENVIRON["optnums"]
	   cmdline = ENVIRON["cmdline"]
	   gsub("--", "- -", cmdline)
	   ENVIRON["cmdline"] = cmdline
	   header(base1, base2)

	   difflines1 = 0
	   difflines2 = 0
	}

function header(file1, file2) {
   printf "" \
"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"> \n" \
"<!-- Generated by rfcdiff %s: rfcdiff %s --> \n" \
"<!-- <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional\" > -->\n" \
"<!-- System: %s --> \n" \
"<!-- Using awk: %s: %s --> \n" \
"<!-- Using diff: %s: %s --> \n" \
"<!-- Using wdiff: %s: %s --> \n" \
"<html> \n" \
"<head> \n" \
"  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" /> \n" \
"  <meta http-equiv=\"Content-Style-Type\" content=\"text/css\" /> \n" \
"  <title>Diff: %s - %s</title> \n" \
"  <style type=\"text/css\"> \n" \
"    body    { margin: 0.4ex; margin-right: auto; } \n" \
"    tr      { } \n" \
"    td      { white-space: pre; font-family: monospace; vertical-align: top; font-size: 0.86em;} \n" \
"    th      { font-size: 0.86em; } \n" \
"    .small  { font-size: 0.6em; font-style: italic; font-family: Verdana, Helvetica, sans-serif; } \n" \
"    .left   { background-color: #EEE; } \n" \
"    .right  { background-color: #FFF; } \n" \
"    .diff   { background-color: #CCF; } \n" \
"    .lblock { background-color: #BFB; } \n" \
"    .rblock { background-color: #FF8; } \n" \
"    .insert { background-color: #8FF; } \n" \
"    .delete { background-color: #ACF; } \n" \
"    .void   { background-color: #FFB; } \n" \
"    .cont   { background-color: #EEE; } \n" \
"    .linebr { background-color: #AAA; } \n" \
"    .lineno { color: red; background-color: #FFF; font-size: 0.7em; text-align: right; padding: 0 2px; } \n" \
"    .elipsis{ background-color: #AAA; } \n" \
"    .left .cont { background-color: #DDD; } \n" \
"    .right .cont { background-color: #EEE; } \n" \
"    .lblock .cont { background-color: #9D9; } \n" \
"    .rblock .cont { background-color: #DD6; } \n" \
"    .insert .cont { background-color: #0DD; } \n" \
"    .delete .cont { background-color: #8AD; } \n" \
"    .stats, .stats td, .stats th { background-color: #EEE; padding: 2px 0; } \n" \
"  </style> \n" \
"</head> \n" \
"<body > \n" \
"  <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"> \n" \
"  <tr bgcolor=\"orange\"><th></th><th>&nbsp;%s&nbsp;</th><th> </th><th>&nbsp;%s&nbsp;</th><th></th></tr> \n" \
"", ENVIRON["version"], ENVIRON["cmdline"], ENVIRON["uname"], ENVIRON["awkbin"], ENVIRON["awkver"], ENVIRON["diffbin"], ENVIRON["diffver"], ENVIRON["wdiffbin"], ENVIRON["wdiffver"], file1, file2, file1, file2;
}

function worddiff(w1, w2) {
   prefixlen = 0;
   word1 = w1;
   do {
      if (substr(w1,1,1) == substr(w2,1,1)) {
	 w1 = substr(w1,2);
	 w2 = substr(w2,2);
      } else {
	 break;
      }
      prefixlen++;
   } while (length(w1) && length(w2));

   prefix = substr(word1,1,prefixlen);

   do {
      l1 = length(w1);
      l2 = length(w2);
      if (substr(w1,l1,1) == substr(w2,l2,1)) {
	 w1 = substr(w1,1,l1-1);
	 w2 = substr(w2,1,l2-1);
      } else {
	 break;
      }
   } while (l1 && l2);

   suffix = substr(word1, prefixlen+length(w1)+1);

   wordpart[0] = prefix;
   wordpart[1] = w1;
   wordpart[2] = w2;
   wordpart[3] = suffix;
}

function numdisplay(which, line) {
    if (optnums && (line != prevline[which])) {
	prevline[which] = line;
	return line-1;
    }
    return "";
}

function fixesc(line) {
#    Making this a no-op for now -- the change in line-breaking
#    "<br><span...>" => "\n" should make this less necessary.
#    line = gensub(/&(<[^>]*>)/, "\\1\\&", "g", line);

#   We still have to handle cases where we have a broken up "&lt;" / "&gt;"
    gsub(/&l<\/span>t;/, "\\&lt;</span>", line);
    gsub(/&g<\/span>t;/, "\\&gt;</span>", line);
    gsub(/&<span class="delete">l<\/span>t;/, "<span class=\"delete\">\\&lt;</span>", line);
    gsub(/&<span class="delete">g<\/span>t;/, "<span class=\"delete\">\\&gt;</span>", line);
    gsub(/&<span class="insert">l<\/span>t;/, "<span class=\"insert\">\\&lt;</span>", line);
    gsub(/&<span class="insert">g<\/span>t;/, "<span class=\"insert\">\\&gt;</span>", line);

    return line;
}

function chunkdiff(chunk) {
   if (difflines1 == 0 && difflines2 == 0) return;

   chunkfile1= sprintf("1/chunk%04d", chunk);
   chunkfile2= sprintf("2/chunk%04d", chunk);
   printf "" > chunkfile1;
   printf "" > chunkfile2;
   for (l = 0; l < difflines1; l++) { print stack1[l] >> chunkfile1; }
   for (l = 0; l < difflines2; l++) { print stack2[l] >> chunkfile2; }
   close(chunkfile1);
   close(chunkfile2);

   cmd1 = sprintf("%s -n -2 -w \"<span class=\\\"delete\\\">\"  -x \"</span>\" %s %s", wdiff, chunkfile1, chunkfile2);
   cmd2 = sprintf("%s -n -1 -y \"<span class=\\\"insert\\\">\"  -z \"</span>\" %s %s", wdiff, chunkfile1, chunkfile2);

   l=0; while (cmd1 | getline > 0) { stack1[l] = fixesc($0); l++; }
   difflines1 = l;
   l=0; while (cmd2 | getline > 0) { stack2[l] = fixesc($0); l++; }
   difflines2 = l;

   close(cmd1);
   close(cmd2);
}

function flush() {
   if (difflines1 || difflines2) {
      difftag++;
      multiline = (difflines1 > 1) || (difflines2 > 1);
      if (multiline && (wdiff != "")) chunkdiff(difftag);

      printf "      <tr><td><a name=\"diff%04d\" /></td></tr>\n", difftag;
      for (l = 0; l < difflines1 || l < difflines2; l++) {
	 if (l in stack1) {
	    line1 = stack1[l];
	    delete stack1[l];
	    linenum1++
	    if (line1 == "")
	       if (optwidth > 0) {
		   line1 = substr("                                                                                                                                                                ",0,optwidth);
	       } else {
		   line1 = "                                                                         ";
	       }
	 } else {
	    line1 = "";
	 }
	 if (l in stack2) {
	    line2 = stack2[l];
	    delete stack2[l];
	    linenum2++;
	    if (line2 == "")
	       if (optwidth > 0) {
		   line2 = substr("                                                                                                                                                                ",0,optwidth);
	       } else {
		   line2 = "                                                                         ";
	       }
	 } else {
	    line2 = "";
	 }

	 if (!multiline || (wdiff == "")) {
	    worddiff(line1, line2);
	    line1 = fixesc(sprintf("%s<span class=\"delete\">%s</span>%s", wordpart[0], wordpart[1], wordpart[3]));
	    line2 = fixesc(sprintf("%s<span class=\"insert\">%s</span>%s", wordpart[0], wordpart[2], wordpart[3]));
	    # Clean up; remove empty spans
	    sub(/<span class="delete"><\/span>/,"", line1);
	    sub(/<span class="insert"><\/span>/,"", line2);
	 }
	 left  = sprintf("<td class=\"lineno\" valign=\"top\">%s</td><td class=\"lblock\">%s</td>", numdisplay(1, linenum1), line1);
	 right = sprintf("<td class=\"rblock\">%s</td><td class=\"lineno\" valign=\"top\">%s</td>", line2, numdisplay(2, linenum2));
	 printf "      <tr>%s<td> </td>%s</tr>\n", left, right;
      }
   }
}

function getpage(which, line) {
    line = line + ENVIRON["prelines"];
    page = "?";
    for (p=1; p <= maxpage[which]; p++) {
	if (pageend[which,p] == 0) continue;
	if (line <= pageend[which,p]) {
	    page = p;
	    break;
	}
    }
    return page;
}

function getpageline(which, line, page) {
    if (page == "?") {
	return line + ENVIRON["prelines"];
    } else {
	if (pageend[which,page-1]+0 != 0) {
	    return line + ENVIRON["prelines"] - pageend[which,page-1] + 3; # numbers of header lines stripped
	} else {
	    return "?";
	}
    }
}

function htmlesc(line) {
    gsub("&", "\\&amp;", line);
    gsub("<", "\\&lt;", line);
    gsub(">", "\\&gt;", line);
    return line;
}

function expandtabs(line) {
    spaces = "        ";
    while (pos = index(line, "\t")) {
	sub("\t", substr(spaces, 0, (8-pos%8)), line);
    }
    return line;
}

function maybebreakline(line,    width) {
    width = optwidth;
    new = "";
    if (width > 0) {
	line = expandtabs(line);
	while (length(line) > width) {
	    new = new htmlesc(substr(line, 1, width)) "\n";
	    line = substr(line, width+1);
	}
    }
    line = new htmlesc(line) ;
    return line;
}

/^@@/	{
	   linenum1 = 0 - $2;
	   linenum2 = 0 + $4;
	   diffnum ++;
	   if (linenum1 > 1) {
	      printf "      <tr><td class=\"lineno\"></td><td class=\"left\"></td><td> </td><td class=\"right\"></td><td class=\"lineno\"></td></tr>\n";
	      page1 = getpage(1,linenum1);
	      page2 = getpage(2,linenum2);
	      if (page1 == "?") {
		 posinfo1 = sprintf("<a name=\"part-l%s\" /><small>skipping to change at</small><em> line %s</em>", diffnum, getpageline(1, linenum1, page1));
	      } else {
		 posinfo1 = sprintf("<a name=\"part-l%s\" /><small>skipping to change at</small><em> page %s, line %s</em>", diffnum, page1, getpageline(1, linenum1, page1));
	      }

	      if (page2 == "?") {
		 posinfo2 = sprintf("<a name=\"part-r%s\" /><small>skipping to change at</small><em> line %s</em>", diffnum, getpageline(2, linenum2, page2));
	      } else {
		 posinfo2 = sprintf("<a name=\"part-r%s\" /><small>skipping to change at</small><em> page %s, line %s</em>", diffnum, page2, getpageline(2, linenum2, page2));
	      }

	      printf "      <tr bgcolor=\"gray\" ><td></td><th>%s</th><th> </th><th>%s</th><td></td></tr>\n", posinfo1, posinfo2;
	   }
	}

/^---/	{  next; }
/^[+][+][+]/	{  next; }
/^[ ]/	{
	   line = substr($0, 2);
	   line = maybebreakline(line);

	   flush();
	   linenum1++;
	   linenum2++;
	   printf "      <tr><td class=\"lineno\" valign=\"top\">%s</td><td class=\"left\">%s</td><td> </td>", numdisplay(1, linenum1), line;
	   printf "<td class=\"right\">%s</td><td class=\"lineno\" valign=\"top\">%s</td></tr>\n", line, numdisplay(2, linenum2);
	   diffcount1 += difflines1
	   difflines1 = 0
	   diffcount2 += difflines2
	   difflines2 = 0
	}
/^-/	{
	   line = substr($0, 2);
	   line = maybebreakline(line);

	   stack1[difflines1] = line;
	   difflines1++;
	}
/^[+]/	{
	   line = substr($0, 2);
	   line = maybebreakline(line);

	   stack2[difflines2] = line;
	   difflines2++;
	}

END	{
	   flush();
	   printf("\n" \
"     <tr><td></td><td class=\"left\"></td><td> </td><td class=\"right\"></td><td></td></tr>\n" \
"     <tr bgcolor=\"gray\"><th colspan=\"5\" align=\"center\"><a name=\"end\">&nbsp;%s. %s change blocks.&nbsp;</a></th></tr>\n" \
"     <tr class=\"stats\"><td></td><th><i>%s lines changed or deleted</i></th><th><i> </i></th><th><i>%s lines changed or added</i></th><td></td></tr>\n" \
"     <tr><td colspan=\"5\" align=\"center\" class=\"small\"><br/>This html diff was produced by rfcdiff %s. The latest version is available from <a href=\"http://www.tools.ietf.org/tools/rfcdiff/\" >http://tools.ietf.org/tools/rfcdiff/</a> </td></tr>\n" \
"   </table>\n" \
"   </body>\n" \
"   </html>\n", diffnum?"End of changes":"No changes", difftag, diffcount1, diffcount2, ENVIRON["version"]);
	}
' $1
}

# ----------------------------------------------------------------------
# Generate before/after text output from a context diff
# ----------------------------------------------------------------------
abdiff() {
$AWK '
BEGIN	{
	   # Read pagecache1
	   maxpage[1] = 1
	   pageend[1,0] = 2;
	   while ( getline < ENVIRON["pagecache1"] > 0) {
	      pageend[1,$1] = $2;
	      if ($1+0 > maxpage[1]) maxpage[1] = $1+0;
	   }

	   # Read pagecache2
	   maxpage[2] = 1
	   pageend[2,0] = 2;
	   while ( getline < ENVIRON["pagecache2"] > 0) {
	      pageend[2,$1] = $2;
	      if ($1+0 > maxpage[2]) maxpage[2] = $1+0;
	   }

	   base1 = ENVIRON["base1"]
	   base2 = ENVIRON["base2"]

	   section = "INTRODUCTION";
	   para = 0;

	}
/^\+\+/ {
	   next;
	}
/^\-\-/ {
	   next;
	}
/^ Appendix ./	{
	   section = $1 " " $2;
	   para = 0;
	}
/^  ? ? ?[0-9]+(\.[0-9]+)*\.? /	{
	   section = "Section " $1;
	   para = 0;
	}
/^ ?$/	{
	   if (inpara) {
	      printf "\n%s, paragraph %s:\n", section, para;
	      print "OLD:\n"
	      print oldpara
	      print "NEW:\n"
	      print newpara
	   }
	   oldpara = "";
	   newpara = "";
	   para ++;
	   inpara = 0
	}
/^ ./	{
	   oldpara = oldpara $0 "\n"
	   newpara = newpara $0 "\n"
	}
/^\-/	{
	   sub(/^./, " ");
	   oldpara = oldpara $0 "\n"
	   inpara++;
	}
/^\+/	{
	   sub(/^./, " ");
	   newpara = newpara $0 "\n"
	   inpara++;
	}
END	{
	   if (inpara) {
	      printf "\n%s, paragraph %s:\n", section, para;
	      print "OLD:\n"
	      print oldpara
	      print "NEW:\n"
	      print newpara
	   }	
	}
'
}


# ----------------------------------------------------------------------
# Utility to extract keyword info
# ----------------------------------------------------------------------
extract() {
    $AWK -v keyword=$1 '
	BEGIN {
	    # print "Keyword", keyword;
	}
	/^# [A-Z]/ {
	    # print "New key", $2;
	    if ($2 == keyword ":" ) { output=1; } else { output=0; }
	    # print "Output", output;
	}
	/^#\t/	{
	    # print "Content", output, $0;
	    if ( output ) {
		sub(/^#/,"");
		print;
	    }
	}
	{
	    next;
	}

    ' $2
}
# ----------------------------------------------------------------------
# Utility to start a browser
# ----------------------------------------------------------------------

browse() {
    browser=$(lookfor firefox phoenix MozillaFirebird mozilla opera Netscape netscape dillo)

    if [ -z "$browser" ]; then
	echo "Couldn't find any browser, can't display $*."
	exit 1
    fi

    # make sure file name is absolute
    if [ ${1#/} == $1 ]; then
        # not absolute path, add pwd
	arg="file://$PWD/$1"
    else
	arg="file://$1"
    fi


    # see if a browser is running, act accordingly
    $browser -remote "ping()" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
	# use running instance
	#echo "$browser -raise -remote \"openurl($arg, new-tab)\""
	$browser -raise -remote "openurl($arg, new-tab)"
    else
	# error exit: no running instance
	echo "Starting web browser."
	#echo "$browser $arg >/dev/null 2>&1 &"
	$browser $arg >/dev/null 2>&1 &
    fi
}


# ----------------------------------------------------------------------
# Utility for error exit
# ----------------------------------------------------------------------
die() {
   echo $*;
   exit 1;
}

# ----------------------------------------------------------------------
# Process options
# ----------------------------------------------------------------------
opthtml=1; optdiff=0; optchbars=0; optwdiff=0; optshow=0; optnowdiff=0;
optkeep=0; optinfo=0; optwidth=0;  optnums=0;  optbody=0; optabdiff=0;
optstrip=1; opthwdiff=0;
optstdout=0;

export cmdline="$*"
while [ $# -gt 0 ]; do
   case "$1" in
      --html)   opthtml=1; optdiff=0; optchbars=0; optwdiff=0; opthwdiff=0; optabdiff=0;;
      --diff)   opthtml=0; optdiff=1; optchbars=0; optwdiff=0; opthwdiff=0; optabdiff=0;;
      --chbars) opthtml=0; optdiff=0; optchbars=1; optwdiff=0; opthwdiff=0; optabdiff=0;;
      --wdiff)  opthtml=0; optdiff=0; optchbars=0; optwdiff=1; opthwdiff=0; optabdiff=0;;
      --hwdiff) opthtml=0; optdiff=0; optchbars=0; optwdiff=0; opthwdiff=1; optabdiff=0;;
      --changes)opthtml=0; optdiff=0; optchbars=0; optwdiff=0; opthwdiff=0; optabdiff=1;;
      --abdiff)	opthtml=0; optdiff=0; optchbars=0; optwdiff=0; opthwdiff=0; optabdiff=1;;
      --ab-diff)opthtml=0; optdiff=0; optchbars=0; optwdiff=0; opthwdiff=0; optabdiff=1;;
      --rfc-editor-diff)opthtml=0; optdiff=0; optchbars=0; optwdiff=0; opthwdiff=0; optabdiff=1;;
      --version)echo -e "$basename\t$version\t$progdate"; exit 0;;
      --browse) optshow=1;;
      --nowdiff)optnowdiff=1;;
      --keep)	optkeep=1;;
      --info)	optinfo=1; keyword=$2; shift;;
      --help)	optinfo=1; keyword="Usage";;
      --width)	optwidth=$2; shift;;
      --linenum)optnums=1;;
      --body)	optbody=1;;
      --nostrip)optstrip=0; optbody=0;;
      --stdout) optstdout=1;;
      --)	shift; break;;

      -r) options="$options $1 $2"; rev=$2; shift;;
      -v) echo "$basename $version"; exit 0;;
      -*) echo "Unrecognized option: $1";
	  exit 1;;
      *)  files="$files $1";;
   esac
   shift
done
#echo $1 $2 $3

export optwidth
export optnums

# ----------------------------------------------------------------------
# Determine output file name. Maybe output usage and exit.
# ----------------------------------------------------------------------
#set -x

if [ $optinfo -gt 0 ]; then
   extract $keyword $0
   exit
fi
if [ "$files" ]; then
  set $files
fi
if [ $# -ge 2 ]; then
   if [ $1 = $2 ]; then
      echo "The files are the same file"
      exit
   fi
   export base1=$(basename $1)
   export base2=$(basename $2)
   outbase=$(worddiff $base2 $base1 "%s%s-from-%s")
else
   extract Usage $0
   exit 1
fi


# ----------------------------------------------------------------------
# create working directory.
# ----------------------------------------------------------------------
mkdir $workdir || die "$0: Error: Failed to create temporary directory '$workdir'."
mkdir $workdir/1 || die "$0: Error: Failed to create temporary directory '$workdir/1'."
mkdir $workdir/2 || die "$0: Error: Failed to create temporary directory '$workdir/2'."

# ----------------------------------------------------------------------
# If any of the files is an http or ftp URL we download it, else copy it
# ----------------------------------------------------------------------

wgetbin=$(lookfor wget)
dowgetarg1=0
dowgetarg2=0

if [ -n "$wgetbin" ]; then
   if [ ${1#http://} != $1 ]; then dowgetarg1=1; fi
   if [ ${1#ftp://} != $1 ]; then dowgetarg1=1; fi

   if [ ${2#http://} != $2 ]; then dowgetarg2=1; fi
   if [ ${2#ftp://} != $2 ]; then dowgetarg2=1; fi
fi


if [ $dowgetarg1 -gt 0 ]; then
   $wgetbin -nv $1 -O $workdir/1/$base1
else
   cp $1 $workdir/1/$base1
fi

if [ $dowgetarg2 -gt 0 ]; then
   $wgetbin -nv $2 -O $workdir/2/$base2
else
   cp $2 $workdir/2/$base2
fi

# ----------------------------------------------------------------------
# Maybe strip headers/footers from both files
# ----------------------------------------------------------------------

if [ $optstrip -gt 0 ]; then
   export which=1
   strip $workdir/1/$base1 > $workdir/1/$base1.stripped
   mv -f $workdir/1/$base1.stripped $workdir/1/$base1
   export which=2
   strip $workdir/2/$base2 > $workdir/2/$base2.stripped
   mv -f $workdir/2/$base2.stripped $workdir/2/$base2
fi

# ----------------------------------------------------------------------
# Maybe do html quoting
# ----------------------------------------------------------------------

if [ $opthwdiff -gt 0 ]; then
   sed -e 's/&/&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' $workdir/1/$base1 > $workdir/1/$base1.quoted
   mv -f $workdir/1/$base1.quoted $workdir/1/$base1
   sed -e 's/&/&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' $workdir/2/$base2 > $workdir/2/$base2.quoted
   mv -f $workdir/2/$base2.quoted $workdir/2/$base2
fi

# ----------------------------------------------------------------------
# Maybe strip preamble (title, boilerplate and table of contents) and
# postamble (Intellectual Property Statement, Disclaimer etc)
# ----------------------------------------------------------------------
if [ $optbody -gt 0 ]; then
   bodystrip $workdir/1/$base1 > $workdir/1/$base1.stripped
   mv $workdir/1/$base1.stripped $workdir/1/$base1
   bodystrip $workdir/2/$base2 > $workdir/2/$base2.stripped
   mv $workdir/2/$base2.stripped $workdir/2/$base2
fi

# ----------------------------------------------------------------------
# Get output file name
# ----------------------------------------------------------------------
if [ "$3" ]; then
  outfile=$3
else
    if [ $opthtml -gt 0 ]; then
      outfile=./$outbase.diff.html
    fi
    if [ $optchbars -gt 0 ]; then
      outfile=./$outbase.chbar
    fi
    if [ $optdiff -gt 0 ]; then
      outfile=./$outbase.diff
    fi
    if [ $optabdiff -gt 0 ]; then
      outfile=./$outbase.changes
    fi
    if [ $opthwdiff -gt 0 ]; then
      outfile=./$outbase.wdiff.html
    fi
fi
if [ "$outfile" ]; then
   tempout=./$(basename $outfile)
fi

# ----------------------------------------------------------------------
# Check if we can use wdiff for block diffs
# ----------------------------------------------------------------------
if [ $optnowdiff -eq 0 ]; then
   wdiffbin=$(lookfor wdiff)
   if [ -n "$wdiffbin" ]; then
      wdiffver=$($wdiffbin --version 2>/dev/null | egrep "(wdiff|GNU).+[0-9]\.[0-9]")
      if [ -z "$wdiffver" ]; then
        wdiffbin="";
	echo -en "\n  Found wdiff, but it reported no recognisable version."
      fi
   else
      echo -en "\n  Couldn't find wdiff."
   fi
   if [ -z "$wdiffbin" ]; then echo " Falling back to builtin diff colouring..."; fi
   export wdiffbin
   export wdiffver
   #echo "Found wdiff at $wdiffbin"
fi

# ----------------------------------------------------------------------
# Get some misc. info
# ----------------------------------------------------------------------
uname=$(uname -a)
export uname
awkbin=$AWK
export awkbin
awkver=$($AWK --version | head -n 1)
export awkver
diffbin=$(lookfor diff)
export diffbin
diffver=$(diff --version | head -n 1)
export diffver

# ----------------------------------------------------------------------
# Do diff
# ----------------------------------------------------------------------

origdir=$PWD
cd $workdir
if cmp 1/$base1 2/$base2 >/dev/null; then
   echo ""
   echo "The files are identical."
fi

if [ $opthtml -gt 0 ]; then
   diff -Bwd -U $prelines 1/$base1 2/$base2 | tee $workdir/diff | htmldiff > $tempout
fi
if [ $optchbars -gt 0 ]; then
   diff -Bwd -U 10000 1/$base1 2/$base2 | tee $workdir/diff | grep -v "^-" | tail +3 | sed 's/^+/|/' > $tempout
fi
if [ $optdiff -gt 0 ]; then
   diff -Bwd -U $prelines 1/$base1 2/$base2 | tee $workdir/diff > $tempout
fi
if [ $optabdiff -gt 0 ]; then
   diff -wd -U 1000 1/$base1 2/$base2 | tee $workdir/diff | abdiff
fi
if [ $optwdiff -gt 0 ]; then
   wdiff -a 1/$base1 2/$base2
fi
if [ $opthwdiff -gt 0 ]; then
    echo "<html><head><title>wdiff $base1 $base2</title></head><body>"		>  $tempout
    echo "<pre>"								>> $tempout
    wdiff -w "<strike><font color='red'>" -x "</font></strike>" -y "<strong><font color='green'>" -z "</font></strong>" 1/$base1 2/$base2 >> $tempout
    echo "</pre>"								>> $tempout
    echo "</body></html>"							>> $tempout
fi

if [ $optstdout -gt 0 ]; then
  cat $tempout
  rm  $tempout
else
  cd "$origdir"; if [ -f $workdir/$tempout ]; then mv $workdir/$tempout $outfile; fi
fi

if [ $optshow -gt 0 ]; then
   browse $outfile
fi

if [ $optkeep -eq 0 ]; then
   if [ -f $pagecache1 ]; then rm $pagecache1; fi
   if [ -f $pagecache2 ]; then rm $pagecache2; fi
   rm -fr $workdir/1
   rm -fr $workdir/2
   if [ -f $workdir/diff ]; then
      rm $workdir/diff
   fi
   rmdir $workdir
else
   cd /tmp
   tar czf $basename-$$.tgz $basename-$$
   echo "
   Temporary workfiles have been left in $workdir/, and packed up in $workdir.tgz"
fi

