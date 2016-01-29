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
package clenotes.utils

import clenotes.CLENotesSession
import clenotes.CommandLineArguments
import clenotes.Logger
import java.io.File
import java.io.FileWriter
import java.io.PrintWriter
import java.io.Writer
import lotus.domino.Database
import lotus.domino.Document
import lotus.domino.DocumentCollection
import lotus.domino.DxlImporter
import clenotes.ErrorLogger

class DxlUtils {

	private var static importedDXLDBName = "CLENotes_importedDXL_DB.nsf"
	private var static Database importedDXLDB = null

	def static exportDxl(Document doc) {

		//export single document
		var writer = writer
		doc.generateXML(writer)
		endWrite(writer)

	}

	def static exportDxl(DocumentCollection docCollection) {

		//export multiple documents
		var writer = writer

		var Document doc = docCollection.getFirstDocument()
		var Document tmpdoc
		while (doc != null) {
			doc.generateXML(writer)
			tmpdoc = docCollection.getNextDocument()
			doc.recycle();
			doc = tmpdoc;
		}
		docCollection.recycle
		endWrite(writer)

	}

	private def static getWriter() {
		var fileName = CommandLineArguments::getValue("dxl")
		var Writer writer = null
		if (fileName == null) {
			writer = new PrintWriter(System.out)

		} else {
			writer = new FileWriter(new File(fileName))

		}
		writer.write("<?xml version='1.0'?>")
		writer.write(System.getProperty("line.separator"))
		writer.write("<database>")
		writer.write(System.getProperty("line.separator"))
		writer
	}

	private def static endWrite(Writer writer) {

		writer.write("</database>")
		writer.write(System.getProperty("line.separator"))
		writer.close

		var fileName = CommandLineArguments::getValue("dxl")
		if (fileName != null) {
			println("DXL written to: " + fileName)
		}

	}

	def static Database importDxl() {

		var session = CLENotesSession.session

		var fileName = CommandLineArguments::getValue("dxli")
		var f = new File(fileName)

		if (!f.exists) {
			ErrorLogger::error(-104, "File does not exist.")
			return null
		}
		Logger::log("Import DXL from %s", fileName)

		importedDXLDB = session.getDatabase(null, importedDXLDBName)
		if (importedDXLDB.isOpen()) {
			importedDXLDB.remove()
		}
		var dbdir = session.getDbDirectory(null)
		importedDXLDB = dbdir.createDatabase(importedDXLDBName, true)
		importedDXLDB.setTitle("DXL DB")

		// Import DXL from file to new database
		var importer = session.createDxlImporter()
		importer.setReplaceDbProperties(true)
		importer.setReplicaRequiredForReplaceOrUpdate(false)
		importer.inputValidationOption = DxlImporter.DXLVALIDATIONOPTION_VALIDATE_NEVER
		importer.setAclImportOption(DxlImporter.DXLIMPORTOPTION_REPLACE_ELSE_IGNORE)

		importer.setDesignImportOption(DxlImporter.DXLIMPORTOPTION_IGNORE)

		var stream = session.createStream();
		if (!f.isAbsolute) {
			var dir = System.getProperty("user.dir")
			fileName = dir + "/" + fileName

		}
		stream.open(fileName)

		importer.importDxl(stream, importedDXLDB)
		stream.close
		importedDXLDB

	}

	def static deleteImportedDxlDatabase() {
		if (importedDXLDB != null) {
			importedDXLDB.remove

		}
	}

}
