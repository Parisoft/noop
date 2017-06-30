package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.Collection
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*

class Classes {

	static val int SIZE_OF_CLASS_TYPE = 1;

	@Inject extension Members
	@Inject extension TypeSystem
	@Inject extension IQualifiedNameProvider

	def classHierarchy(NoopClass c) {
		val visited = <NoopClass>newArrayList()
		var current = c

		while (current !== null && !visited.contains(current)) {
			visited.add(current)
			current = current.superClassOrObject
		}

		visited
	}

	def containingClass(EObject e) {
		e.getContainerOfType(NoopClass)
	}

	def isSubclassOf(NoopClass c1, NoopClass c2) {
		c1.classHierarchy.contains(c2)
	}

	def getSuperClassOrObject(NoopClass c) {
		if (c === null || c.fullyQualifiedName?.toString == TypeSystem::LIB_PRIMITIVE || c.fullyQualifiedName?.toString == TypeSystem::LIB_VOID) {
			null
		} else {
			c.superClass ?: c.toObjectClass
		}
	}

	def merge(Collection<NoopClass> classes) {
		val hierarchies = classes.map[it.classHierarchy]

		hierarchies.reduce [ h1, h2 |
			h1.retainAll(h2)
			h1
		]?.head ?: TypeSystem::TYPE_VOID
	}

	def fields(NoopClass c) {
		c.members.filter(Variable)
	}

	def methods(NoopClass c) {
		c.members.filter(Method)
	}

	def inheritedFields(NoopClass c) {
		c.classHierarchy.map[members].flatten.filter(Variable)
	}

	def inheritedMethods(NoopClass c) {
		c.classHierarchy.map[members].flatten.filter(Method)
	}

	def isInstanceOf(NoopClass c1, NoopClass c2) {
		if (c1.isNumeric && c2.isNumeric) {
			return true
		}

		val className = c2.fullyQualifiedName

		return c1.classHierarchy.exists[it.fullyQualifiedName == className]
	}

	def isNumeric(NoopClass c) {
		try {
			c.classHierarchy.exists[it.fullyQualifiedName.toString == TypeSystem::LIB_INT]
		} catch (Exception exception) {
			false
		}
	}

	def isBoolean(NoopClass c) {
		try {
			c.fullyQualifiedName.toString == TypeSystem::LIB_BOOL
		} catch (Exception exception) {
			false
		}
	}

	def isGame(NoopClass c) {
		try {
			c.fullyQualifiedName.toString != TypeSystem::LIB_GAME && c.classHierarchy.exists [
				it.fullyQualifiedName.toString == TypeSystem::LIB_GAME
			]
		} catch (Exception exception) {
			false
		}
	}

	def isSingleton(NoopClass c) {
		try {
			c.fullyQualifiedName.toString != TypeSystem::LIB_SINGLETON && c.classHierarchy.exists [
				it.fullyQualifiedName.toString == TypeSystem::LIB_SINGLETON
			]
		} catch (Exception exception) {
			false
		}
	}

	def defaultValueOf(NoopClass c) {
		if (c.isNumeric) {
			0
		} else if (c.isBoolean) {
			false
		} else {
			c
		}
	}

	def int sizeOf(NoopClass c) {
		switch (c.fullyQualifiedName.toString) {
			case TypeSystem::LIB_BYTE:
				1
			case TypeSystem::LIB_SBYTE:
				1
			case TypeSystem::LIB_BOOL:
				1
			case TypeSystem::LIB_INT:
				2
			case TypeSystem::LIB_UINT:
				2
			default: {
				c.fields.filter[nonConstant].map[sizeOf].reduce [ v1, v2 |
					v1 + v2
				] ?: 0 + SIZE_OF_CLASS_TYPE
			}
		}
	}

}
