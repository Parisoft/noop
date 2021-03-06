package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.ArrayList
import java.util.Collection
import java.util.List
import java.util.NoSuchElementException
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable

import static org.parisoft.noop.^extension.Cache.*

import static extension org.eclipse.xtext.EcoreUtil2.*

class Classes {

	static val int SIZE_OF_CLASS_TYPE = 1;

	@Inject extension Members
	@Inject extension Statements
	@Inject extension TypeSystem
	@Inject extension Collections
	@Inject extension IQualifiedNameProvider

	static val allocating = ConcurrentHashMap::<NoopClass>newKeySet

	def getSuperClasses(NoopClass c) {
		val visited = <NoopClass>newArrayList()
		var current = c

		if (current?.eIsProxy) {
			current = current.resolve
		}

		while (current !== null && !visited.contains(current)) {
			visited.add(current)
			current = current.superClassOrObject

			if (current?.eIsProxy) {
				current = current.resolve
			}
		}

		visited
	}

	def getSubClasses(NoopClass c) {
		classes.filter[isNotEquals(c)].filter[isInstanceOf(c)]
	}

	def getContainerClass(EObject e) {
		e.getContainerOfType(NoopClass)
	}

	def isSubclassOf(NoopClass c1, NoopClass c2) {
		c1.superClasses.exists[isEquals(c2)]
	}

	def isNonSubclassOf(NoopClass c1, NoopClass c2) {
		!c1.isSubclassOf(c2)
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

	def List<Variable> getDeclaredFields(NoopClass c) {
		val fields = c.members.filter(Variable)
		(fields.filter[static] + fields.filter[nonStatic]).toList
	}

	def getDeclaredMethods(NoopClass c) {
		c.members.filter(Method).toList
	}

	def getAllFieldsBottomUp(NoopClass c) {
		val fields = c.superClasses.map[new ArrayList(members).reverse].flatten.filter(Variable)
		(fields.filter[nonStatic] + fields.filter[static]).toList
	}

	def getAllMethodsBottomUp(NoopClass c) {
		c.superClasses.map[new ArrayList(members).reverse].flatten.filter(Method).toList
	}

	def getAllFieldsTopDown(NoopClass c) {
		val fields = c.superClasses.reverse.map[members].flatten.filter(Variable)
		(fields.filter[static] + fields.filter[nonStatic]).toList
	}

	def getAllMethodsTopDown(NoopClass c) {
		c.superClasses.reverse.map[members].flatten.filter(Method).toList
	}

	def isEquals(NoopClass c1, NoopClass c2) {
		c1 == c2 || c1.fullyQualifiedName.toString == c2.fullyQualifiedName.toString
	}

	def isNotEquals(NoopClass c1, NoopClass c2) {
		!c1.isEquals(c2)
	}

	def isInstanceOf(NoopClass c1, NoopClass c2) {
		if (c1.isNumeric && c2.isNumeric) {
			true
		} else {
			c1.isSubclassOf(c2)
		}
	}

	def isNonInstanceOf(NoopClass c1, NoopClass c2) {
		!c1.isInstanceOf(c2)
	}

	def isNumeric(NoopClass c) {
		TypeSystem::LIB_NUMBERS.contains(c.fullyQualifiedName?.toString)
	}

	def isNonNumeric(NoopClass c) {
		!c.isNumeric
	}

	def isBoolean(NoopClass c) {
		c.fullyQualifiedName.toString == TypeSystem::LIB_BOOL
	}

	def isNonBoolean(NoopClass c) {
		!c.isBoolean
	}

	def isVoid(NoopClass c) {
		c.fullyQualifiedName.toString == TypeSystem::LIB_VOID
	}

	def isNonVoid(NoopClass c) {
		!c.isVoid
	}

	def isObject(NoopClass c) {
		c.fullyQualifiedName.toString == TypeSystem::LIB_OBJECT
	}

	def isPrimitive(NoopClass c) {
		c.superClasses.exists[it.fullyQualifiedName.toString == TypeSystem::LIB_PRIMITIVE]
	}

	def isNonPrimitive(NoopClass c) {
		!c.isPrimitive
	}

	def isMain(NoopClass c) {
		c.allMethodsBottomUp.exists[reset]
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
		}
	}

	def nameOf(NoopClass c) {
		'''«c.name»#class'''.toString
	}

	def int sizeOf(NoopClass c) {
		classeSize.get(c, [c.fullSizeOf])
	}

	private def int fullSizeOf(NoopClass c) {
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
			default:
				(newArrayList(c.rawSizeOf) + c.subClasses.map[rawSizeOf]).max
		}
	}

	def int rawSizeOf(NoopClass c) {
		SIZE_OF_CLASS_TYPE + (c.allFieldsTopDown.filter[nonStatic].map[sizeOf].reduce [ s1, s2 |
			s1 + s2
		] ?: 0)
	}

	def prepare(NoopClass gameImplClass) {
		contexts.get(gameImplClass, [
			val ctx = new AllocContext

			TypeSystem::context.set(gameImplClass)

			gameImplClass.prepare(ctx)

			val overriders = new ArrayList<Method>

			do {
				ctx.classes.putAll(ctx.classes.values.map[superClasses].flatten.toMap[nameOf])

				classes.clear
				classes.addAll(ctx.classes.values)

				overriders.clear
				overriders += prepared.filter(Method).filter[nonStatic].map[it.overriders].flatten.filter [
					!prepared.contains(it)
				].toList

				overriders.forEach[it.prepare(ctx)]
			} while (overriders.isNotEmpty)

			classeSize.clear
			ctx.classes.values.forEach[sizeOf]

			ctx
		])
	}

	def void prepare(NoopClass noopClass, AllocContext ctx) {
		if (ctx.classes.put(noopClass.nameOf, noopClass) === null) {
			noopClass.allFieldsTopDown.filter[ROM].forEach[prepare(ctx)]
			noopClass.allFieldsTopDown.filter[INesHeader].forEach[prepare(ctx)]
			noopClass.allFieldsTopDown.filter[mapperConfig].forEach[prepare(ctx)]
			noopClass.allMethodsBottomUp.findFirst[reset]?.prepare(ctx)
			noopClass.allMethodsBottomUp.findFirst[nmi]?.prepare(ctx)
			noopClass.allMethodsBottomUp.findFirst[irq]?.prepare(ctx)
		}
	}

	def void alloc(NoopClass noopClass, AllocContext ctx) {
		if (allocating.add(noopClass)) {
			try {
				allocated.get(noopClass, [
					if (noopClass.isMain) {
						ctx.statics.values.forEach[alloc(ctx)]
					}

					val chunks = noopClass.allMethodsBottomUp.findFirst[nmi]?.alloc(ctx) ?: newArrayList

					ctx.counters.forEach [ counter, page |
						try {
							counter.set(chunks.filter[lo >= page * 0x100 && hi < (page + 1) * 0x100].maxBy[hi].hi + 1)
						} catch (NoSuchElementException e) {
						}
					]

					chunks += noopClass.allMethodsBottomUp.findFirst[irq]?.alloc(ctx) ?: emptyList

					ctx.counters.forEach [ counter, page |
						try {
							counter.set(chunks.filter[lo >= page * 0x100 && hi < (page + 1) * 0x100].maxBy[hi].hi + 1)
						} catch (NoSuchElementException e) {
						}
					]

					noopClass.allMethodsBottomUp.findFirst[reset]?.alloc(ctx)
				])
			} finally {
				allocating.remove(noopClass)
			}
		}
	}

}
