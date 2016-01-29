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
package clenotes.utils.extensions

/*
 * Generic extension methods.
 */
class ExtensionMethods {

	/*
	 * Extension method to String. For a given string, returns string multplied by
	 * itself for n times
	 */
	static def times(String str, int n) {
		var i = -1
		var StringBuffer sb = new StringBuffer
		while ((i = i + 1) < n) {
			sb.append(str)
		}
		return sb.toString
	}

	static def ljust(String str, int width) {
		var _str = str
		var len = str.length
		if (len < width) {
			_str = str + " ".times(width - len)

		}
		_str
	}


	static def isInteger(String str) {
		var isInteger=false
		try
		{
			Integer::parseInt(str)
			isInteger=true
		}
		catch(NumberFormatException e)
		{
			
		}
		return isInteger
	}

}
