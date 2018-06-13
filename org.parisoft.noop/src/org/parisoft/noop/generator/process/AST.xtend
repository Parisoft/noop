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
	
	@Accessors var String container
	
	val tree = new HashMap<String, List<Node>>
	
	def clear(NoopClass c) {
		val prefix = '''«c.fullyQualifiedName.toString».'''
		tree.keySet.removeIf[startsWith(prefix)]
	}
	
	def append(Node node) {
		container.append(node)
	}
	
	def append(String name, Node node) {
		tree.computeIfAbsent(name, [new ArrayList]).add(node)
	}
}