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


class ErrorLogger {

	private var static _errorCode = 0
	private var static _defaultErrorCode = -99

	def static getErrorCode() {
		_errorCode
	}

	def static setErrorCode(int errorCode) {
		_errorCode = errorCode
	}

	def static error(String message) {
		error(_defaultErrorCode,message)
	}

	def static error(int errorCode, String message) {
		setErrorCode(errorCode)
		var msg = String.format("[ERROR] %s", message)
		Logger::log("(%d) %s", errorCode, msg)
		println(msg)
	}

}
