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
package clenotes.commands

import clenotes.Command
import clenotes.CommandLineArguments
import clenotes.Configuration
import clenotes.Option
import java.util.Map

import static extension clenotes.utils.extensions.ExtensionMethods.*

class Help {

	static val OPT_NAME_SECTION_LENGTH = 28
	static val OPT_DESC_SECTION_LENGTH = 42

	def static execute(Command cmd) {
		var rv = 0

		println("Usage: clenotes.cmd [global-options] [cmd [cmd-options]]")

		//help commmand
		//do help
		//Usage: clenotes [global-options] [cmd cmd-options]
		//Global options:
		//  --help         This help
		//  -ccc=<arg>     help desc
		//                 in multiple lines
		//
		//Commands:
		//  cmdname        desc
		//    --opti
		//  cmdname1       desc2
		//    --opt2
		val globalOptionMap = Configuration::globalOptionMap

		//println("Usage: clenotes.cmd [OPTIONS] [CMD [CMD-OPTIONS] [CMD ...] ]")
		println()
		println("Global options (common for one or more commands):")
		val goptIndent = "  --"
		printOptions(goptIndent, globalOptionMap)
		println()
		println("Commands:")

		var helpWithCmdName = CommandLineArguments::getValue("help")
		var cmdNamesOnly = helpWithCmdName == "!"

		val commandMap = Configuration::commandMap
		val _commandNames = commandMap.keySet		
		val commandNames=_commandNames.sort
		
		val commandIndent = "  "
		for (name : commandNames) {
			var command = commandMap.get(name) as Command
			if (cmdNamesOnly) {
				helpWithCmdName = name as String
			}
			if (helpWithCmdName === null || name == helpWithCmdName) {
				val cmdName = commandIndent + command.name
				var java.util.List<String> desc = command.description.split(" ")

				val appendSpaces = OPT_NAME_SECTION_LENGTH - cmdName.length
				val appendString = " ".times(appendSpaces)
				printHelp(cmdName + appendString, desc)
				if (!cmdNamesOnly) {
					var cmdOptions = command.optionMap
					printOptions("    --", cmdOptions)

				}
			}
		}
		return rv
	}

	private static def printOptions(String indent, Map<String, Option> optionMap) {
		val _optionNames = optionMap.keySet
		val optionNames=_optionNames.sort
		
		for (name : optionNames) {
			val option = optionMap.get(name)
			val String optName = option.name
			val String[] optDesc = option.description.split(" ")
			val boolean hasValue = option.mandatoryValue
			var String descStr = indent + optName + if(hasValue) "=ARG" else ""
			val appendSpaces = OPT_NAME_SECTION_LENGTH - descStr.length

			val appendString = " ".times(appendSpaces)

			descStr = descStr + appendString
			printHelp(descStr, optDesc)
		}
	}

	private static def printHelp(String name, java.util.List<String> desc) {

		val indentation = " ".times(OPT_NAME_SECTION_LENGTH)
		var java.util.List<String> descLines = newArrayList
		var StringBuffer sb = new StringBuffer
		for (word : desc) {
			sb.append(word)
			if (sb.length > OPT_DESC_SECTION_LENGTH) {
				descLines.add(sb.toString.substring(0, sb.length - word.length))
				sb = new StringBuffer
				sb.append(word)
			}
			sb.append(" ")
		}
		descLines.add(sb.toString.trim)
		descLines.forEach [ line, index |
			if (index == 0) {
				println(name + line)

			} else {
				println(indentation + line)

			}
		]
	}

}
