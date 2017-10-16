package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.Collection
import java.util.Map
import java.util.NoSuchElementException
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.NoopInstance
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*

class Classes {

	static val int SIZE_OF_CLASS_TYPE = 1;
	static val ThreadLocal<Map<NoopClass, Integer>> classeSizeCache = ThreadLocal::withInitial[newHashMap]

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
			classHierarchy
		].reduce [ h1, h2 |
			h1.removeIf[c1|!h2.exists[c2|c1.fullyQualifiedName.toString == c2.fullyQualifiedName.toString]]
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

	def isSigned(NoopClass c) {
		switch (c.fullyQualifiedName.toString) {
			case TypeSystem::LIB_SBYTE: true
			case TypeSystem::LIB_INT: true
			default: false
		}
	}

	def isUnsigned(NoopClass c) {
		!c.isSigned
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

	def int rawSizeOf(NoopClass c) {
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
			case TypeSystem::LIB_PRIMITIVE:
				2
			default: {
				SIZE_OF_CLASS_TYPE + (c.allFieldsTopDown.filter[nonStatic].map[rawSizeOf].reduce [ s1, s2 |
					s1 + s2
				] ?: 0)
			}
		}
	}

	def int sizeOf(NoopClass c) {
		classeSizeCache.get.computeIfAbsent(c, [rawSizeOf])
	}

	def prepare(NoopClass gameImplClass) {
		val data = new AllocData

		gameImplClass.prepare(data)

		classeSizeCache.get.clear

		data.classes += data.classes.map[classHierarchy].flatten.toSet
		data.classes.forEach [ class1 |
			if (class1.isPrimitive) {
				classeSizeCache.get.put(class1, class1.rawSizeOf)
			} else {
				classeSizeCache.get.put(class1, data.classes.filter [ class2 |
					class2.isInstanceOf(class1)
				].map [
					rawSizeOf
				].max)
			}
		]

		return data
	}

	def void prepare(NoopClass noopClass, AllocData data) {
		if (data.classes.add(noopClass)) {
			noopClass.allFieldsTopDown.filter[static].forEach[prepare(data)]

			if (noopClass.isGame) {
				noopClass.allMethodsBottomUp.findFirst[reset].prepare(data)
				noopClass.allMethodsBottomUp.findFirst[nmi].prepare(data)
				noopClass.allMethodsBottomUp.findFirst[irq].prepare(data)
			}
		}
	}

	def void alloc(NoopClass noopClass, AllocData data) {
		if (noopClass.isGame) {
			data.statics.forEach[alloc(data)]

			val chunks = noopClass.allMethodsBottomUp.findFirst[nmi].alloc(data)
			
			try {
				data.ptrCounter.set(chunks.filter[hi < 0x0200].maxBy[hi].hi + 1)
			} catch (NoSuchElementException e) {
			}

			try {
				data.varCounter.set(chunks.filter[hi > 0x0200].maxBy[hi].hi + 1)
			} catch (NoSuchElementException e) {
			}
			
			chunks += noopClass.allMethodsBottomUp.findFirst[irq].alloc(data)

			try {
				data.ptrCounter.set(chunks.filter[hi < 0x0200].maxBy[hi].hi + 1)
			} catch (NoSuchElementException e) {
			}

			try {
				data.varCounter.set(chunks.filter[hi > 0x0200].maxBy[hi].hi + 1)
			} catch (NoSuchElementException e) {
			}
			
			noopClass.allMethodsBottomUp.findFirst[reset].alloc(data)
		}
	}

}
