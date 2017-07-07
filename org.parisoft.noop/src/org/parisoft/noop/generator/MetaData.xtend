package org.parisoft.noop.generator

import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.noop.Method
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.emf.ecore.EObject

class MetaData {

	@Accessors val Variable header
	@Accessors val classes = <NoopClass>newHashSet()
	@Accessors val constants = <Variable>newHashSet()
	@Accessors val singletons = <NoopClass>newHashSet()
	@Accessors val prgRoms = <Variable>newHashSet()
	@Accessors val chrRoms = <Variable>newHashSet()
	@Accessors val methods = <Method, MemChunk>newHashMap()
	@Accessors val variables = <Variable, MemChunk>newHashMap()
	@Accessors val temps = <EObject, MemChunk>newHashMap()

	@Accessors var int ptrCounter = 0x0000
	@Accessors var int varCounter = 0x0400

	new(Variable header) {
		this.header = header
	}

}
