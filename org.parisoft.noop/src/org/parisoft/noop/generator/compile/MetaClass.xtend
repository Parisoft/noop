package org.parisoft.noop.generator.compile

import java.util.HashMap
import java.util.LinkedHashMap
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.StorageType

class MetaClass {
	
	@Accessors var String superClass
	@Accessors var String constructor
	@Accessors var Map<Integer, Map<String, String>> prgRoms = new LinkedHashMap
	@Accessors var Map<Integer, Map<String, String>> chrRoms = new LinkedHashMap
	@Accessors var Map<String, String> constants = new LinkedHashMap
	@Accessors var Map<String, Static> statics = new LinkedHashMap
	@Accessors var Map<String, Size> fields = new LinkedHashMap
	@Accessors var Map<Integer, Map<String, String>> methods = new LinkedHashMap
	@Accessors var Map<String, String> macros = new LinkedHashMap
	@Accessors var Map<String, String> vectors = new HashMap
	@Accessors var Map<StorageType, String> headers = new HashMap
	
	static class Size {
		@Accessors var int qty
	    @Accessors var String type
	}
	
	static class Static {
		@Accessors var String asm
		@Accessors var Size size
	}
}