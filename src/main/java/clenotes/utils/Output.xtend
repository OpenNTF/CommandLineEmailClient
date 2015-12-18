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
package clenotes.utils

import java.util.List

import static extension clenotes.utils.extensions.ExtensionMethods.*

class Output {

	val static defaultColumnWidth = 20
	val static defaultScreenWidth = 80
	val static defaultIndentation = 4
	val static defaultLineStartIndentLevel = 1

	/*
	 * print messages in messagelist in single line per columns 
	 * format to be pretty
	 *  
	*/
	def static prettyPrintln(List<String> messageList) {
		prettyPrintln(messageList, defaultColumnWidth, defaultScreenWidth, defaultLineStartIndentLevel)
	}

	def static prettyPrintln(List<String> messageList, int columnWidth, int lineStartIndentLevel) {
		prettyPrintln(messageList, columnWidth, defaultScreenWidth, lineStartIndentLevel)

	}

	def static prettyPrintln(List<String> messageList, int columnWidth, int screenWidth, int lineStartIndentLevel) {
		if (lineStartIndentLevel != 0) {
			print(" ".times(lineStartIndentLevel * defaultIndentation))

		}
		var lineLength = 0
		for (_msg : messageList) {
			var msg = _msg
			msg = msg.ljust(columnWidth)
			lineLength = lineLength + msg.length
			print(msg)

		//TODO: pretty print, multi line help with correct indentation. See below.
		//     --delim=ARG          Custom delimiter when formatting mail with 
		//                          --output-format option. Default delimiter is ';'  
		}
		println
	}
}
