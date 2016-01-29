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

import java.io.File
import java.io.FileWriter
import java.io.PrintWriter
import java.text.SimpleDateFormat
import java.util.Date

class Logger {
	static SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS z")

	def static void log(Object msg) {
		if (Configuration::logEnabled) {

			val logDir=new File("log")
			if (logDir.exists==false)
			{
				logDir.mkdir
			}
			//open log file
			val PrintWriter logWriter = new PrintWriter(new FileWriter(new File("log/clenotes.log"), true))
			logWriter.println(">> " + formatter.format(new Date()) + ": " + msg)
			//logWriter.println("<<")
			logWriter.close()
		}
	}

	def static void log(String msg, Object... args) {
		if (Configuration::logEnabled) {
			log(String.format(msg,args))
		}
	}

}
