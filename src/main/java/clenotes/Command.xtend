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
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder

class Command {
	@Accessors String name = null
	@Accessors String description = null

	//@Property Map<String,Option> options=new LinkedHashMap<String,Option>()
	@Accessors Map<String, Option> optionMap = newLinkedHashMap()

	def hasOption(String optionName) {
		optionMap.containsKey(optionName)
	}

	def addOption(String optionName, String value) {
		if (optionMap.containsKey(optionName)) {

			//option already exists
			var option = optionMap.get(optionName) as Option
			var values = option.values
			values.add(0, value)
			option.values = values
		} else {

			//global option does not exist
			var option = new Option
			option.name = optionName
			option.addValue(value)
			optionMap.put(optionName, option)
		}

	}

	def getOptionValue(String optionName) {

		var valueList = getOptionValues(optionName)
		var String value = null
		if (valueList != null) {
			if (valueList.size > 1) {
				value = valueList.join(",")
			} else {
				value = valueList.get(0)
			}
		}
		value

	}

	def getOptionValues(String optionName) {
		var Option option = optionMap.get(optionName)
		var List<String> values = null
		if (option != null) {
			values = option.values
		}
		values
	}

	public override String toString() {
		var str = new ToStringBuilder(this);
		str.addDeclaredFields
		return str.toString;
	}
}
