package org.parisoft.noop.generator.process

import java.util.ArrayList
import java.util.HashMap
import java.util.LinkedHashMap
import java.util.LinkedHashSet
import java.util.List
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.^extension.TypeSystem
import org.parisoft.noop.generator.alloc.AllocContext
import org.parisoft.noop.generator.compile.MetaClass
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.generator.compile.MetaClass.Size
import java.util.concurrent.atomic.AtomicInteger

class ProcessContext {

	@Accessors val classes = new LinkedHashSet<String> => [TypeSystem::LIB_PRIMITIVES.forEach[t|add(t)]]
	@Accessors val statics = new LinkedHashSet<String>
	@Accessors val constants = new LinkedHashSet<String>
	@Accessors val methods = new LinkedHashSet<String>
	@Accessors val constructors = new LinkedHashSet<String>
	@Accessors val alloc = new AllocContext
	@Accessors val sizeOfClasses = new HashMap<String, Integer>
	@Accessors val structOfClasses = new LinkedHashMap<String, String>
	@Accessors val superClasses = new HashMap<String, List<String>>
	@Accessors val subClasses = new HashMap<String, List<String>>
	@Accessors val directives = new LinkedHashSet<String>
	@Accessors val macros = new HashMap<String, CharSequence>
	@Accessors val headers = new HashMap<StorageType, String>

	@Accessors var AST ast
	@Accessors var Map<String, MetaClass> metaClasses

	def start(String vector) {
		val entry = ast.vectors.get(vector)
		ast.get(entry)?.forEach[process(this)]
	}

	def finish() {
		for (clazz : classes) {
			val s = clazz.calcSize
			sizeOfClasses.put(clazz, s)
			clazz.superClasses.forEach[sizeOfClasses.compute(it, [k, v|if(v === null || v < s) s else v])]
		}

		for (clazz : classes) {
			for (other : classes.filter[it != clazz]) {
				if (other.superClasses.contains(clazz)) {
					subClasses.computeIfAbsent(clazz, [new ArrayList]).add(other)
				}
			}
		}

		classes.forEach [ clazz, i |
			structOfClasses.computeIfAbsent(clazz, [
				'''
					«val offset = new AtomicInteger(1)»
						«clazz».CLASS = «i»
						«clazz».SIZE = «clazz.size»
						«FOR field : clazz.allFields.entrySet»
							«field.key» = «offset.getAndAdd(field.value.size)»
						«ENDFOR»
				'''
			])
		]

		for (clazz : classes) {
			val classHeaders = clazz.metadata?.headers

			if (classHeaders !== null) {
				headers.putAll(classHeaders)

				val mapper = classHeaders.get(StorageType::INESMAPPER)

				if (mapper !== null) {
					directives.add('''inesmap = «mapper»''')
				}
			}
		}

		for (method : methods) {
			for (call : method.calls) {
				if (method.isCalledBy(call)) {
					directives.add('''recursive_«method»_to_«call.methodName» = 1''')
				} else {
					directives.add('''recursive_«method»_to_«call.methodName» = 0''')
				}
			}
		}

		for (method : methods) {
			val dot = method.lastIndexOf('.')
			val containerClass = method.substring(0, dot)
			val methodName = method.substring(dot + 1)

			if (methodName.isNonStatic) {
				val overriders = containerClass.subClasses.filter [ sub |
					val overrideName = '''«sub».«methodName»'''
					sub.metadata?.methods.values.exists[containsKey(overrideName)]
				].toList

				if (overriders.size > 0) {
					val params = ast.get(method)?.filter(NodeVar).filter[param].toList ?: emptyList
					val ret = ast.get(method)?.filter(NodeVar).findFirst[varName.endsWith('.ret')]
					val call = containerClass.getPolymorphicCall(methodName, overriders, params, ret)
					macros.put('''call_«method»''', call)
				} else {
					macros.put('''call_«method»''', '''	JSR «method»''')
				}
			} else if (containerClass.isInline(methodName)) {
				methods.remove(method)
				macros.put('''call_«method»''', containerClass.metadata.macros.get(method))
			}
		}
	}

