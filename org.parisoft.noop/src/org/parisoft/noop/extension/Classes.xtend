package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.Collection
import java.util.NoSuchElementException
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.NoopInstance
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*

class Classes {

	static val int SIZE_OF_CLASS_TYPE = 1;

	@Inject extension Members
	@Inject extension Statements
	@Inject extension TypeSystem
	@Inject extension IQualifiedNameProvider

	val classeSizeCache = <NoopClass, Integer>newHashMap
	val classesCache = <NoopClass>newArrayList

	def getSuperClasses(NoopClass c) {
		val visited = <NoopClass>newArrayList()
		var current = c

		if (current?.eIsProxy) {
			try {
				current = current.eResource.resourceSet.getEObject(current.URI, true) as NoopClass
			} catch (Exception exception) {
				return visited
			}
		}

		while (current !== null && !visited.contains(current)) {
			visited.add(current)
			current = current.superClassOrObject

			if (current?.eIsProxy) {
				try {
					current = current.eResource.resourceSet.getEObject(current.URI, true) as NoopClass
				} catch (Exception exception) {
					current = null
				}
			}
		}

		visited
	}

	def getSubClasses(NoopClass c) {
		classesCache.filter[it != c].filter[isInstanceOf(c)]
	}

	def getContainerClass(EObject e) {
		e.getContainerOfType(NoopClass)
	}

	def isSubclassOf(NoopClass c1, NoopClass c2) {
		c1.superClasses.contains(c2)
	}

	def getSuperClassOrObject(NoopClass c) {
		if (c === null || c.fullyQualifiedName?.toString == TypeSystem::LIB_PRIMITIVE ||
			c.fullyQualifiedName?.toString == TypeSystem::LIB_VOID) {
			null
		} else {
			c.superClass ?: c.toObjectClass
		}
	}

	def merge(Collection<NoopClass> classes) {
		if (classes.isEmpty) {
			TypeSystem::TYPE_VOID
		} else if (classes.forall[isNumeric]) {
			classes.reduce [ c1, c2 |
				if (c1.sizeOf > c2.sizeOf) {
					c1
				} else if (c1.sizeOf < c2.sizeOf) {
					c2
				} else if (c1.isSigned) {
					c1
				} else {
					c2
				}
			]
		} else {
			classes.map [
				superClasses
			].reduce [ h1, h2 |
				h1.removeIf [ c1 |
					!h2.exists[c2|c1.fullyQualifiedName.toString == c2.fullyQualifiedName.toString]
				]
				h1
			]?.head ?: TypeSystem::TYPE_VOID
		}
	}

	def getDeclaredFields(NoopClass c) {
		c.members.filter(Variable)
	}

	def getDeclaredMethods(NoopClass c) {
		c.members.filter(Method)
	}

	def getAllFieldsBottomUp(NoopClass c) {
		c.superClasses.map[members].flatten.filter(Variable)
	}

	def getAllMethodsBottomUp(NoopClass c) {
		c.superClasses.map[members].flatten.filter(Method)
	}

	def getAllFieldsTopDown(NoopClass c) {
		c.superClasses.reverse.map[members].flatten.filter(Variable)
	}

	def getAllMethodsTopDown(NoopClass c) {
		c.superClasses.reverse.map[members].flatten.filter(Method)
	}
	
	def isEquals(NoopClass c1, NoopClass c2) {
		c1.fullyQualifiedName.toString == c2.fullyQualifiedName.toString
	}

	def isInstanceOf(NoopClass c1, NoopClass c2) {
		if (c1.isNumeric && c2.isNumeric) {
			return true
		}

		val className = c2.fullyQualifiedName

		return c1.superClasses.exists[it.fullyQualifiedName == className]
	}

	def isNumeric(NoopClass c) {
		TypeSystem::LIB_NUMBERS.contains(c.fullyQualifiedName?.toString)
	}

	def isBoolean(NoopClass c) {
		c.fullyQualifiedName.toString == TypeSystem::LIB_BOOL
	}

	def isVoid(NoopClass c) {
		c.fullyQualifiedName.toString == TypeSystem::LIB_VOID
	}

	def isNonVoid(NoopClass c) {
		!c.isVoid
	}

	def isPrimitive(NoopClass c) {
		c.superClasses.exists[it.fullyQualifiedName.toString == TypeSystem::LIB_PRIMITIVE]
	}

	def isNonPrimitive(NoopClass c) {
		!c.isPrimitive
	}

	def isGame(NoopClass c) {
		c.superClasses.exists[it.fullyQualifiedName.toString == TypeSystem::LIB_GAME]
	}

	def isNonGame(NoopClass c) {
		!c.isGame
	}

	def isINESHeader(NoopClass c) {
		c.superClasses.exists[it.fullyQualifiedName.toString == TypeSystem::LIB_NES_HEADER]
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

	def nameOf(NoopClass c) {
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
		classeSizeCache.computeIfAbsent(c, [rawSizeOf])
	}

	def prepare(NoopClass gameImplClass) {
		val ctx = new AllocContext

		gameImplClass.prepare(ctx)

		classeSizeCache.clear

		ctx.classes.putAll(ctx.classes.values.map[superClasses].flatten.toMap[nameOf])
		ctx.classes.values.forEach [ class1 |
			if (class1.isPrimitive) {
				classeSizeCache.put(class1, class1.rawSizeOf)
			} else {
				classeSizeCache.put(class1, ctx.classes.values.filter [ class2 |
					class2.isInstanceOf(class1)
				].map [
					rawSizeOf
				].max)
			}
		]

		classesCache.clear
		classesCache += ctx.classes.values

		return ctx
	}

	def void prepare(NoopClass noopClass, AllocContext ctx) {
		if (ctx.classes.put(noopClass.nameOf, noopClass) === null) {
			noopClass.allFieldsTopDown.filter[ROM].forEach[prepare(ctx)]

			if (noopClass.isGame) {
				noopClass.allFieldsBottomUp.findFirst[typeOf.INESHeader].prepare(ctx)
				noopClass.allMethodsBottomUp.findFirst[reset].prepare(ctx)
				noopClass.allMethodsBottomUp.findFirst[nmi].prepare(ctx)
				noopClass.allMethodsBottomUp.findFirst[irq].prepare(ctx)
			}
		}
	}

	def void alloc(NoopClass noopClass, AllocContext ctx) {
		if (noopClass.isGame) {
			ctx.statics.values.forEach[alloc(ctx)]

			val chunks = noopClass.allMethodsBottomUp.findFirst[nmi].alloc(ctx)

			ctx.counters.forEach [ counter, page |
				try {
					counter.set(chunks.filter[hi < (page + 1) * 256].maxBy[hi].hi + 1)
				} catch (NoSuchElementException e) {
				}
			]

			chunks += noopClass.allMethodsBottomUp.findFirst[irq].alloc(ctx)

			ctx.counters.forEach [ counter, page |
				try {
					counter.set(chunks.filter[hi < (page + 1) * 256].maxBy[hi].hi + 1)
				} catch (NoSuchElementException e) {
				}
			]

			noopClass.allMethodsBottomUp.findFirst[reset].alloc(ctx)
		}
	}

}
