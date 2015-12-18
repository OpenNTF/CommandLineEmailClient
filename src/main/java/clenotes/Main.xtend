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

import clenotes.commands.Help
import clenotes.utils.Input
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.List
import java.util.zip.ZipInputStream
import lotus.domino.NotesThread

import static extension clenotes.utils.extensions.ExtensionMethods.*

class Main {

	def static printHeader() {
		if (!CommandLineArguments::globalOptionMap.containsKey("noheader")) {
			println(Configuration::HEADER)
		}
	}

	def static void main(String[] args) {
		var returnValue = 0
		var startTime = System::currentTimeMillis
		try {

			for (arg : args) {
				if (arg == "--log") {
					Configuration::setLogEnabled(true)
				}
			}

			//test Notes installation
			try {
				new TestNotesAvailability()
			} catch (NoClassDefFoundError exc) {

				println("Notes classes not found.");
				val answer = Input.prompt("Install Notes classes (yes/no) [yes]? ")

				//val prompt = "Install Notes classes (yes/no) [yes]? "
				//var answer = System::console.readLine(prompt)
				if (answer.empty || answer == "yes") {
					setupNotesClasses
				} else {
					println("Notes classes not installed.");

				}
				return
			}

			//read and parse command line
			//load config file
			Configuration::load()
			val List<String> argsList = args
			Logger::log("CLENOTES START: %s",argsList.join(" "))

			CommandLineArguments::parse(args)

			//parse config file
			Configuration::parse()
			Configuration::printConfigFileEntries()
			printHeader()
			var commandMap = CommandLineArguments::commandMap
			if (commandMap.empty && CommandLineArguments::globalOptionMap.empty) {
				println("No commands specified. Use --help option for usage.")
				return
			}

			if (CommandLineArguments::globalOptionMap.containsKey("help") || commandMap.containsKey("help")) {
				returnValue = Help::execute(null) //send null as params in Help, they're not used
				return
			}

			//if this far => Notes classes available
			Logger::log("Starting CLENotes thread..")
			var cleNotes = new CLENotes
			var threadName = "CLENotesThreadRunnable"
			var notesThread = new NotesThread(cleNotes, threadName)
			notesThread.start();
			notesThread.join()
			returnValue = ErrorLogger::getErrorCode
			Logger::log("CLENotes thread ended..")

		} finally {
			var endTime = System::currentTimeMillis
			var execTime = "Execution time: " + (endTime - startTime) / 1000.0 + " seconds."
			if (CommandLineArguments::hasOption("exec-time")) {
				println()
				println(execTime)
			}
			Logger::log(execTime)
			Logger::log("CLENOTES END")
			System::exit(returnValue)
		}
	}

	private static def setupNotesClasses() {
		val OSname = System::getProperty("os.name")
		Logger::log("OS name: %s",OSname)
		var notesDirs = newLinkedList()
		val libDir = "/jvm/lib/ext/Notes.jar"
		switch (OSname) {
			case OSname.toLowerCase.indexOf("win") >= 0: {
				notesDirs.add("C:/Program Files/IBM/Lotus/Notes" + libDir)
				notesDirs.add("C:/Lotus/Notes" + libDir)
				notesDirs.add("c:/notes" + libDir)
			}
			case OSname.toLowerCase.indexOf("linux") >= 0: {
				notesDirs.add("/opt/ibm/lotus/notes" + libDir)
			}
			case OSname.toLowerCase.indexOf("mac") >= 0: {
				notesDirs.add("/Applications/Notes.app" + libDir)
			}
			default: {
				val dir = promptNotesJarLocation
				if (dir.nullOrEmpty) {
					return
				}
				notesDirs.add(dir)
			}
		}

		var installed = notesDirs.installNotesJar()
		while (!installed) {

			val dir = promptNotesJarLocation
			if (dir.nullOrEmpty) {
				println("Notes classes not installed.");
				return
			}
			notesDirs.clear
			notesDirs.add(dir)
			installed = notesDirs.installNotesJar()
		}

	}

	private def static promptNotesJarLocation() {
		val prompt = "What is the full path of Notes.jar? "
		var dir = System::console.readLine(prompt)
		if (dir.nullOrEmpty) {
			return null
		}
		var dir2 = dir.toLowerCase
		if (!dir2.endsWith("notes.jar")) {
			if (!dir2.endsWith("/") || !dir2.endsWith("\\")) {
				dir = dir + "/"
			}
			dir = dir + "Notes.jar"
		}
		dir
	}

	def static private installNotesJar(List<String> notesDirs) {
		println("Locating Notes.jar... ")
		for (dir : notesDirs) {
			val file = new File(dir)
			print(dir + ": ")
			if (file.exists) {
				println("found.")
				print("Extracting classes... ")
				val filesExtracted = file.extractJar()
				println(filesExtracted + " classes extracted.")
				println("Notes classes installed.")
				return true
			} else {
				println("not found.")

			}
		}
		return false
	}

	def static private extractJar(File notesJarFile) {
		var buffer = newByteArrayOfSize(1024)
		val outputDir = new File("classes")
		var jarFile = new ZipInputStream(new FileInputStream(notesJarFile))
		var entry = jarFile.getNextEntry
		var fileCount = 0
		var currentNameLength = 0
		while (entry != null) {
			val name = entry.getName

			//print("\r"+name+" ".times(-name.length))
			print("\b \b".times(currentNameLength) + name)
			currentNameLength = name.length
			var f = new File(outputDir, name)
			f.parentFile.mkdirs

			var outputStream = new FileOutputStream(f)

			var int size;
			while ((size = jarFile.read(buffer)) > 0) {
				outputStream.write(buffer, 0, size)
				outputStream.flush
			}

			outputStream.close
			fileCount = fileCount + 1
			entry = jarFile.nextEntry
		}
		println
		fileCount
	}

}
