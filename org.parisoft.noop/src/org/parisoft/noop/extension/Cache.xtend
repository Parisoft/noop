package org.parisoft.noop.^extension

import java.util.HashMap
import java.util.HashSet
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.parisoft.noop.generator.MemChunk
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.generator.AllocContext
import com.google.common.collect.HashBasedTable
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.^extension.Expressions.MethodReference
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.Index

class Cache {
	
	public static val prepared = new HashSet<EObject>
	public static val allocated = new HashMap<EObject, List<MemChunk>>
	public static val classeSize = new HashMap<NoopClass, Integer>
	public static val classes = new HashSet<NoopClass>
	public static val contexts = new HashMap<NoopClass, AllocContext>
	public static val mulMethods = HashBasedTable::<Expression, Expression, MethodReference>create
	public static val divMethods = HashBasedTable::<Expression, Expression, MethodReference>create
	public static val modMethods = HashBasedTable::<Expression, Expression, MethodReference>create
	public static val indexExpressions = HashBasedTable::<Member, List<Index>, Expression>create
	
	public static def clear() {
		prepared.clear
		allocated.clear
		classeSize.clear
		classes.clear
		contexts.clear
		mulMethods.clear
		divMethods.clear
		modMethods.clear
		indexExpressions.clear
	}
}