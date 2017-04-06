package com.github.parisoft.noop.typing

import com.github.parisoft.noop.NOOPLib
import com.github.parisoft.noop.nOOP.SJClass
import com.github.parisoft.noop.util.NOOPUtils
import com.google.inject.Inject
import org.eclipse.xtext.naming.IQualifiedNameProvider

import static com.github.parisoft.noop.typing.NOOPTypeComputer.*

class NOOPTypeConformance {
	
	@Inject extension NOOPUtils
	@Inject extension IQualifiedNameProvider

	def isConformant(SJClass c1, SJClass c2) {
		c1 === NULL_TYPE || // null can be assigned to everything
		c1 === c2 || c2.fullyQualifiedName.toString == NOOPLib.LIB_OBJECT || conformToLibraryTypes(c1, c2) ||
			c1.isSubclassOf(c2)
	}

	def conformToLibraryTypes(SJClass c1, SJClass c2) {
		(c1.conformsToString && c2.conformsToString) || (c1.conformsToInt && c2.conformsToInt) ||
			(c1.conformsToBoolean && c2.conformsToBoolean)
	}

	def conformsToString(SJClass c) {
		c == STRING_TYPE || c.fullyQualifiedName.toString == NOOPLib.LIB_STRING
	}

	def conformsToInt(SJClass c) {
		c == INT_TYPE || c.fullyQualifiedName.toString == NOOPLib.LIB_INTEGER
	}

	def conformsToBoolean(SJClass c) {
		c == BOOLEAN_TYPE || c.fullyQualifiedName.toString == NOOPLib.LIB_BOOLEAN
	}

	def isSubclassOf(SJClass c1, SJClass c2) {
		c1.classHierarchy.contains(c2)
	}
}
