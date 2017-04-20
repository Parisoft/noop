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
		if (context.fullyQualifiedName == TypeSystem::LIB_OBJECT || context.fullyQualifiedName == "Object") {
			return context as NoopClass;
		}

		val desc = context.getVisibleClassesDescriptions.findFirst [
			qualifiedName.toString == TypeSystem::LIB_OBJECT || qualifiedName.toString == "Object"
		]

		if (desc === null) {
			return null
		}

		var o = desc.EObjectOrProxy

		if (o.eIsProxy) {
			o = context.eResource.resourceSet.getEObject(desc.EObjectURI, true)
		}

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
//			println('''«c1.name» isAssignableFrom «c2.name»''')
			return true
		}

		val is = c2.classHierarchy.exists[it == c1]
//		println('''«c1.name» isAssignableFrom «c2.name» ? «is» hierarchy=«c2.classHierarchy»''')
		is
	}

	def isNumber(NoopClass c) {
		c == TypeSystem::TYPE_INT || c == TypeSystem::TYPE_BYTE || c == TypeSystem::TYPE_CHAR || c == TypeSystem::TYPE_UINT
	}
}
