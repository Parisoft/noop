/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.generator

import com.google.inject.Inject
import java.util.Objects
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.resource.IResourceDescriptions
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Datas
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Files
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.^extension.Statements
import org.parisoft.noop.^extension.TypeSystem
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopPackage

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
	@Inject IResourceDescriptions descriptions

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val asm = resource.compile

		if (asm !== null) {
			fsa.generateFile(asm.asmFileName, asm.content)

			val asmFile = fsa.getURI(asm.asmFileName).toFile
			val binFile = fsa.getURI(asm.binFileName).toFile
			val lstFile = fsa.getURI(asm.lstFileName).toFile
			println(asmFile)
			println(binFile)
			println(lstFile)
		}
	}

	private def compile(Resource resource) {
		val gameImpl = resource.gameClass

		if (gameImpl === null) {
			return null
		}

		val data = gameImpl.prepare
		gameImpl.alloc(data)
		val content = data.compile.optimize

		new ASM(gameImpl.name, content)
	}

	private def optimize(CharSequence code) {
		val lines = code.toString.split(System::lineSeparator)
		val builder = new StringBuilder

		lines.forEach [ line, i |
			val pushPull = line == '\tPHA' && lines.get(i - 1) == '\tPLA'
			val pullPush = line == '\tPLA' && lines.get(i + 1) == '\tPHA'
			val rtsAfterJsr = line.startsWith('\tRTS') && lines.get(i - 1).startsWith('\tJSR')
			val jsrBeforeRts = line.startsWith('\tJSR') && lines.get(i + 1).startsWith('\tRTS')

			if (jsrBeforeRts) {
				builder.append('''	JMP «line.substring(4)»''').append(System::lineSeparator)
			} else if (!(pushPull || pullPush || rtsAfterJsr)) {
				builder.append(line).append(System::lineSeparator)
			}
		]

		builder.toString
	}

	private def gameClass(Resource resource) {
		val uri = resource.URI?.trimSegments(1)

		val games = descriptions.allResourceDescriptions.map [
			getExportedObjectsByType(NoopPackage::eINSTANCE.noopClass)
		].flatten.map [
			var obj = it.EObjectOrProxy

			if (obj.eIsProxy) {
				obj = resource.resourceSet.getEObject(it.EObjectURI, true)
			}

			obj as NoopClass
		].filter[
			Objects::equals(eResource.URI?.trimSegments(1), uri)
		].filter [
			it.isGame && it.name != TypeSystem::LIB_GAME
		].toSet

		if (games.size > 1) {
			throw new IllegalArgumentException("More than 1 game implementation found: " + games.map[name])
		}

		return games.head
	}

	private def compile(AllocData data) '''
		;----------------------------------------------------------------
		; Class Metadata
		;----------------------------------------------------------------
		«var classCount = 0»
		«FOR noopClass : data.classes.filter[nonPrimitive]»
			«noopClass.asmName» = «classCount++»
			«val fieldOffset = new AtomicInteger(1)»
			«FOR field : noopClass.allFieldsTopDown.filter[nonStatic]»
				«field.nameOfOffset» = «fieldOffset.getAndAdd(field.sizeOf)»
			«ENDFOR»
			
		«ENDFOR»
		;----------------------------------------------------------------
		; Constant variables
		;----------------------------------------------------------------
		«Members::TRUE» = 1
		«Members::FALSE» = 0
		«Members::FT_DPCM_OFF» = $C000
		«Members::FT_DPCM_PTR» = («Members::FT_DPCM_OFF»&$3fff)>>6
		«FOR cons : data.constants»
			«cons.nameOfConstant» = «cons.value.compileConstant»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Static variables
		;----------------------------------------------------------------
		«FOR page : 0..< data.counters.size»
			«val counter = data.counters.get(page)»
			«counter.set(page * 256)»
			«val staticVars = data.statics.filter[storage?.location?.valueOf as Integer ?: Datas::VAR_PAGE === page]»
			«FOR staticVar : staticVars»
				«staticVar.nameOfStatic» = «counter.getAndAdd(staticVar.sizeOf).toHexString(4)»
			«ENDFOR»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; Local variables
		;----------------------------------------------------------------
		«Members::TEMP_VAR_NAME1» = «data.counters.get(Datas::PTR_PAGE).getAndAdd(2).toHexString(4)»
		«Members::TEMP_VAR_NAME2» = «data.counters.get(Datas::PTR_PAGE).getAndAdd(2).toHexString(4)»
		«FOR chunk : data.pointers.values.flatten.sort + data.variables.values.flatten.sort»
			«val delta = data.counters.get(chunk.page).get - chunk.page * 256»
			«chunk.shiftTo(delta)»
			«chunk.variable» = «chunk.lo.toHexString(4)»
		«ENDFOR»
		
		;----------------------------------------------------------------
		; iNES Header
		;----------------------------------------------------------------
			.db 'NES', $1A ;identification of the iNES header
			.db «(data.header.fieldValue('prgRomPages') as Integer).toHexString» ;number of 16KB PRG-ROM pages
			.db «(data.header.fieldValue('chrRomPages') as Integer).toHexString» ;number of 8KB CHR-ROM pages
			.db «(data.header.fieldValue('mapper') as Integer).toHexString» | «(data.header.fieldValue('mirroring') as Integer).toHexString»
			.dsb 9, $00 ;clear the remaining bytes to 16
			
		;----------------------------------------------------------------
		; PRG-ROM Bank(s)
		;----------------------------------------------------------------
			.base $10000 - («(data.header.fieldValue('prgRomPages') as Integer).toHexString» * $4000) 
		
		«FOR rom : data.prgRoms.filter[nonDMC]»
			«rom.compile(new CompileData)»
		«ENDFOR»
		
		;-- Macros ------------------------------------------------------
		;macro mult8x8to8 ; A = A + «Members::TEMP_VAR_NAME1» * «Members::TEMP_VAR_NAME2»
		;  JMP +loop:
		;-add:
		;  CLC
		;  ADC «Members::TEMP_VAR_NAME1»
		;-loop:
		;  ASL «Members::TEMP_VAR_NAME1»
		;+loop:
		;  LSR «Members::TEMP_VAR_NAME2»
		;  BCS -add:
		;  BNE -loop:
		;endm
		
		;-- Methods -----------------------------------------------------
		«FOR method : data.methods.sortBy[fullyQualifiedName]»
			«method.compile(new CompileData => [allocation = data])»
			
		«ENDFOR»
		;-- Constructors ------------------------------------------------
		«FOR constructor : data.constructors.sortBy[type.name]»
			«constructor.compile(null)»
			
		«ENDFOR»
		«val dmcList = data.prgRoms.filter[DMC].toList»
		«IF dmcList.isNotEmpty»
			;-- DMC sound data-----------------------------------------------
				.org «Members::FT_DPCM_OFF»
			«FOR dmcRom : dmcList»
				«dmcRom.compile(new CompileData)»
			«ENDFOR»
		«ENDIF»
		
		;----------------------------------------------------------------
		; Interrupt vectors
		;----------------------------------------------------------------
			.org $FFFA     
		
		 	.dw «data.methods.findFirst[nmi].nameOf»
		 	.dw «data.methods.findFirst[reset].nameOf»
		 	.dw «data.methods.findFirst[irq].nameOf»
		
		;----------------------------------------------------------------
		; CHR-ROM bank(s)
		;----------------------------------------------------------------
		   .base $0000
		
		«FOR rom : data.chrRoms»
			«rom.compile(new CompileData)»
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

	private def fieldValue(NewInstance instance, String fieldname) {
		instance?.constructor?.fields.findFirst [
			variable.name == fieldname
		].value.valueOf ?: instance.type.allFieldsBottomUp.findFirst [
			name == fieldname
		].valueOf

	}
}
