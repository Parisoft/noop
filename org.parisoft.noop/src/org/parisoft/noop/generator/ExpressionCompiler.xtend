package org.parisoft.noop.generator

import org.parisoft.noop.noop.Expression

class ExpressionCompiler {
	
	def prepare(Expression expression, MetaData data) {
		
	}
	
	def prepareExpr(Expression expression, MetaData data) {
		expression.prepare(data)
	}
}