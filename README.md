# Command Line Email Client for IBM Notes

Command Line Email Client for IBM Notes (also known as CLENotes and, in the past, NotesCLI) is a tool to access IBM Notes email from, you guessed it, the shell and command prompt.
Functions include reading mail, sending mail, listing mail and searching mail and the main use case is to automate Notes email related tasks.

Latest release is available from OpenNTF: [CLENotes@OpenNTF](http://www.openntf.org/main.nsf/project.xsp?r=project/command%20line%20email%20client/)

##Requirements

- IBM Notes, v8 or later, client must be installed locally.
- IBM Domino as mail server.
- 32-bit Java 1.7 or later.
- PATH environment variable must include path to Java-executable.

CLENotes is tested with Windows but Linux and Mac should work too.

##Installation

1. The first thing to do is to add IBM Notes directory to system PATH environment variable. Otherwise, executing clenotes.cmd will give error: java.lang.UnsatisfiedLinkError: no nlsxbe in java.library.path so make sure that IBM Notes directory included in PATH.
2. Unzip *clenotes-VERSION*.zip to a directory of your choosing.
3. When executing CLENotes for the first time, the program checks Notes Java classes availability. If classes are not present, CLENotes asks to install them and tries to automatically find IBM Notes Java classes by searching commonly used Notes installation directories and then extracting it's contents to classes-directory. If CLENotes doesn't find Notes.jar, user is prompted for it's location.
4. Windows: See the help using clenotes.cmd --help and start using the program.
5. Linux and other platforms: clenotes.sh should work. Or open clenotes.cmd/.sh in a text editor to see the Java syntax and start using the program.
6. In order to use clenotes from any directory, modify clenotes.cmd/.sh file and add installation path to classpath. For example:  ```java -classpath c:/path/to/clenotes/classes;c:/path/to/clenotes/lib/* clenotes.Main %*```. Then add clenotes.cmd/.sh to PATH.

##Usage

Usage: ```clenotes.cmd [OPTIONS] [CMD [CMD-OPTIONS] [CMD ...] ]```. See sample commands.
Commands include:

- today - Read todays mail.
- send - Send mail.
- search - Search mail.
- read - Read latest mail or specific mail when listing mail with today.
- list -List mail in mail database.
- maildbinfo - Show mail database information.
- notes-version - Show Notes, Java and OS version.

See full command line help using: ```clenotes.cmd --help```.

##Sample commands

A few sample commands are here: [src/files/samplecommands.md](https://github.com/OpenNTF/CommandLineEmailClient/blob/master/src/files/samplecommands.md).

##Folders

Starting from version 5.3, CLENotes has support for folders. There is global '--folder' option that is used to select folder and it is supported in today,list and search commands.

Notes/Domino does not use folder references by default.
For the curious, these two support docs may be interesting: [LotusScript FolderReferences property helps determine in which folders a document is stored](http://www-01.ibm.com/support/docview.wss?rs=463&uid=swg21092899) and [LotusScript FolderReferences property not populated when document is moved to folder](http://www-01.ibm.com/support/docview.wss?uid=swg21209890)

**Note:** maintaining folder references impacts performance.

####Enable folder references
 
In order to use folders, you need to enable it. Enable it using this command:

```clenotes.cmd dev --folderrefs --enable``` 

This enables folder tracking for all future mails/documents.
For all existing documents, folders are still not tracked.

Use this command to move all existing mails to their folders:

```clenotes.cmd dev --folderrefs --putallinfolder``` 

After folder references are enabled, mails can be listed or searched from specified folder.
For example, following command searches all mails with subject 'January' from 'project'-folder:

```clenotes.cmd --folder=project search --subject=January``` 

To disable folder references, use this command:

```clenotes.cmd dev --folderrefs --disable``` 

##Development

CLENotes source is [Xtend](https://eclipse.org/xtend/), a dialect of Java, and it was [chosen for a reason](http://sami.salkosuo.net/reasons-for-xtend/).

Development is mostly done using Oracle Java, Windows and Eclipse IDE. Sources are built using Maven.
In order to build CLENotes, location of Notes.jar must be either specified in pom.xml
or NOTES_JAR_LOCATION environment variable must be pointed to Notes.jar location.

By default, starting maven build cleans existing build and then compiles and packages
CLENotes to target-directory. Distribution file is clenotes-VERSION.zip.

##History

CLENotes has been available for a long time, ever since 2002: 

- http://sami.salkosuo.net/about-the-history-of-clenotes
- http://sami.salkosuo.net/history-in-the-making
- http://sami.salkosuo.net/clenotes-v1-0-discovered/

####OPENNTF
    This project is an OpenNTF project, and is available under the Apache License V2.0.  
    All other aspects of the project, including contributions, defect reports, discussions, 
    feature requests and reviews are subject to the OpenNTF Terms of Use - available at 
    http://openntf.org/Internal/home.nsf/dx/Terms_of_Use.
