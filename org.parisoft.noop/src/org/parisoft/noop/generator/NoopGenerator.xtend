/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.generator

import com.google.inject.Inject
import com.google.inject.Provider
import java.io.PrintStream
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.consoles.Console
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Datas
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Files
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.^extension.Statements
import org.parisoft.noop.noop.NoopClass

import static org.parisoft.noop.generator.Asm8.*

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class NoopGenerator extends AbstractGenerator {

	@Inject extension Files
	@Inject extension Classes
	@Inject extension Members
	@Inject extension Statements
	@Inject extension Collections
	@Inject extension Expressions
	@Inject extension IQualifiedNameProvider

	@Inject Provider<Console> console

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val asm = resource.compile

		if (asm !== null) {
			fsa.generateFile(asm.asmFileName, asm.content)
			fsa.deleteFile(asm.binFileName)

			new Asm8 => [
				Asm8.outStream = new PrintStream(console.get.newOutStream, true)
				Asm8.errStream = new PrintStream(console.get.newErrStream, true)

				inputFileName = fsa.getURI(asm.asmFileName).toFile.absolutePath
				outputFileName = fsa.getURI(asm.binFileName).toFile.absolutePath
				listFileName = fsa.getURI(asm.lstFileName).toFile.absolutePath

				try {
					compile
				} catch (Exception exception) {
					Asm8.errStream.println(exception.message)
					throw exception
				}
			]
		}
	}

	private def compile(Resource resource) {
		val mainClass = resource.contents.filter(NoopClass).findFirst[main]

		if (mainClass === null) {
			return null
		}

		val ctx = mainClass.prepare

		mainClass.alloc(ctx)

		ctx.prgRoms.entrySet.removeIf[ctx.prgRoms.values.exists[rom|rom.isOverrideOf(value)]]
		ctx.chrRoms.entrySet.removeIf[ctx.chrRoms.values.exists[rom|rom.isOverrideOf(value)]]

		val content = ctx.compile.optimize

		new ASM(mainClass.name, content)
	}

	private def optimize(CharSequence code) {
		val lines = code.toString.split(System::lineSeparator)
		val builder = new StringBuilder
		val AtomicInteger skip = new AtomicInteger

		lines.forEach [ line, i |
			var next = if(i + 1 < lines.length) lines.get(i + 1) else ''

			if (skip.get > 0) {
				skip.decrementAndGet
			} else if (line == '\tPLA' && next == '\tPHA') {
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
			} else if (line == System::lineSeparator) {
				while (next == System::lineSeparator) {
					next = lines.get(i + 1 + skip.incrementAndGet)
				}

				builder.append(line)
			} else {
				builder.append(line).append(System::lineSeparator)
			}
		]

		builder.toString
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
			«val offsets = noopClass.allFieldsTopDown.filter[nonStatic].toMap([it], [offset.getAndAdd(sizeOf)])»
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
			«cons.nameOfConstant» = «cons.value.compileConstant»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Static variables
		;----------------------------------------------------------------
		«FOR page : 0..< ctx.counters.size»
			«IF ctx.resetCounter(page) == 0»«noop»«ENDIF»
		«ENDFOR»
		«FOR page : 0..< ctx.counters.size»
			«val staticVars = ctx.statics.values.filter[storageOf == page]»
			«FOR staticVar : staticVars»
				«staticVar.nameOfStatic» = «ctx.counters.get(page).getAndAdd(staticVar.sizeOf).toHexString(4)»
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
			.db «inesMap.toHexString» | «inesMir.toHexString»
			.dsb 9, $00 ;clear the remaining bytes to 16
			
		;----------------------------------------------------------------
		; PRG-ROM Bank(s)
		;----------------------------------------------------------------
			.base $10000 - («(inesPrg / 16).toHexString» * $4000) 
		
		«FOR rom : ctx.prgRoms.values.filter[nonDMC]»
			«rom.compile(new CompileContext)»
		«ENDFOR»
		«IF ctx.methods.values.exists[objectSize] && ctx.constructors.size > 0»
			Object.$sizes:
				.db «ctx.constructors.values.sortBy[type.name].map[type.rawSizeOf].join(', ', [toHexString])»
		«ENDIF»
		
		;-- Methods -----------------------------------------------------
		«FOR method : ctx.methods.values.sortBy[fullyQualifiedName]»
			«method.compile(new CompileContext => [allocation = ctx])»
			
		«ENDFOR»
		;-- Constructors ------------------------------------------------
		«FOR constructor : ctx.constructors.values.sortBy[type.name]»
			«constructor.compile(null)»
			
		«ENDFOR»
		«val dmcList = ctx.prgRoms.values.filter[DMC].toList»
		«IF dmcList.isNotEmpty»
			;-- DMC sound data-----------------------------------------------
				.org «Members::FT_DPCM_OFF»
			«FOR dmcRom : dmcList»
				«dmcRom.compile(new CompileContext)»
			«ENDFOR»
		«ENDIF»
		
		;----------------------------------------------------------------
		; Interrupt vectors
		;----------------------------------------------------------------
			.org $FFFA     
		
		 	.dw «ctx.methods.values.findFirst[nmi]?.nameOf ?: 0»
		 	.dw «ctx.methods.values.findFirst[reset]?.nameOf ?: 0»
		 	.dw «ctx.methods.values.findFirst[irq]?.nameOf ?: 0»
		
		;----------------------------------------------------------------
		; CHR-ROM bank(s)
		;----------------------------------------------------------------
		   .base $0000
		
		«FOR rom : ctx.chrRoms.values»
			«rom.compile(new CompileContext)»
		«ENDFOR»
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
