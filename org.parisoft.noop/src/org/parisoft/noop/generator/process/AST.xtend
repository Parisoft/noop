package org.parisoft.noop.generator.process

import java.util.ArrayList
import java.util.HashMap
import java.util.LinkedHashMap
import java.util.LinkedHashSet
import java.util.List
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.NoopClass
import java.util.Objects

class AST {
	
	@Accessors var volatile String container
	@Accessors var volatile List<NoopClass> types = new ArrayList
	@Accessors var volatile Set<NoopClass> externalClasses = new LinkedHashSet
	
	@Accessors var String project
	@Accessors var String mainClass
	@Accessors val vectors = new HashMap<String, String>
	@Accessors val tree = new LinkedHashMap<String, List<Node>>
	
	def clear(String clazz) {
		val prefix = '''«clazz».'''
		tree.keySet.removeIf[startsWith(prefix)]
		externalClasses.clear
	}
	
	def append(Node node) {
		container.append(node)
	}
	
	def append(String container, Node node) {
		tree.computeIfAbsent(Objects::requireNonNull(container), [new ArrayList]) => [
			if (node !== null) {
				add(node)
			}
		]
	}
	
	def get(String container) {
		tree.get(container) ?: emptyList
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