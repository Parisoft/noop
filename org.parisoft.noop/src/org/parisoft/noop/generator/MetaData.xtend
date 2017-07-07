package org.parisoft.noop.generator

import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.noop.Method
import org.eclipse.xtend.lib.annotations.Accessors

class MetaData {

	@Accessors val Variable header
	@Accessors val classes = <NoopClass>newHashSet()
	@Accessors val constants = <Variable>newHashSet()
	@Accessors val singletons = <NoopClass>newHashSet()
	@Accessors val prgRoms = <Variable>newHashSet()
	@Accessors val chrRoms = <Variable>newHashSet()
	@Accessors val methods = <Method, MemChunk>newHashMap()
	@Accessors val variables = <Variable, MemChunk>newHashMap()

	@Accessors var int ptrCounter
	@Accessors var int varCounter

	new(Variable header) {
		this.header = header
	}

}
