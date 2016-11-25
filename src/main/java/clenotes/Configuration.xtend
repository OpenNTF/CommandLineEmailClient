/*
 * Copyright 2002, 2016 IBM Corp.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.  
 *
 *  Author: Sami Salkosuo, sami.salkosuo@fi.ibm.com
*/
package clenotes

import java.io.BufferedReader
import java.io.StringReader
import java.util.List
import java.util.Map
import java.util.Vector

class Configuration {
	public val static PROGRAM_NAME = "Command Line Email Client for IBM Notes"
	public val static VERSION = "5.2.1"

	public val static HEADER = '''«PROGRAM_NAME» v«VERSION»
Copyright (C) 2002, 2016 by IBM Corporation.
Licensed under the Apache License v2.0.
'''
	public val static MAILER = '''«PROGRAM_NAME» v«VERSION»'''
	public val static LINE_SEPARATOR = System::getProperty("line.separator")

	static var List<Option> globalOptions = new Vector<Option>()
	public var static Map<String, Option> globalOptionMap = newLinkedHashMap()

	var static List<String> options = new Vector<String>()
	public var static commandMap = newLinkedHashMap()
	var static List<String> commands = new Vector<String>()
	public var static configMap = newLinkedHashMap()

	var static LOG_ENABLED = false

	var static logParsing = false

