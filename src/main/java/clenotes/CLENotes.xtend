/*
 * Copyright 2002, 2017 IBM Corp.
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

import clenotes.commands.Appointments
import clenotes.commands.List
import clenotes.commands.MailDBInfo
import clenotes.commands.ReadMail
import clenotes.commands.Replicate
import clenotes.commands.Search
import clenotes.commands.Send
import clenotes.commands.Shell
import clenotes.commands.Today
import clenotes.utils.DxlUtils

class CLENotes implements Runnable {


	//var Session notesSession = null
	new() {
	}

	override run() {

		if (!verifyOptionsAndCommands()) {
			ErrorLogger.setErrorCode(-1)
			return
		}

		var commandMap = CommandLineArguments::commandMap

		if (CommandLineArguments::hasOption("version")) {

			//show version info of CLENotes and Java
			option_Version
			return
		}

		var password = CommandLineArguments::getValue("password")

		//TODO: add DIIOP
		//--server-host!: Domino server host name or IP address to be used with DIIOP calls (does not require local Notes installation).
		var String serverHost = null // CommandLineArguments::getValue("server-host")

		//init notes session
		val hostName=CommandLineArguments::getValue("host")
		if  (hostName!=null)
		{
			val userName=CommandLineArguments::getValue("username")
			if (userName==null)
			{
				ErrorLogger.error("User name required. Use --username option.")
				return
			}
			CLENotesSession.initSession(hostName, password)

		}
		else
		{
			CLENotesSession.initSession(serverHost, password)

		}

		try {

			//do commands	
			if (!commandMap.empty) {

				for (cmdName : commandMap.keySet) {

					//do commands one at a time
					var command = commandMap.get(cmdName) as Command
					switch (cmdName) {
						//use simple switch to determine command object to invoke
						//would be better to dynamically find out the command object based
						//on command name... but perhaps later...					
						case "today": {
							Today::execute(command)
						}
						case "replicate": {
							Replicate::execute(command)
						}
						case "search": {
							Search::execute(command)
						}
						case "read": {
							ReadMail::readLatestMail(command)
						}
						case "list": {
							List::execute(command)
						}
						case "notes-version": {
							command_NotesVersion
						}
						case "send": {
							Send::execute(command)
						}
						case "appointments": {
							Appointments::execute(command)
						}
						case "maildbinfo": {
							MailDBInfo::execute(command)
						}
						case "shell": {
							Shell::execute(command)
						}
					}
				}
			}

			if (CommandLineArguments::hasOption("dxli")) {

				//delete imported DXL database
				DxlUtils.deleteImportedDxlDatabase
			}

		//catch any exception and throw them again
		} catch (RuntimeException re) {
			ErrorLogger.setErrorCode(110)
			throw re
		} catch (Exception e) {
			ErrorLogger.setErrorCode(111)
			throw e
		} finally {

			CLENotesSession.recycle
		}
	}

	def option_Version() {
		println("CLENotes      : " + Configuration::VERSION)
		println("Java          : " + System::getProperty("java.version"))

	}

	def command_NotesVersion() {
		var String prog
		var notesSession = CLENotesSession.session

		if (notesSession.onServer) {
			prog = 'Domino version: '

		} else {
			prog = 'Notes version : '

		}
		print(prog)
		print(notesSession.getNotesVersion())
		print(" (")
		print(notesSession.getPlatform)
		println(")")
		println("CLENotes      : " + Configuration::VERSION)
		println("Java          : " + System::getProperty("java.version"))

	}

	def verifyOptionsAndCommands() {

		//verify that options and commands specified in command line
		//are valid
		var atLeastOneValid = false
		var optionMap = CommandLineArguments::globalOptionMap
		var optionMapConfig = Configuration::globalOptionMap
		for (key : optionMap.keySet) {
			if (optionMapConfig.containsKey(key)) {
				atLeastOneValid = true
			} else {
				println("Unknown option: " + key)
			}
		}

		var commandMap = CommandLineArguments::commandMap
		var commandMapConfig = Configuration::commandMap
		for (key : commandMap.keySet) {
			if (commandMapConfig.containsKey(key)) {
				atLeastOneValid = true
			} else {
				println("Unknown command: " + key)
			}
		}

		atLeastOneValid
	}

}
