package org.parisoft.noop.generator.process

import java.util.HashMap
import java.util.List
import org.parisoft.noop.noop.NoopClass
import com.google.inject.Inject
import org.eclipse.emf.mwe2.language.scoping.QualifiedNameProvider
import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors

class AST {
	
	@Inject extension QualifiedNameProvider
	
	@Accessors var String project
	@Accessors var volatile String container
	@Accessors var volatile List<NoopClass> types = new ArrayList
	
	val tree = new HashMap<String, List<Node>>
	
	def clear(NoopClass c) {
		val prefix = '''«c.fullyQualifiedName.toString».'''
		tree.keySet.removeIf[startsWith(prefix)]
	}
	
	def append(Node node) {
		container.append(node)
	}
	
	def append(String container, Node node) {
		tree.computeIfAbsent(container, [new ArrayList]).add(node)
	}
	
	def get(String container) {
		tree.get(container)
	}
	
	def contains(String container) {
		tree.containsKey(container)
	}
}