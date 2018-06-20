package org.parisoft.noop.generator.process

import org.parisoft.noop.generator.alloc.AllocContext
import org.parisoft.noop.generator.alloc.MemChunk
import java.util.List

interface Node {
	
	def void process(ProcessContext ctx)
	
	def List<MemChunk> alloc(AllocContext ctx)
}