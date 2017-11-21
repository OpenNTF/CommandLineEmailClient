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
package clenotes.utils

import clenotes.Configuration
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.util.Map
import java.util.Vector

/*
 * General purpose functions/methods.
 */
class Utils {

	def static sortMap(Map<?, ?> map) {
		var keySet = map.keySet

		//var String[] vr = newArrayList
		var vr = newArrayList
		for (key : keySet) {
			vr.add(key as String)
		}
		vr.sort
	}

	def static concatToString(Vector<?> items) {
		var txt = new StringBuffer()
		for (item : items) {
			txt.append(item.toString)
			txt.append(Configuration::LINE_SEPARATOR)
		}
		txt.toString
	}

	def static Vector<String> readFileToVector(String fileName) {

		var f = new File(fileName)
		var fr = new BufferedReader(new FileReader(f))
		var lines = new Vector<String>()

		var line = fr.readLine
		while (line !== null && !line.equals("")) {
			lines.add(line.trim)
			line = fr.readLine
		}
		fr.close()

		lines

	}

	def static removeMultipleEmptyLines(String txt) {
		var text = new StringBuffer
		var emptyLastLine = false
		var txtLines = txt.split(Configuration::LINE_SEPARATOR)
		for (_line : txtLines) {
			var line = _line.trim
			if (line.nullOrEmpty) {
				if (!emptyLastLine) {
					text.append(Configuration::LINE_SEPARATOR)
				}
				emptyLastLine = true
			} else {
				emptyLastLine = false
				text.append(line)
				text.append(Configuration::LINE_SEPARATOR)
			}
		}
		text.toString
	}

	def static checkIfFileExists(String filePath) {
		var newFilePath = filePath
		var seq = 2
		var f = new File(newFilePath)
		while (f.exists) {

			//modify file
			var index = filePath.lastIndexOf(".")
			if (index == -1) {

				//not found file type, just add sequence to end
				newFilePath = String.format("%s_(%d)", filePath, seq)
			} else {

				//found fule type, add seq before type
				newFilePath = String.format("%s_(%d)%s", filePath.substring(0, index), seq, filePath.substring(index))
			}
			seq = seq + 1
			f = new File(newFilePath)
		}
		return newFilePath

	}

	def static replaceInvalidCharactersInFileName(String fileName)
	{
		var name=fileName
		//invalid characters in filename
		//https://en.wikipedia.org/wiki/Filename
		name=name.replace("\\","-")
		name=name.replace("/","-")
		name=name.replace("?","-")
		name=name.replace("%","-")
		name=name.replace("*","-")
		name=name.replace(":","-")
		name=name.replace("|","-")
		name=name.replace("\"","-")
		name=name.replace("<","-")
		name=name.replace(">","-")
		
		name
	}
	
}
