/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.generator

import com.google.inject.Inject
import com.google.inject.Provider
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.util.concurrent.CompletableFuture
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.core.runtime.FileLocator
import org.eclipse.core.runtime.Platform
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.parisoft.noop.consoles.Console
import org.parisoft.noop.^extension.Cache
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Datas
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Files
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.^extension.Variables
import org.parisoft.noop.generator.mapper.MapperFactory
import org.parisoft.noop.noop.NoopClass
import java.util.HashMap
import org.parisoft.noop.generator.process.AST
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.^extension.Methods

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class NoopGenerator extends AbstractGenerator {

	@Inject extension Files
	@Inject extension Classes
	@Inject extension Members
	@Inject extension Methods
	@Inject extension Variables
	@Inject extension Expressions

	@Inject Provider<Console> console
	@Inject MapperFactory mapperFactory

	static val astByProject = new HashMap<String, AST>
	static val assembler = new File( // TODO open from jar
	FileLocator::getBundleFile(Platform::getBundle("org.parisoft.noop")), '''/asm/asm6«Platform.OS»''')

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		if (fsa !== null) {
			val ini = System::currentTimeMillis
			val clazz = resource.allContents.filter(NoopClass).head
			val project = clazz.URI.project.name
			val ast = astByProject.computeIfAbsent(project, [new AST => [it.project = project]])
			
			ast.clear(clazz.fullName)
			clazz.declaredMethods.forEach[preProcess(ast)]
			
			ast.tree.forEach[root, nodes|
				println('''-> «root»''')
				nodes.forEach[
					println('''	«it»''')
				]
			]
			
			println(ast.vectors)
			
			println('''Took:«System::currentTimeMillis - ini»ms''')
			
			//if ast.vectors !== null ast.vectors.forEach[preCompile]
			
			return
		}

		// from here, all legacy code 
		val asm = resource.compile

		if (asm !== null) {
			fsa.generateFile(asm.asmFileName, asm.content)
			fsa.deleteFile(asm.binFileName)

			if (assembler?.exists) {
				assembler.executable = true

				val ini = System::currentTimeMillis
				val inputFileName = fsa.getURI(asm.asmFileName).toFile.absolutePath
				val outputFileName = fsa.getURI(asm.binFileName).toFile.absolutePath
				val listFileName = fsa.getURI(asm.lstFileName).toFile.absolutePath
				val command = '''«assembler.absolutePath» -l «inputFileName» «outputFileName» «listFileName»'''

				try {
					val proc = Runtime::runtime.exec(command)

					CompletableFuture::runAsync [
						val out = console.get.newOutStream
						new BufferedReader(new InputStreamReader(proc.inputStream)).lines.forEach [
							out.write(it.bytes)
							out.write('\n'.bytes)
						]
					]

					CompletableFuture::runAsync [
						val err = console.get.newErrStream
						new BufferedReader(new InputStreamReader(proc.errorStream)).lines.forEach [
							err.write(it.bytes)
							err.write('\n'.bytes)
						]
					]

					proc.waitFor
				} finally {
					println('''Assembly = «System::currentTimeMillis - ini»ms''')
					Cache::clear
				}
			}
		}
	}

	private def compile(Resource resource) {
		val mainClass = resource.contents.filter(NoopClass).findFirst[main]

		if (mainClass === null) {
			return null
		}

		var ini = System::currentTimeMillis
		val ctx = mainClass.prepare
		println('''RePrepare = «System::currentTimeMillis - ini»ms''')

		ini = System::currentTimeMillis
		mainClass.alloc(ctx)
		println('''Alloc = «System::currentTimeMillis - ini»ms''')

		ctx.prgRoms.entrySet.removeIf[ctx.prgRoms.values.exists[rom|rom.isOverrideOf(value)]]
		ctx.chrRoms.entrySet.removeIf[ctx.chrRoms.values.exists[rom|rom.isOverrideOf(value)]]

		ini = System::currentTimeMillis
		val code = ctx.compile
		println('''Compile = «System::currentTimeMillis - ini»ms''')

		ini = System::currentTimeMillis
		val content = code.optimize
		println('''Optimize = «System::currentTimeMillis - ini»ms''')

		new ASM(mainClass.name, content)
	}

	private def String optimize(CharSequence code) {
		val lines = code.toString.split(System::lineSeparator)
		val builder = new StringBuilder
		val AtomicInteger skip = new AtomicInteger
		val AtomicBoolean skipped = new AtomicBoolean(false)

		lines.forEach [ line, i |
			var next = if(i + 1 < lines.length) lines.get(i + 1) else ''

			if (skip.get > 0) {
				skip.decrementAndGet
				skipped.set(true)
			} else if (line == '\tPHA' && next == '\tPLA') {
				skip.set(1)
			} else if ((line.startsWith('\tJMP') || line.startsWith('\tRTS')) &&
				(next.startsWith('\tJMP') || next.startsWith('\tRTS'))) {
				while (next.startsWith('\tJMP') || next.startsWith('\tRTS')) {
					next = lines.get(i + 1 + skip.incrementAndGet)
				}

				builder.append(line).append(System::lineSeparator)
			} else if (line.startsWith('\tJSR') && next.startsWith('\tRTS')) {
				while (next.startsWith('\tRTS')) {
					next = lines.get(i + 1 + skip.incrementAndGet)
				}

				builder.append('''	JMP «line.substring(5)»''').append(System::lineSeparator)
			} else if (line.startsWith('\tLDA')) {
				val src = line.substring(line.indexOf('LDA') + 3).trim

				if (next.startsWith('\tSTA') && src == next.substring(next.indexOf('STA') + 3).trim) {
					skip.incrementAndGet
				} else {
					builder.append(line).append(System::lineSeparator)
				}
			} else if (line.startsWith('\tSTA')) {
				val dst = line.substring(line.indexOf('STA') + 3).trim

				if (next.startsWith('\tLDA') && dst == next.substring(next.indexOf('LDA') + 3).trim) {
					skip.incrementAndGet
				}

				builder.append(line).append(System::lineSeparator)
			} else if (line == System::lineSeparator && next == System::lineSeparator) {
				skip.incrementAndGet
				builder.append(line)
			} else {
				builder.append(line).append(System::lineSeparator)
			}
		]

		if (skipped.get) {
			builder.toString.optimize
		} else {
			builder.toString
		}
	}

	private def compile(AllocContext ctx) '''
		;----------------------------------------------------------------
		; Class Metadata
		;----------------------------------------------------------------
		«var classCount = 0»
		«val classes = ctx.classes.values.filter[nonPrimitive].sortWith[a, b|
			val aHasConstructor = ctx.constructors.containsKey(a.nameOf)
			val bHasConstructor = ctx.constructors.containsKey(b.nameOf)
			
			if (aHasConstructor && !bHasConstructor) {
				return -1 //don't know why this works inverted ... should be 1 instead
			}
			
			if (!aHasConstructor && bHasConstructor) {
				return 1 //don't know why this works inverted ... should be -1 instead
			}
			
			return a.name.compareTo(b.name)
		]»
		«FOR noopClass : classes»
			«noopClass.nameOf» = «classCount++»
			«val offset = new AtomicInteger(1)»
			«val offsets = noopClass.allFieldsTopDown.filter[nonStatic].toMap([it], [offset.getAndAdd(sizeOf as Integer)])»
			«FOR field : noopClass.declaredFields.filter[nonStatic]»
				«field.nameOfOffset» = «offsets.get(field)»
			«ENDFOR»
			
		«ENDFOR»
		;----------------------------------------------------------------
		; Constant variables
		;----------------------------------------------------------------
		«Members::TRUE» = 1
		«Members::FALSE» = 0
		«Members::FT_DPCM_OFF» = $C000
		«Members::FT_DPCM_PTR» = («Members::FT_DPCM_OFF»&$3fff)>>6
		«FOR cons : ctx.constants.values»
			«cons.nameOf» = «cons.value.compileConstant»
		«ENDFOR»
		min EQU (b + ((a - b) & ((a - b) >> «Integer.BYTES» * 8 - 1)))
		
		;----------------------------------------------------------------
		; Static variables
		;----------------------------------------------------------------
		«FOR page : 0..< ctx.counters.size»
			«IF ctx.resetCounter(page) == 0»«noop»«ENDIF»
		«ENDFOR»
		«FOR page : 0..< ctx.counters.size»
			«val staticVars = ctx.statics.values.filter[(storageOf ?: 0) == page]»
			«FOR staticVar : staticVars»
				«staticVar.nameOf» = «ctx.counters.get(page).getAndAdd(staticVar.sizeOf as Integer).toHexString(4)»
			«ENDFOR»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Local variables
		;----------------------------------------------------------------
		«Members::TEMP_VAR_NAME1» = «ctx.counters.get(Datas::PTR_PAGE).getAndAdd(2).toHexString(4)»
		«Members::TEMP_VAR_NAME2» = «ctx.counters.get(Datas::PTR_PAGE).getAndAdd(2).toHexString(4)»
		«Members::TEMP_VAR_NAME3» = «ctx.counters.get(Datas::PTR_PAGE).getAndAdd(2).toHexString(4)»
		«val zpDelta = ctx.counters.get(Datas::PTR_PAGE).get»
		«FOR zpChunk : ctx.pointers.values.flatten.sort»
			«zpChunk.shiftTo(zpDelta)»
		«ENDFOR»
		«val varDelta = ctx.counters.drop(Datas::VAR_PAGE).map[get].reduce[c1, c2| c1 + c2] - 0x1600»
		«FOR varChunk : ctx.variables.values.flatten.sort»
			«varChunk.shiftTo(varDelta)»
		«ENDFOR»
		«FOR chunk : ctx.pointers.values.flatten.sort + ctx.variables.values.flatten.sort»
			«chunk.variable» = «chunk.lo.toHexString(4)»
		«ENDFOR»
		
		«val inesPrg = ctx.constants.values.findFirst[INesPrg]?.valueOf as Integer ?: 32»
		«val inesChr = ctx.constants.values.findFirst[INesChr]?.valueOf as Integer ?: 8»
		«val inesMap = ctx.constants.values.findFirst[INesMapper]?.valueOf as Integer ?: 0»
		«val inesMir = ctx.constants.values.findFirst[INesMir]?.valueOf as Integer ?: 1»
		;----------------------------------------------------------------
		; iNES Header
		;----------------------------------------------------------------
			.db 'NES', $1A ;identification of the iNES header
			.db «(inesPrg / 16).toHexString» ;number of 16KB PRG-ROM pages
			.db «(inesChr / 8).toHexString» ;number of 8KB CHR-ROM pages
			.db «inesMap.toHexString(1)»0 | «inesMir.toHexString»
			.dsb 9, $00 ;clear the remaining bytes to 16
			
		«mapperFactory.get(inesMap)?.compile(ctx)»
	'''

	private def toHexString(int value) {
		value.toHexString(2)
	}

	private def toHexString(int value, int len) {
		var string = Integer.toHexString(value).toUpperCase

		while (string.length < len) {
			string = '0' + string
		}

		return '$' + string
	}

	private def void noop() {
	}
}
