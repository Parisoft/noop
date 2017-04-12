package org.parisoft.noop.^extension

import org.eclipse.emf.ecore.EObject
import org.parisoft.noop.noop.NoopClass

import static extension org.eclipse.xtext.EcoreUtil2.*
import com.google.inject.Inject
import org.parisoft.noop.scoping.NoopIndex

class Classes {

	@Inject extension NoopIndex

	def static classHierarchy(NoopClass c) {
		val visited = <NoopClass>newArrayList()
		var current = c.superClass

		while(current != null && !visited.contains(current)) {
			visited.add(current)
			current = current.superClass
		}

		visited
	}

	def static containingClass(EObject e) {
		e.getContainerOfType(NoopClass)
	}

	def isSubclassOf(NoopClass c1, NoopClass c2) {
		c1.classHierarchy.contains(c2)
	}

	def getSuperClassOrObject(NoopClass c) {
		c.superClass ?: getNoopObjectClass(c)
	}

	def getNoopObjectClass(EObject context) {
		val desc = context.getVisibleClassesDescriptions.findFirst[qualifiedName.toString == TypeSystem::LIB_OBJECT]

		if(desc == null)
			return null

		var o = desc.EObjectOrProxy

		if(o.eIsProxy)
			o = context.eResource.resourceSet.getEObject(desc.EObjectURI, true)

		o as NoopClass
	}

}
