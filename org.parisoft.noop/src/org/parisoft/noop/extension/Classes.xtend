package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.Collection
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*

class Classes {

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
		c.superClass ?: c.toObjectClass
	}

	def merge(Collection<NoopClass> classes) {
		if (classes.isEmpty || classes.contains(TypeSystem::TYPE_VOID)) {
			return TypeSystem::TYPE_VOID
		}

		val hierarchies = <List<NoopClass>>newArrayList()

		classes.forEach[hierarchies += it.classHierarchy]

		return hierarchies.reduce[h1, h2|h1.retainAll(h2); h1].head
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

	def isAssignableFrom(NoopClass c1, NoopClass c2) {
		if (c1.isNumeric && c2.isNumeric) {
			return true
		}

		val className = c1.fullyQualifiedName

		return c2.classHierarchy.exists[it.fullyQualifiedName == className]
	}

	def isNumeric(NoopClass c) {
		try {
			val className = c.fullyQualifiedName

			return className == c.toIntClass.fullyQualifiedName || className == c.toByteClass.fullyQualifiedName ||
				className == c.toUByteClass.fullyQualifiedName || className == c.toUIntClass.fullyQualifiedName
		} catch (Exception exception) {
			return false
		}
	}
	
	def isBoolean(NoopClass c) {
		try {
			return  c.fullyQualifiedName == c.toBoolClass.fullyQualifiedName
		} catch (Exception exception) {
			return false
		}
	}

}