	//TODO: change to better configuration
	val static configString='''#Command Line Email Client for IBM Notes configuration

[options]
#Options provided by program. Do not change existing.
#Options are always long options. Use '!' at the end of long option to specify
#that option requires argument. Remember to use -- with option. Only long
#options are supported. 
--help!: List options and commands. Optional argument is command name to get help or "!" to list command names only.
--log:Enabled logging for current session.
--noheader:Do not print header.
--version: Version info.|versionInfo
--password!: Users Notes ID password
--replica-id!: Select local database by specifying replica ID of the local database. Use "maildbinfo" command to get replica ID of local mail database.
--local: Use local mail database.
--output-format!: Custom output format string when listing emails. Formatting options: "d=Date", "t=time", "Z=timezone", "g=GMT time", "s=subject", "f=from", "I=from (inet address)", "m=mailer", "D=message id", "S=message size", "!=do not print index number", "a=list attachments". For example: --output-format=dts print email date, time and subject in one line.  
--tab: Use tab as delimiter when using output-format option.
--delim!: Custom delimiter when formatting mail with --output-format option. Default delimiter is ';'
--adjust-day!: Adjust cutoff day. Use integer value (1=mail today and yesterday, 2=mail from day before yesterday until today, and so on). No cutoff date means either "no cutoff date" or "today only" and it depends on command context.  
--exec-time: Display elapsed time of the program execution. Does not include Java start-up time.
--no-striphtmltags: Do not strip HTML tags when reading HTML emails. 
--all-mime-texts: Print all MIME text parts when reading emails. By default prints only the first mime text part, usually text/plain.
--server-name!: Domino server name where database is located.
--database-name!: Name of the database to be opened.
--dxl!: Exports mail as DXL. Optional value is file name where DXL is exported.  
--dxli!: Import DXL as mail database to be used.
#--host!: Server host name or IP address.
#--username!: User name to access server.

[commands]
#help.cmd: Lists all options and commands.

today.cmd:Read todays mail.
today.--all: Print all todays documents, not only mails.
today.--read!: Read specific mail (given as index, or '*' for all mails) from result set. See also read-command options.
today.--list: List mail from result set. See also list-command options.   

search.cmd:Search mail.
search.--subject!: Search mails with subject.  
search.--from!: Search mails with sender address.  
search.--formula!: Search mails using Notes formula.  
search.--formula-file!: Search mails using Notes formula in specified file.
search.--fulltext!: Search mails using full text.  
search.--view!: Search mails from specified View. Only --fulltext search is available and --adjust-day is ignored.  
search.--read!: Read specific mail (given as index, or '*' for all mails) from result set. See also read-command options.   
search.--list: List mail from result set. See also list-command options.   

read.cmd:Read latest mail or use with today, list or search commands
read.--attachments: Print attachment file names in this mail document.  
read.--linelen: Line length of mail to be read. Works only for Notes RichText mails.  
read.--fields: Print all fields and their types in mail document.
read.--fieldvalues!: Print value(s) of given field.  
read.--no-body: Do not print mail body.  
read.--detach-file!: Detach specified attachment to current directory or directory specified with --detach-dir option. 
read.--detach-all: Detach all attachment to current directory. 
read.--detach-dir!: Specify directory for detached attachments. 
read.--replace: Replace attached file, if it already exists. By default, if file exists, a sequence number is appended to file name. 
read.--move-to-folder!: Move mail to specified folder. 
read.--source-folder!: Source folder of mail to be moved. If not specified, default is "$Inbox". 
read.--delete: Delete mail.
read.--no-confirmation: Do not confirm mail delete.  
read.--reply: Reply email to sender.  
read.--all: Reply email to all recipients.
read.--body!: Body in reply mail.

replicate.cmd: Replicate local database to server.
replicate.--server!:Specify server for replication. Default is mail database server.
replicate.--database!:Specify local database file path for replication. Default is mail database.
replicate.--replica-id!:Replica ID of database. Default is mail database replica ID.

send.cmd: Send mail.
send.--to!: Comma separated list of recipients. For example: --to=="recp1@com,recp2@another.com"
send.--file-to!: Path to text file that includes comma separated list of recipients. 
send.--cc!: Comma separated list of CC recipients. For example: --cc=="recp1@com,recp2@another.com"
send.--file-cc!: Path to text file that includes comma separated list of CC recipients. 
send.--bcc!: Comma separated list of BCC recipients. For example: --bcc=="recp1@com,recp2@another.com"
send.--file-bcc!: Path to text file that includes comma separated list of BCC recipients. 
send.--attach!: Comma separated list of files to be attached.
send.--subject!: Mail subject.
send.--body!: Mail body.
send.--file-body!: Mail body read from specified text file.
send.--charset!: Charset of --file-body file. Default is UTF-8.
send.--html: Send mail as HTML.
send.--urgent: Send mail as urgent.
send.--encrypt: Encrypt mail.
send.--sign: Sign mail.
send.--nosave: Do not save mail.
send.--replyto!: Set reply-to parameter to email.
send.--principal!: Override email sender. Remember to add Notes domain after email, for example: sender@somewhere.com@NotesDomain.
send.--signature!: Add signature to email.
send.--file-signature!: Add signature to email from specified file.

list.cmd: List all mail in mail database.
list.--all: List all documents, not only mails.
list.--read!: Read specific mail (given as index, or '*' for all mails) from result set. See also read-command options.
list.--start!: Start index when listing mail.
list.--end!: End index when listing mail.
list.--sortorder!: Sort mails. Use value ASC or DESC. Default is ASC
list.--sortfield!: Sort mails by field. Use values DATE, SUBJECT or FROM. Default is DATE.
list.--folder!: Specify mail folder to be used. Default is inbox ($Inbox).

maildbinfo.cmd:Mail database information. Use --server-name, --replica-id or --database-name to specify database other than mail database.
notes-version.cmd: The release of Domino the session is running on.

appointments.cmd: Show appointments.
appointments.--today: List only todays appointments.
appointments.--week: List appointments in next 7 days.
appointments.--sincedate!: List appointments since specified date. Date format is "DD/MM/YYYY".
appointments.--desc: Show appointment description.
appointments.--required: List required participants.
appointments.--optional: List optional participants.

shell.cmd: Command line email shell, like v1.0 in the old days.


[configuration]
#Program configuration. Add here static configuration that is not expected to 
#change
write_log: false

'''

