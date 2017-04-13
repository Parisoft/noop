package org.parisoft.noop.^extension

import org.eclipse.emf.ecore.EObject
import org.parisoft.noop.noop.NoopClass

import static extension org.eclipse.xtext.EcoreUtil2.*
import com.google.inject.Inject
import org.parisoft.noop.scoping.NoopIndex
import java.util.List
import java.util.Collection
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.noop.Method

class Classes {

	@Inject extension NoopIndex
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
		c.superClass ?: getNoopObjectClass(c)
	}

	def getNoopObjectClass(EObject context) {
		if (context.fullyQualifiedName == TypeSystem::LIB_OBJECT) {
			return context as NoopClass;
		}

		val desc = context.getVisibleClassesDescriptions.findFirst [
			qualifiedName.toString == TypeSystem::LIB_OBJECT || qualifiedName.toString == "Object"
		]

		if (desc == null)
			return null

		var o = desc.EObjectOrProxy

		if (o.eIsProxy)
			o = context.eResource.resourceSet.getEObject(desc.EObjectURI, true)

		o as NoopClass
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
		c.members.filter(Variable).filter[it.type === null]
	}

	def methods(NoopClass c) {
		c.members.filter(Method)
	}
}