	private def int calcSize(String clazz) {
		switch (clazz) {
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
				return 1 + clazz.allFields.values.map[size].sum
			}
		}
	}
	
	private def sum(Iterable<Integer> ints) {
		ints.reduce[a, b|a + b] ?: 0
	}

	private def getSize(String clazz) {
		sizeOfClasses.get(clazz) ?: 1
	}

	private def getSize(Size size) {
		size.qty * (sizeOfClasses.get(size.type) ?: size.type.calcSize)
	}

	private def getAllFields(String clazz) {
		val fields = new LinkedHashMap<String, Size>

		for (supr : clazz.superClasses.reverse) {
			for (field : (supr.metadata?.fields ?: emptyMap).entrySet) {
				val fieldName = field.key.substring(field.key.lastIndexOf('.') + 1)

				if (fields.keySet.forall[fieldName != it.substring(it.lastIndexOf('.') + 1)]) {
					fields.put(field.key, field.value)
				}
			}
		}

		fields
	}

	private def getSubClasses(String clazz) {
		subClasses.get(clazz) ?: emptyList
	}

	private def getSuperClasses(String clazz) {
		superClasses.get(clazz) ?: emptyList
	}

	private def getMetadata(String clazz) {
		metaClasses.get(clazz)
	}

	private def Iterable<NodeCall> getCalls(String entry) {
		ast.get(entry)?.map [
			switch (it) {
				NodeCall: newArrayList(it)
				NodeBeginStmt: statementName.calls
				default: emptyList
			}
		].flatten
	}

	private def boolean isCalledBy(String method, NodeCall node) {
		node.methodName == method || node.methodName.calls.exists[method.isCalledBy(it)]
	}

	private def isNonStatic(String method) {
		!method.startsWith('_$') && !method.startsWith('$')
	}

	private def isInline(String clazz, String method) {
		clazz.metadata?.macros.containsKey('''«clazz».«method»''')
	}

	private def getPolymorphicCall(String clazz, String method, List<String> overriders, List<NodeVar> params,
		NodeVar ret) '''
		«noop»
			LDY #0
			LDA («clazz».«method».rcv), Y
		«FOR overrider : overriders»
			+	CMP #«overrider».CLASS
				BEQ ++
				JMP +
			++	LDA «clazz».«method».rcv + 0
				STA «overrider».«method».rcv + 0
				LDA «clazz».«method».rcv + 1
				STA «overrider».«method».rcv + 1
			«FOR param : params»
				«val overrideParam = param.varName.replaceFirst(clazz, overrider)»
				«IF param.ptr»
					«noop»
						LDA «param.varName» + 0
						STA «overrideParam» + 0
						LDA «param.varName» + 1
						STA «overrideParam» + 1
				«ELSE»
					i = 0
						.rept «param.type».SIZE
						LDA «param.varName» + i
						STA «overrideParam» + i
					i = i + 1
						.endr
				«ENDIF»
			«ENDFOR»
			«noop»
				JSR «overrider».«method»
			«IF ret !== null»
				«val overrideRet = ret.varName.replaceFirst(clazz, overrider)»
				«IF ret.ptr»
					«noop»
						LDA «overrideRet» + 0
						STA «ret.varName» + 0
						LDA «overrideRet» + 1
						STA «ret.varName» + 1
				«ELSE»
					i = 0
						.rept «ret.type».SIZE
						LDA «overrideRet» + i
						STA «ret.varName» + i
					i = i + 1
						.endr
				«ENDIF»
			«ENDIF»
			«noop»
				JMP +invocation.end
		«ENDFOR»
		+	JSR «clazz».«method»
		+invocation.end:
	'''

	private def void noop() {
	}
}
