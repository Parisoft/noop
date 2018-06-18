package org.parisoft.noop.generator.compile

import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashMap
import java.util.Map
import java.util.LinkedHashMap

class MetaClass {
	
	@Accessors var String superClass
	@Accessors var String constructor
	@Accessors var Map<Integer, Map<String, String>> prgRoms = new LinkedHashMap
	@Accessors var Map<Integer, Map<String, String>> chrRoms = new LinkedHashMap
	@Accessors var Map<String, String> constants = new LinkedHashMap
	@Accessors var Map<String, String> statics = new LinkedHashMap
	@Accessors var Map<String, Size> fields = new LinkedHashMap
	@Accessors var Map<Integer, Map<String, String>> methods = new LinkedHashMap
	@Accessors var Map<String, String> vectors = new HashMap
	@Accessors var Map<String, String> headers = new HashMap
	
	static class Size {
		@Accessors var int qty
	    @Accessors var String type
	}
}