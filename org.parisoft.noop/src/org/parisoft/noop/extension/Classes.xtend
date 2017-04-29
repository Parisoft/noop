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
import org.parisoft.noop.scoping.NoopIndex

class Classes {

	@Inject extension NoopIndex
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
		c.superClass ?: getNoopObjectClass(c)
	}

	def getNoopObjectClass(EObject context) {
		context.objectType
//		if (context instanceof NoopClass && (context as NoopClass).is(TypeSystem::TYPE_OBJECT)) {
//			return context as NoopClass;
//		}
//		
//		val desc = context.getVisibleClassesDescriptions.findFirst[qualifiedName.toString == TypeSystem::LIB_OBJECT]
//
//		if (desc === null) {
//			return null
//		}
//
//		var o = desc.EObjectOrProxy
//
//		if (o.eIsProxy) {
//			o = context.eResource.resourceSet.getEObject(desc.EObjectURI, true)
//		}
//
//		o as NoopClass
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
		if (c1.isNumber && c2.isNumber) {
			return true
		}

		c2.classHierarchy.exists[it.is(c1)]
	}

	def isNumber(NoopClass c) {
		c.is(TypeSystem::TYPE_INT) || c.is(TypeSystem::TYPE_BYTE) || c.is(TypeSystem::TYPE_UBYTE) || c.is(TypeSystem::TYPE_UINT)
	}

	def is(NoopClass c1, NoopClass c2) {
		c1.fullyQualifiedName == c2.fullyQualifiedName
	}
}
