package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.Collection
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.NoopInstance
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*

class Classes {

	static val int SIZE_OF_CLASS_TYPE = 1;

	@Inject extension Members
	@Inject extension Statements
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
		classes.map [
			it.classHierarchy
		].reduce [ h1, h2 |
			h1.retainAll(h2)
			h1
		]?.head ?: TypeSystem::TYPE_VOID
	}

	def declaredFields(NoopClass c) {
		c.members.filter(Variable)
	}

	def declaredMethods(NoopClass c) {
		c.members.filter(Method)
	}

	def allFieldsBottomUp(NoopClass c) {
		c.classHierarchy.map[members].flatten.filter(Variable)
	}

	def allMethodsBottomUp(NoopClass c) {
		c.classHierarchy.map[members].flatten.filter(Method)
	}

	def allFieldsTopDown(NoopClass c) {
		c.classHierarchy.reverse.map[members].flatten.filter(Variable)
	}

	def allMethodsTopDown(NoopClass c) {
		c.classHierarchy.reverse.map[members].flatten.filter(Method)
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

	def isVoid(NoopClass c) {
		try {
			c.fullyQualifiedName.toString == TypeSystem::LIB_VOID
		} catch (Exception exception) {
			false
		}
	}

	def isNonVoid(NoopClass c) {
		!c.isVoid
	}

	def isPrimitive(NoopClass c) {
		try {
			c.classHierarchy.exists[it.fullyQualifiedName.toString == TypeSystem::LIB_PRIMITIVE]
		} catch (Exception exception) {
			false
		}
	}

	def isNonPrimitive(NoopClass c) {
		!c.isPrimitive
	}

	def isGame(NoopClass c) {
		try {
			c.classHierarchy.exists [
				it.fullyQualifiedName.toString == TypeSystem::LIB_GAME
			]
		} catch (Exception exception) {
			false
		}
	}

	def isNonGame(NoopClass c) {
		!c.isGame
	}

	def isINESHeader(NoopClass c) {
		try {
			c.classHierarchy.exists [
				it.fullyQualifiedName.toString == TypeSystem::LIB_NES_HEADER
			]
		} catch (Exception exception) {
			false
		}
	}

	def isNonINESHeader(NoopClass c) {
		!c.isINESHeader
	}

	def defaultValueOf(NoopClass c) {
		if (c.isNumeric) {
			0
		} else if (c.isBoolean) {
			false
		} else {
			new NoopInstance(c.name, c.allFieldsBottomUp)
		}
	}

	def asmName(NoopClass c) {
		'''«c.name».class'''.toString
	}

	def int sizeOf(NoopClass c) {
		switch (c.fullyQualifiedName.toString) {
			case TypeSystem::LIB_VOID:
				0
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
				SIZE_OF_CLASS_TYPE + (c.allFieldsTopDown.filter[nonStatic].map[sizeOf].reduce [ s1, s2 |
					s1 + s2
				] ?: 0)
			}
		}
	}

	def prepare(NoopClass gameImplClass) {
		val gameClass = gameImplClass.classHierarchy.findLast[game]
		val gameInstance = NoopFactory::eINSTANCE.createVariable => [
			name = '''«Members::STATIC_PREFIX»instance'''
			value = NoopFactory::eINSTANCE.createNewInstance => [type = gameImplClass]
		]
		val mainInvocation = NoopFactory::eINSTANCE.createMemberSelection => [
			receiver = NoopFactory::eINSTANCE.createMemberRef => [member = gameInstance]
			member = gameImplClass.allMethodsBottomUp.findFirst[main]
		]
		val data = new AllocData

		gameClass.allMethodsBottomUp.findFirst[reset].body.statements += mainInvocation
		gameImplClass.members += gameInstance
		gameImplClass.prepare(data)

		return data
	}

	def void prepare(NoopClass noopClass, AllocData data) {
		if (data.classes.add(noopClass)) {
			noopClass.allFieldsTopDown.filter[static].forEach[prepare(data)]

			if (noopClass.isGame) {
				noopClass.allMethodsBottomUp.findLast[reset].prepare(data)
				noopClass.allMethodsBottomUp.findFirst[main].prepare(data)
				noopClass.allMethodsBottomUp.findFirst[nmi].prepare(data)
			}
		}
	}

	def void alloc(NoopClass noopClass, AllocData data) {
		if (noopClass.isGame) {
			data.statics.forEach[alloc(data)]
			
			noopClass.allMethodsBottomUp.findLast[reset].alloc(data)
			noopClass.allMethodsBottomUp.findFirst[main].alloc(data)
			noopClass.allMethodsBottomUp.findFirst[nmi].alloc(data)
		}
	}

	def update(Method reset, NoopClass gameImplClass) {
		val gameConstructor = NoopFactory::eINSTANCE.createNewInstance => [type = gameImplClass]
		val gameInstance = NoopFactory::eINSTANCE.createVariable => [
			name = Members::STATIC_PREFIX + gameImplClass.name.toFirstLower
			value = gameConstructor
		]

		reset.body.statements += gameInstance
		reset
	}

}