	def static load() {
//		val BufferedReader br = new BufferedReader(new FileReader(new File('config/clenotes.cfg')))

		val BufferedReader br = new BufferedReader(new StringReader(configString))
		//load config file
		var String line

		while ((line = br.readLine()) != null) {
			line=line.trim
			switch line {
				case line.startsWith("#") || line.empty: {
					//ignore comments and empty lines
				}
				case line.equals("[options]"):
					ConfigurationSection::setOption
				case line.equals("[commands]"):
					ConfigurationSection::setCommand
				case line.equals("[configuration]"):
					ConfigurationSection::setConfiguration
				case ConfigurationSection::option:
					options.add(line)
				case ConfigurationSection::command:
					commands.add(line)
				case ConfigurationSection::configuration: {
					if (line.contains("write_log")) {
						if (LOG_ENABLED == false && line.toLowerCase().contains("true")) {
							LOG_ENABLED = true;
						}
					}
					val configEntry = line.split(":")
					configMap.put(configEntry.get(0).trim(), configEntry.get(1).trim())

				}
			}
		}
		br.close()
	}

	def static printConfigFileEntries() {
		if (logParsing) {
			Logger::log("Options: " + globalOptions)
			Logger::log("Commands: " + commandMap)
			Logger::log("Configuration: " + configMap)

		}

	}

	def static parse() {

		//parse config file entries
		for (option : options) {
			val firstIndex = option.indexOf(":")
			var name = option.substring(0, firstIndex)
			var desc = option.substring(firstIndex + 1)
			name = name.replace("--", "").trim()
			var mandatoryValue = false;
			if (name.contains("!")) {
				mandatoryValue = true
				name = name.replace("!", "")
			}
			desc = removeFunctionName(desc)
			var Option opt = new Option()

			opt.setName(name)
			opt.setDescription(desc)
			opt.setMandatoryValue(mandatoryValue)

			globalOptions.add(opt)
			globalOptionMap.put(opt.name, opt);

		}

		for (command : commands) {
			val commandName = command.substring(0, command.indexOf("."))
			if (command.contains(".cmd")) {

				//extract command name
				var commandDescription = command.substring(command.indexOf(":") + 1)
				commandDescription = removeFunctionName(commandDescription)
				var cmd = new Command()
				cmd.setName(commandName)
				cmd.setDescription(commandDescription)

				//commandName, commandDescription, new Vector<Option>())
				commandMap.put(commandName, cmd)
			} else {
				var commandObj = commandMap.get(commandName) as Command;
				if (command.contains("--")) {

					//command option
					var optionString = command.substring(command.indexOf(".") + 1)
					if(logParsing) Logger::log("Option in config: %s", optionString)
					val cInd = optionString.indexOf(":")
					var optionName = optionString.substring(0, cInd)
					val mandatoryValue = optionName.contains("!")
					optionName = optionName.replace("--", "").replace("!", "").trim()
					if(logParsing) Logger::log("Option in config: %s", optionName)
					var optionDesc = optionString.substring(cInd + 1).trim()
					if(logParsing) Logger::log("Option desc config: %s", optionDesc)
					var opt = new Option()
					opt.setMandatoryValue(mandatoryValue)
					opt.setName(optionName)
					opt.setDescription(optionDesc)

					var cmdOpts = commandObj.optionMap
					cmdOpts.put(opt.name, opt)
				}
			}

		}

		if (logEnabled) {
			for (commandName : commandMap.keySet) {
				if(logParsing) Logger::log("Command object: " + commandMap.get(commandName))

			}

		}

	}

	private def static removeFunctionName(String _desc) {
		var desc = _desc
		desc = desc.trim()
		val ind = desc.indexOf("|")
		if (ind > -1) {
			desc = desc.substring(0, ind)
		}
		return desc

	}

	def static setLogEnabled(boolean enabled) {
		LOG_ENABLED = enabled

	}

	def static isLogEnabled() {
		return LOG_ENABLED
	}

	def static getConfig(String configName) {
		return configMap.get(configName)
	}

}
