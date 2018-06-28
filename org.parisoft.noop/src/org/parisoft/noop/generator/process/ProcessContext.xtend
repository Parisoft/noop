package org.parisoft.noop.generator.process

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.LinkedHashMap
import java.util.LinkedHashSet
import java.util.List
import java.util.Map
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.^extension.TypeSystem
import org.parisoft.noop.generator.alloc.AllocContext
import org.parisoft.noop.generator.compile.MetaClass
import org.parisoft.noop.generator.compile.MetaClass.Size
import org.parisoft.noop.noop.StorageType

class ProcessContext {

	@Accessors val processing = new HashSet<String>
	@Accessors val classes = new LinkedHashSet<String> => [addAll(TypeSystem::LIB_PRIMITIVES)]
	@Accessors val statics = new LinkedHashSet<String>
	@Accessors val constants = new LinkedHashSet<String>
	@Accessors val methods = new LinkedHashSet<String>
	@Accessors val methodsByBank = new HashMap<Integer, Map<String, String>>
	@Accessors val constructors = new LinkedHashSet<String>
	@Accessors val prgRoms = new HashMap<Integer, Map<String, String>>
	@Accessors val chrRoms = new HashMap<Integer, Map<String, String>>
	@Accessors val dmcRoms = new HashMap<Integer, Map<String, String>>
	@Accessors val allocation = new AllocContext
	@Accessors val sizeOfClasses = new HashMap<String, Integer>
	@Accessors val structOfClasses = new LinkedHashMap<String, String>
	@Accessors val superClasses = new HashMap<String, List<String>>
	@Accessors val subClasses = new HashMap<String, List<String>>
	@Accessors val directives = newLinkedHashSet('''	min EQU (b + ((a - b) & ((a - b) >> «Integer.BYTES» * 8 - 1)))''')
	@Accessors val macros = new HashMap<String, CharSequence>
	@Accessors val headers = new HashMap<StorageType, Object>

	@Accessors var AST ast
	@Accessors var Map<String, MetaClass> metaClasses

	def begin() {
		for (meta : metaClasses.entrySet) {
			superClasses.computeIfAbsent(meta.key, [
				val supers = new ArrayList
				var supr = meta.value

				do {
					supr = metaClasses.get(supr.superClass)
				} while (supr !== null && supers.add(supr.name))

				supers
			])
		}

		for (clazz : metaClasses.keySet) {
			for (other : metaClasses.keySet.filter[it != clazz]) {
				if (other.superClasses.contains(clazz)) {
					subClasses.computeIfAbsent(clazz, [new ArrayList]).add(other)
				}
			}
		}
	}

	def process(String vector) {
		val entry = ast.vectors.get(vector)
		ast.get(entry)?.forEach[node|node.process(this)]
	}

	def finish() {
		val missingClasses = new HashSet(classes) => [
			removeAll(metaClasses.keySet)
			removeAll(TypeSystem::LIB_PRIMITIVES)
		]

		if (missingClasses.size > 0) {
			throw new NoopClassNotFoundException
		}
		
		for (headers : metaClasses.values.map[it.headers]) {
			this.headers.putAll(headers)
		}
		
		for (header : headers.values) {
			constants.add(header.toString)
		}

		for (static : statics) {
			ast.get(static)?.forEach[process(this)]
		}
		
		for (static : statics) {
			val clazz = static.substring(0, static.lastIndexOf('.'))
			val asm = clazz.metadata?.statics?.get(static)

			if (asm !== null) {
				macros.compute('instantiate_statics', [ k, v |
					(v ?: '') + asm + System::lineSeparator
				])
			}
		}

		for (const : constants.toList) {
			ast.get(const)?.forEach[process(this)]
		}

		for (clazz : classes) {
			val s = clazz.calcSize
			sizeOfClasses.put(clazz, s)
			clazz.superClasses.forEach[sizeOfClasses.compute(it, [k, v|if(v === null || v < s) s else v])]
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

		for (meta : classes.map[metadata].filterNull) {
			meta.prgRoms.forEach[bank, roms|
				prgRoms.computeIfAbsent(bank, [new LinkedHashMap]).putAll(roms)
			]
			
			meta.chrRoms.forEach[bank, roms|
				chrRoms.computeIfAbsent(bank, [new LinkedHashMap]).putAll(roms)
			]
			
			meta.dmcRoms.forEach[bank, roms|
				dmcRoms.computeIfAbsent(bank, [new LinkedHashMap]).putAll(roms)
			]
		}
		
//		for (method : methods) {
//			for (call : method.calls) {
//				if (method.isCalledBy(call)) {
//					directives.add('''recursive_«method»_to_«call.methodName» = 1''')
//				} else {
//					directives.add('''recursive_«method»_to_«call.methodName» = 0''')
//				}
//			}
//		}
		for (method : methods) {
			val dot = method.lastIndexOf('.')
			val containerClass = method.substring(0, dot)
			val methodName = method.substring(dot + 1)

			if (containerClass.isInline(method)) {
				macros.put('''call_«method»''', containerClass.metadata.macros.get(method))
			} else if (methodName.isStatic) {
				macros.put('''call_«method»''', '''	JSR «method»''')
			} else {
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
			}
		}

		for (clazz : classes) {
			for (methodByBank : clazz.metadata?.methods?.entrySet ?: emptySet) {
				for (entry : methodByBank.value.entrySet.filter[methods.contains(key)]) {
					methodsByBank.computeIfAbsent(methodByBank.key, [new HashMap]).put(entry.key, entry.value)
				}
			}
		}

		for (vector : ast.vectors.values) {
			val containerClass = vector.substring(0, vector.lastIndexOf('.'))

			containerClass.metadata?.vectors?.forEach [ name, asm |
				methodsByBank.computeIfAbsent(null, [new HashMap]).put(name, asm)
			]
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
		val fields = new LinkedHashMap(clazz.metadata?.fields ?: emptyMap)

		for (supr : clazz.superClasses.clone.reverse) {
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

	private def isStatic(String method) {
		method.startsWith('_$') || method.startsWith('$')
	}

	private def isInline(String clazz, String method) {
		clazz.metadata?.macros?.containsKey(method)
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
