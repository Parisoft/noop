/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.generator

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.resource.IResourceDescriptions
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopPackage
import org.parisoft.noop.noop.StorageType

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class NoopGenerator extends AbstractGenerator {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension IQualifiedNameProvider
	@Inject extension MethodCompiler
	@Inject IResourceDescriptions descriptions

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val asm = resource.compile

		if (asm !== null) {
			fsa.generateFile(asm.filename, asm.content)
		}
	}

	private def compile(Resource resource) {
		val game = resource.gameClass

		if (game === null) {
			return null
		}

		val header = game.inheritedFields.filter[typeOf.isNESHeader].head
		val main = game.inheritedMethods.findFirst[name == "main" && params.isEmpty]
		val metadata = new MetaData(header)
		
//		main.prepare(metadata)
		
		val allFields = game.inheritedFields
		val constants = allFields.filter[isConstant].filter[typeOf.isPrimitive].filter[nonROM].filter[dimensionOf.isEmpty]
		val singletons = allFields.filter[isConstant].filter[typeOf.isSingleton].filter[it != header]
		val prgRoms = allFields.filter[isROM].filter[storage.type == StorageType.PRGROM]
		val chrRoms = allFields.filter[isROM].filter[storage.type == StorageType.CHRROM]
		val fields = allFields.filter[nonConstant]

		var addr = new AtomicInteger(0x0400)
		val content = '''
			;----------------------------------------------------------------
			; Constants
			;----------------------------------------------------------------
			«FOR cons : constants»
				«cons.fullyQualifiedName.toString» = «cons.valueOf.toString»
			«ENDFOR»
			
			;----------------------------------------------------------------
			; Singletons
			;----------------------------------------------------------------
			_«game.name.toLowerCase» = «addr.getAndAdd(game.sizeOf).toHexString»
			«FOR singleton : singletons»
				_«singleton.typeOf.name.toLowerCase» = «addr.getAndAdd(singleton.sizeOf).toHexString»
			«ENDFOR»
			
			;----------------------------------------------------------------
			; iNES Header
			;----------------------------------------------------------------
			  .db "NES", $1A ;identification of the iNES header
			  .db «(header.valueOf as NoopInstance).fields.findFirst[name == "prgRomPages"]?.valueOf» ;number of 16KB PRG-ROM pages
			  .db «(header.valueOf as NoopInstance).fields.findFirst[name == "chrRomPages"]?.valueOf» ;number of 8KB CHR-ROM pages
			  .db «(header.valueOf as NoopInstance).fields.findFirst[name == "mapper"]?.valueOf» | «(header.valueOf as NoopInstance).fields.findFirst[name == "mirroring"]?.valueOf»
			  .dsb 9, $00 ;clear the remaining bytes
			  
			;----------------------------------------------------------------
			; PRG-ROM Bank(s)
			;----------------------------------------------------------------
			  .base $10000 - («(header.valueOf as NoopInstance).fields.findFirst[name == "prgRomPages"]?.valueOf» * $4000) 
			  
		'''

		new ASM('''«game.name».asm''', content)
	}

	private def toHexString(int value) {
		var string = Integer.toHexString(value).toUpperCase

		while (string.length < 4) {
			string = '0' + string
		}

		return '$' + string
	}

	private def gameClass(Resource resource) {
		val games = descriptions.allResourceDescriptions.map [
			getExportedObjectsByType(NoopPackage::eINSTANCE.noopClass)
		].flatten.map [
			var obj = it.EObjectOrProxy

			if (obj.eIsProxy) {
				obj = resource.resourceSet.getEObject(it.EObjectURI, true)
			}

			obj as NoopClass
		].filter [
			it.isGame
		].toSet

		if (games.size > 1) {
			throw new IllegalArgumentException("More than 1 game implementation found: " + games.map[name])
		}

		return games.head
	}
}
