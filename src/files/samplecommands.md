#Sample Commands

A few sample commands to get started.

####Get help

*clenotes.cmd --help*

####Search mail from specific sender

*clenotes.cmd --password=mypassword search --from=yetanothersender*

This search results something like this:
```
Search returned 2 mails.

[0] 17.11.2008 10:59:27 ZE2
  From: yetanothersender@nowhere.org
  Subject: Re: responding to your question
  Attachments: answerdocument.txt.vbs

[1] 09.12.2008 01:24:42 ZE2
  From: yetanothersender@nowhere.org
  Subject: Fw: This is good stuff
  Attachments: FunnyStuffFromReliableSource.txt.vbs
```
You can do search also by subject, formula or fulltext.
Notes formula documentation is found in [Notes InfoCenter](http://www-01.ibm.com/support/knowledgecenter/SSVRGU_9.0.1/com.ibm.designer.domino.main.doc/H_NOTES_FORMULA_LANGUAGE.html?lang=en) 

Couple of samples of formulas:
```
--formula="DeliveredDate > @Date(2013,11,1)", returns mails received after December 1st, 2013.
--formula="@Contains(From;\"UNIX\")", returns mails where sender address includes "UNIX".
--formula="DeliveredDate > @Date(2013,11,1) & @Contains(From;\"UNIX\")", returns mails where sender address includes "UNIX" and mail was received after December 1st, 2013.
```

###Read first mail from today

*clenotes.cmd today --read=1*

This reads mail with index=1 in todays list. For example: in previous today-example mail index=1 would be mail from 'another.sender@anywhere.org'. Read-command lists some mail headers and mail body as text.
Read-option (and command) has many options (see help). 

###Search emails with subject and detach all attachments to a directory

*clenotes.cmd search --subject="string in subject" --nocase --read=* --detach-all --detach-dir="c:\temp"*

--nocase option means case-insensitive search.

####List all mail

*clenotes.cmd list*

This lists all mails in mail database. Use command-options start and end to limit results.

####Send mail to specified recipient with attachment

*clenotes.cmd send --to=recipient@org.org --subject="Status change: Tracking ID 12345" --body="Your order ID 12345. Status changed to: COMPLETE." --attach=orderReceipt.pdf*

####Use output-format option to format output when listing mail

*clenotes.cmd --output-format=dtm today*

This command lists all mail in the mail database and prints date, time and mail program. 
Output is something like this:
```
0;09.12.2008;02:50:29;Lotus Notes Release 8.0.1 HF105 April 10, 2008
1;09.12.2008;04:36:20;Lotus Notes Build V85_M1_05262008 May 26, 2008
2;09.12.2008;01:24:42;Lotus Notes Release 7.0 HF400 February 20, 2008
```

The default delimiter is ';'. Option '--delim' is used to specify custom delimiter.
For example, clenotes.cmd --output-format=dtm --delim=" | " today:
```
0 | 09.12.2008 | 02:50:29 | Lotus Notes Release 8.0.1 HF105 April 10, 2008
1 | 09.12.2008 | 04:36:20 | Lotus Notes Build V85_M1_05262008 May 26, 2008
2 | 09.12.2008 | 01:24:42 | Lotus Notes Release 7.0 HF400 February 20, 2008
```

####Specify remote server and mail database

*clenotes.cmd --server-name="REMOTESRV/DIV/ORG" --database-name="mail/otheruser.nsf" today*

This command lists todays mail for user otheruser whose mail database is in server REMOTESRV.

####Search mails of specific sender and sort them by date in descending order

*clenotes.cmd --local search --from=sender --sortorder=DESC*

This command searches and lists mails from sender and lists them in descending order where mail number 0 is the latest.

####Get mail database info including replica ID

*clenotes.cmd maildbinfo*

Program may ask your Notes ID password.
You get something like this:
```
Mail database information
Title         : My Name
Replica ID    : E22957FEBC4AA6FA
File path     : maildir\mymail.NSF
ODS version   : 43
Server        : SERVER1/ORG
Size (used %) : 720.75 MB (94.60%)
Created       : 05.01.2006 13:41:59 GMT
Modified      : 10.12.2008 08:05:26 GMT
HTTP URL      :
Notes URL     : notes://SERVER1@ORG/__E22957FEBC4AA6FA.nsf?OpenDatabase
```

####Get todays mail using local replica and your password

*clenotes.cmd --local --password=mypassword today*

You get list of todays mail similar to this:
```
3 mails since yesterday.

[0] 09.12.2008 02:50:29 ZE2
  From: sender@somewhere.org
  Subject: Re: responding mail
  Attachments:

[1] 09.12.2008 04:36:20 ZE2
  From: another.sender@anywhere.org
  Subject: Question to you?
  Attachments:

[2] 09.12.2008 01:24:42 ZE2
  From: yetanothersender@nowhere.org
  Subject: Fw: This is good stuff
  Attachments: FunnyStuffFromReliableSource.txt.vbs
```

####Replicate your mail database

*clenotes.cmd --password=mypassword replicate*
