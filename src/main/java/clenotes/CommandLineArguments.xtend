/*
 * Copyright 2002, 2015 IBM Corp.
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

import java.util.List
import java.util.Map
import java.util.Vector

/*
 * Command line syntax is
 * 
 * [global options] [command [command-options] ...]
 * 
 * option is --optionaname
 * or --optionname=value1,value2
 * #no spaces between values, 
 * 
 * 
 */
class CommandLineArguments {

	static var List<String> args

	public static var Map<String, Option> globalOptionMap = newLinkedHashMap()
	public static var commandMap = newLinkedHashMap()

	def static parse(String[] _args) {
		args = _args
		var i = 0
		var commandInProgress = false
		var commandNameInProgress = "";
		while (i < args.size) {
			var arg = args.get(i)
			Logger::log("Argument: " + arg)

			//if first args does not start with '--' then it is a command
			if (!arg.startsWith('--')) {

				//command
				commandInProgress = true
				var cmd = new Command()
				cmd.setName(arg)
				commandNameInProgress = arg
				commandMap.put(arg, cmd)
			} else {

				//option
				val option = getNextOption(arg)

				if (commandInProgress) {
					var cmd = commandMap.get(commandNameInProgress) as Command
					var opts = cmd.optionMap
					opts.put(option.name, option)
				} else {
					globalOptionMap.put(option.name, option)
				}
			}
			i = i + 1
		}

		Logger::log("Global Options in command line: " + globalOptionMap)
		Logger::log("Commands  in command line: " + commandMap)

	}

	private static def getNextOption(String _argument) {

		var argument = _argument.replaceFirst('--', '')
		var Option option

		//if argument has'=' then it has values
		if (argument.contains('=')) {

			//there are values
			var argumentName = argument.substring(0, argument.indexOf('='))
			var argumentValues = argument.substring(argument.indexOf('=') + 1)
			var List<String> values = new Vector<String>()

			if (argumentName != "delim" && argumentValues.contains(',')) {
				var List<String> _values = argumentValues.split(',')
				for (v : _values) {
					values.add(v)
				}
			} else {
				values.add(argumentValues)
			}

			if (globalOptionMap.containsKey(argumentName)) {
				option = globalOptionMap.get(argumentName) as Option
				var existingValues = option.values;
				existingValues.addAll(values)

			} else {
				option = new Option()
				option.setName(argumentName)
				option.setValues(values)
			}
		} else {

			//no values
			option = new Option()
			option.setName(argument)
		}

		args.subList(1, args.size)
		return option
	}

	def static hasOption(String optionName) {
		var option = globalOptionMap.get(optionName)
		option != null
	}

	def static getValue(String optionName) {
		var option = globalOptionMap.get(optionName) as Option
		var String value = null
		if (option != null) {
			value = option.value
		}
		value

	}

	def static getValues(String optionName) {
		var option = globalOptionMap.get(optionName) as Option
		var List<String> values = null
		if (option != null) {
			values = option.values
		}
		values

	}

	def static addOption(String optionName, String value)
	{
		
		if(globalOptionMap.containsKey(optionName))
		{
			//global option already exists
			var option = globalOptionMap.get(optionName) as Option
			var values=option.values
			values.add(0,value)
			option.values=values			
		}	
		else
		{
			//global option does not exist
			var option=new Option
			option.name=optionName
			option.addValue(value)
			globalOptionMap.put(optionName,option)
		}	
	}
}
