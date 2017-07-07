package org.parisoft.noop.generator

import org.parisoft.noop.noop.Constructor
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*

class NoopInstance {

	private val String className;
	private val Iterable<Variable> fields;

	new(String className, Iterable<Variable> fields) {
		this(className, fields, null)
	}

	new(String className, Iterable<Variable> fields, Constructor constructor) {
		this.className = className

		this.fields = fields.map[copy] ?: emptyList

		this.fields.forEach [ field |
			field.value = constructor?.field.findFirst[it.name == field.name]?.value ?: field.value
		]
	}

	def getClassName() {
		className
	}

	def getFields() {
		fields
	}

	override toString() '''
		«className»{}
	'''

}
