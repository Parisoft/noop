package org.parisoft.noop.generator.process

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.NoopClass
import java.util.LinkedHashMap

class AST {
	
	@Accessors var volatile String container
	@Accessors var volatile List<NoopClass> types = new ArrayList
	
	@Accessors var String project
	@Accessors val vectors = new HashMap<String, String>
	@Accessors val tree = new LinkedHashMap<String, List<Node>>
	
	def clear(String clazz) {
		val prefix = '''«clazz».'''
		tree.keySet.removeIf[startsWith(prefix)]
	}
	
	def append(Node node) {
		container.append(node)
	}
	
	def append(String container, Node node) {
		tree.computeIfAbsent(container, [new ArrayList]) => [
			if (node !== null) {
				add(node)
			}
		]
	}
	
	def get(String container) {
		tree.get(container)
	}
	
	def contains(String container) {
		tree.containsKey(container)
	}
	
	def setReset(String method) {
		vectors.put('reset', method)
	}
	
	def setNmi(String method) {
		vectors.put('nmi', method)
	}
	
	def setIrq(String method) {
		vectors.put('irq', method)
	}
}