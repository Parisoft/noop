/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.generator

import com.google.inject.Inject
import com.google.inject.Provider
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.util.ArrayList
import java.util.HashMap
import java.util.Map
import java.util.NoSuchElementException
import java.util.concurrent.CompletableFuture
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.core.resources.IProject
import org.eclipse.core.runtime.FileLocator
import org.eclipse.core.runtime.Platform
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.parisoft.noop.consoles.Console
import org.parisoft.noop.^extension.Cache
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Files
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.^extension.TypeSystem
import org.parisoft.noop.generator.alloc.MemChunk
import org.parisoft.noop.generator.compile.MetaClass
import org.parisoft.noop.generator.mapper.MapperFactory
import org.parisoft.noop.generator.mapper.Mmc3
import org.parisoft.noop.generator.process.AST
import org.parisoft.noop.generator.process.NodeCall
import org.parisoft.noop.generator.process.NoopClassNotFoundException
import org.parisoft.noop.generator.process.ProcessContext
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.StorageType

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.parisoft.noop.^extension.Datas.*

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class NoopGenerator extends AbstractGenerator {

	@Inject extension Files
	@Inject extension Classes
	@Inject extension Members
	@Inject extension TypeSystem

	@Inject Provider<Console> console
	@Inject MapperFactory mapperFactory

	static val astByProject = new HashMap<String, AST>
	static val classesByProject = new HashMap<String, Map<String, MetaClass>>
	static val assembler = new File( // TODO open from jar
	FileLocator::getBundleFile(
		Platform::getBundle("org.parisoft.noop")), '''/asm/asm6_«Platform::OS»_«Platform::OSArch»''')

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val ini = System::currentTimeMillis
		val clazz = resource.allContents.filter(NoopClass).head
		val project = clazz.URI.project

		project.preProcess(clazz)
		project.preCompile(clazz)

		try {
			project.process(clazz).alloc.compile(clazz).optimize.assembly(project, fsa)
		} catch (NoopClassNotFoundException e) {
		}

		println('''«clazz.fullName» Took:«System::currentTimeMillis - ini»ms''')
	}

	private def preProcess(IProject project, NoopClass clazz) {
		val ast = astByProject.computeIfAbsent(project.name, [new AST => [it.project = project.name]]) => [
			clear(clazz.fullName)
		]

		clazz.preProcess(ast)

		val classes = classesByProject.getOrDefault(project.name, emptyMap)

		ast.externalClasses.map[superClasses].flatten.filter[!classes.containsKey(fullName)].forEach [ ext |
			ext.preProcess(ast)
		]
	}

	private def preCompile(IProject project, NoopClass clazz) {
		val classes = classesByProject.computeIfAbsent(project.name, [new HashMap])
		val ast = astByProject.get(project.name)

		classes.put(clazz.fullName, clazz.preCompile)

		ast.externalClasses.map[superClasses].flatten.filter[!classes.containsKey(fullName)].forEach [ ext |
			classes.put(ext.fullName, ext.preCompile)
		]
	}

	private def process(IProject project, NoopClass clazz) {
		val ast = astByProject.get(project.name)
		val classes = classesByProject.get(project.name)
		val ctx = new ProcessContext => [
			it.ast = ast
			it.metaClasses = classes
		]

		ctx.begin
		ctx.process("reset")
		ctx.process("nmi")
		ctx.process("irq")
		ctx.finish
		ctx
	}

	private def alloc(ProcessContext ctx) {
		ctx.allocation => [
			it.ast = ctx.ast
			it.subClasses = ctx.subClasses
			it.sizeOfClasses = ctx.sizeOfClasses
		]

		val chunks = new ArrayList<MemChunk>
		chunks += ctx.allocation.computePtr(Members::TEMP_VAR_NAME1)
		chunks += ctx.allocation.computePtr(Members::TEMP_VAR_NAME2)
		chunks += ctx.allocation.computePtr(Members::TEMP_VAR_NAME3)

		for (static : ctx.statics) {
			for (node : ctx.ast.get(static) ?: emptyList) {
				chunks += node.alloc(ctx.allocation)
			}
		}

		chunks += 'nmi'.alloc(ctx)
		chunks += 'irq'.alloc(ctx)
		chunks += 'reset'.alloc(ctx)

		ctx
	}

	private def alloc(String vector, ProcessContext ctx) {
		val method = ctx.ast.vectors.get(vector)

		val chunks = if (method !== null) {
				(new NodeCall => [methodName = method]).alloc(ctx.allocation)
			} else {
				emptyList
			}

		ctx.allocation.counters.forEach [ counter, page |
			try {
				counter.set(chunks.filter[lo >= page * 0x100 && hi < (page + 1) * 0x100].maxBy[hi].hi + 1)
			} catch (NoSuchElementException e) {
			}
		]

		chunks
	}

	private def compile(ProcessContext ctx, NoopClass clazz) '''
		;----------------------------------------------------------------
		; Class Metadata
		;----------------------------------------------------------------
		«FOR struct : ctx.structOfClasses.values»
			«struct»
			
		«ENDFOR»
		;----------------------------------------------------------------
		; Constant variables
		;----------------------------------------------------------------
		«Members::TRUE» = 1
		«Members::FALSE» = 0
		«Members::FT_DPCM_OFF» = $C000
		«Members::FT_DPCM_PTR» = («Members::FT_DPCM_OFF»&$3fff)>>6
		«FOR cons : ctx.constants»
			«cons» = «ctx.metaClasses.get(cons.substring(0, cons.lastIndexOf('.')))?.constants?.get(cons) ?: 0»
		«ENDFOR»
		min EQU (b + ((a - b) & ((a - b) >> «Integer.BYTES» * 8 - 1)))
		
		;----------------------------------------------------------------
		; Static variables
		;---------------------------------------------------------------
		«FOR chunk : (ctx.allocation.pointers.values + ctx.allocation.variables.values).flatten.sort.filter[ctx.statics.contains(variable)]»
			«chunk.variable» = «chunk.lo.toHexString(4)»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Local variables
		;----------------------------------------------------------------
		«FOR chunk : (ctx.allocation.pointers.values + ctx.allocation.variables.values).flatten.sort.filter[!ctx.statics.contains(variable)]»
			«chunk.variable» = «chunk.lo.toHexString(4)»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; iNES Header
		;----------------------------------------------------------------
			.db 'NES', $1A ;identification of the iNES header
			.db «(ctx.headers.get(StorageType::INESPRG)?: 32)» / 16 ;number of 16KB PRG-ROM pages
			.db «(ctx.headers.get(StorageType::INESCHR)?: 08)» / 08 ;number of 8KB CHR-ROM pages
			.db «(ctx.headers.get(StorageType::INESMAP)?: 0)» | «ctx.headers.get(StorageType::INESMIR)?: 1»
			.dsb 9, $00 ;clear the remaining bytes to 16
		«clazz.convert(ctx.headers)»
		«(mapperFactory.get(ctx.headers.get(StorageType::INESMAP) as Integer ?: 0) as Mmc3).compile(ctx)»
	'''

	private def assembly(String code, IProject project, IFileSystemAccess2 fsa) {
		val mainClass = astByProject.get(project.name).mainClass

		if (mainClass !== null) {
			val asmFileName = '''«mainClass».asm'''
			val binFileName = '''«mainClass».bin'''
			val lstFileName = '''«mainClass».lst'''

			fsa.generateFile(asmFileName, code)
			fsa.deleteFile(binFileName)

			if (assembler?.exists) {
				assembler.executable = true

				val ini = System::currentTimeMillis
				val inputFileName = fsa.getURI(asmFileName).toFile.absolutePath
				val outputFileName = fsa.getURI(binFileName).toFile.absolutePath
				val listFileName = fsa.getURI(lstFileName).toFile.absolutePath
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

	private def void convert(NoopClass c, Map<StorageType, Object> headers) {
		for (header : headers.entrySet) {
			val const = header.value.toString
			val clazz = const.substring(0, const.lastIndexOf('.'))
			val value = c.toClassOrDefault(clazz, null).declaredConstants.findFirst[nameOf == const].valueOf
			header.value = value
		}
	}

	private def toHexString(int value, int len) {
		var string = Integer.toHexString(value).toUpperCase

		while (string.length < len) {
			string = '0' + string
		}

		return '$' + string
	}

}
