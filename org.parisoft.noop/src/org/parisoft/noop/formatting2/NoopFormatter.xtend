/*
 * generated by Xtext 2.12.0
 */
package org.parisoft.noop.formatting2

import com.google.inject.Inject
import org.eclipse.xtext.formatting2.AbstractFormatter2
import org.eclipse.xtext.formatting2.IFormattableDocument
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.AddExpression
import org.parisoft.noop.noop.AndExpression
import org.parisoft.noop.noop.ArrayLiteral
import org.parisoft.noop.noop.AsmStatement
import org.parisoft.noop.noop.AssignmentExpression
import org.parisoft.noop.noop.BAndExpression
import org.parisoft.noop.noop.BOrExpression
import org.parisoft.noop.noop.Block
import org.parisoft.noop.noop.CastExpression
import org.parisoft.noop.noop.ComplementExpression
import org.parisoft.noop.noop.Constructor
import org.parisoft.noop.noop.ConstructorField
import org.parisoft.noop.noop.DecExpression
import org.parisoft.noop.noop.DifferExpression
import org.parisoft.noop.noop.DivExpression
import org.parisoft.noop.noop.ElseStatement
import org.parisoft.noop.noop.EqualsExpression
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.noop.ForeverStatement
import org.parisoft.noop.noop.GeExpression
import org.parisoft.noop.noop.GtExpression
import org.parisoft.noop.noop.IfStatement
import org.parisoft.noop.noop.IncExpression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.InstanceOfExpression
import org.parisoft.noop.noop.LShiftExpression
import org.parisoft.noop.noop.LeExpression
import org.parisoft.noop.noop.Length
import org.parisoft.noop.noop.LtExpression
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.ModExpression
import org.parisoft.noop.noop.MulExpression
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopPackage
import org.parisoft.noop.noop.NotExpression
import org.parisoft.noop.noop.OrExpression
import org.parisoft.noop.noop.RShiftExpression
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.SigNegExpression
import org.parisoft.noop.noop.SigPosExpression
import org.parisoft.noop.noop.Statement
import org.parisoft.noop.noop.Storage
import org.parisoft.noop.noop.SubExpression
import org.parisoft.noop.noop.Variable

class NoopFormatter extends AbstractFormatter2 {

	@Inject extension Members
//	@Inject extension Statements
	@Inject extension Collections

	def dispatch void format(NoopClass noopClass, extension IFormattableDocument document) {
		interior(noopClass.regionFor.keyword('{'), noopClass.regionFor.keyword('}'))[indent]
		noopClass.regionFor.keyword('extends').surround[oneSpace]
		noopClass.regionFor.keyword('{').prepend[oneSpace]
		noopClass.members.forEach[format]
	}

	def dispatch void format(Variable variable, extension IFormattableDocument document) {
		variable.prepend[indent]

		if (variable.isParameter) {
			if (variable.dimension.isEmpty) {
				variable.regionFor.feature(NoopPackage.Literals::VARIABLE__TYPE).prepend[indent].append[oneSpace]
			} else {
				variable.regionFor.feature(NoopPackage.Literals::VARIABLE__TYPE).prepend[indent].append[noSpace]
				variable.dimension.forEach [ length, i |
					if (i < variable.dimension.length - 1) {
						length.format.surround[noSpace]
					} else {
						length.format.prepend[noSpace].append[oneSpace]
					}
				]
			}
		} else {
			variable.regionFor.keyword(':').surround[indent; oneSpace]
		}

		variable.storage.format
		variable.value.format
	}

	def dispatch void format(Method method, extension IFormattableDocument document) {
		interior(method.regionFor.keyword('('), method.regionFor.keyword(')'))[indent]
		method.prepend[indent]
		method.regionFor.keyword('(').surround[noSpace]
		method.regionFor.keyword(')').prepend[noSpace]
		method.params.forEach [ param |
			param.format.immediatelyFollowing.keyword(',').prepend[noSpace].append[oneSpace]
		]
		method.storage.format
		method.body.format
	}

	def dispatch void format(Length length, extension IFormattableDocument document) {
		interior(length.regionFor.keyword('['), length.regionFor.keyword(']'))[indent; noSpace]
		length.value.format
	}

	def dispatch void format(Index index, extension IFormattableDocument document) {
		interior(index.regionFor.keyword('['), index.regionFor.keyword(']'))[indent; noSpace]
		index.value.format
	}

	def dispatch void format(Storage storage, extension IFormattableDocument document) {
		interior(storage.regionFor.keyword('['), storage.regionFor.keyword(']'))[indent; noSpace]
		storage.prepend[indent; oneSpace]
		storage.regionFor.keyword('[').prepend[noSpace]
		storage.location.format;
	}

	def dispatch void format(ReturnStatement ret, extension IFormattableDocument document) {
		ret.prepend[indent]
		ret.value.format.prepend[oneSpace]
	}

	def dispatch void format(IfStatement ifStatement, extension IFormattableDocument document) {
		interior(ifStatement.regionFor.keyword('('), ifStatement.regionFor.keyword(')'))[indent]
		ifStatement.prepend[indent; oneSpace]
		ifStatement.regionFor.keyword('(').prepend[oneSpace].append[noSpace]
		ifStatement.regionFor.keyword(')').prepend[noSpace]
		ifStatement.condition.format
		ifStatement.body.format
		ifStatement.^else.format
	}

	def dispatch void format(ElseStatement elseStatement, extension IFormattableDocument document) {
		elseStatement.prepend[indent; oneSpace]
		elseStatement.body.format
		elseStatement.^if.format
	}

	def dispatch void format(ForStatement forStatement, extension IFormattableDocument document) {
		interior(forStatement.regionFor.keyword('('), forStatement.regionFor.keyword(')'))[indent]
		forStatement.prepend[indent]
		forStatement.regionFor.keyword('(').prepend[oneSpace].append[noSpace]
		forStatement.regionFor.keyword(')').prepend[noSpace]
		forStatement.variables.forEach [ variable |
			variable.format.immediatelyFollowing.keyword(',').prepend[noSpace].append[oneSpace]
		]
		forStatement.assignments.forEach [ assignment |
			assignment.format.immediatelyFollowing.keyword(',').prepend[noSpace].append[oneSpace]
		]
		forStatement.condition.format.append[noSpace]
		forStatement.expressions.forEach [ expression |
			expression.format.immediatelyFollowing.keyword(',').prepend[noSpace].append[oneSpace]
		]

		val semicolons = forStatement.regionFor.keywords(';', ';')

		if (forStatement.condition !== null && forStatement.expressions.isNotEmpty) {
			semicolons.forEach[prepend[noSpace].append[oneSpace]]
		} else if (forStatement.condition !== null && forStatement.expressions.isEmpty) {
			semicolons.head.prepend[noSpace].append[oneSpace]
			semicolons.last.prepend[noSpace]
		} else if (forStatement.condition === null && forStatement.expressions.isNotEmpty) {
			semicolons.head.prepend[noSpace].append[noSpace]
			semicolons.last.append[oneSpace]
		} else {
			semicolons.forEach[prepend[noSpace].append[noSpace]]
		}

		forStatement.body.format
	}

	def dispatch void format(ForeverStatement forever, extension IFormattableDocument document) {
		forever.prepend[indent]
		forever.body.format
	}

	def dispatch void format(AsmStatement asm, extension IFormattableDocument document) {
//		val max = asm.getContainerOfType(Block).statements.filter(AsmStatement).map[compile(null).length].max
//		val len = asm.compile(null).length
		asm.prepend[indent]
	}

	def dispatch void format(Block block, extension IFormattableDocument document) {
		interior(block.regionFor.keyword('{'), block.regionFor.keyword('}'))[indent]
		block.regionFor.keyword('{').prepend[oneSpace]
		block.statements.forEach[format]
	}

	def dispatch void format(AssignmentExpression assignment, extension IFormattableDocument document) {
		assignment.preFormat(document)
		assignment.regionFor.feature(NoopPackage.Literals::ASSIGNMENT_EXPRESSION__ASSIGNMENT).surround[indent; oneSpace]
		assignment.right.format
	}

	def dispatch void format(OrExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('or').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(AndExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('and').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(BOrExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('|').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(BAndExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('&').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(EqualsExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('=').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(DifferExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('#').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(GtExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('>').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(GeExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('>=').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(LtExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('<').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(LeExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('<=').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(InstanceOfExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('instanceOf').surround[indent; oneSpace]
		expression.left.format
	}

	def dispatch void format(LShiftExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('<<').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(RShiftExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('>>').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(AddExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('+').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(SubExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('-').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(MulExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('*').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(DivExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('/').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(ModExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('%').surround[indent; oneSpace]
		expression.left.format
		expression.right.format
	}

	def dispatch void format(CastExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('as').surround[indent; oneSpace]
		expression.left.format
		expression.dimension.forEach[format.prepend[noSpace]]
	}

	def dispatch void format(ComplementExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('~').append[noSpace]
	}

	def dispatch void format(NotExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('not').append[oneSpace]
	}

	def dispatch void format(SigNegExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('-').append[noSpace]
	}

	def dispatch void format(SigPosExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('+').append[noSpace]
	}

	def dispatch void format(DecExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('--').append[noSpace]
	}

	def dispatch void format(IncExpression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
		expression.regionFor.keyword('++').append[noSpace]
	}

	def dispatch void format(ArrayLiteral array, extension IFormattableDocument document) {
		interior(array.regionFor.keyword('['), array.regionFor.keyword(']'))[indent]
		array.preFormat(document)
		array.regionFor.keyword('[').append[noSpace]
		array.regionFor.keyword(']').prepend[noSpace]
		array.values.forEach [ value |
			value.format.immediatelyFollowing.keyword(',').prepend[noSpace].append[oneSpace]
		]
	}

	def dispatch void format(NewInstance newInstance, extension IFormattableDocument document) {
		newInstance.preFormat(document)
		newInstance.constructor.format.prepend[noSpace]
		newInstance.dimension.forEach[format.prepend[noSpace]]
	}

	def dispatch void format(Constructor constructor, extension IFormattableDocument document) {
		interior(constructor.regionFor.keyword('{'), constructor.regionFor.keyword('}'))[indent]
		constructor.regionFor.keyword('}').prepend[oneSpace]
		constructor.fields.head.prepend[oneSpace]
		constructor.fields.forEach [ field |
			field.format.immediatelyFollowing.keyword(',').prepend[noSpace].append[oneSpace]
		]
	}

	def dispatch void format(ConstructorField field, extension IFormattableDocument document) {
		field.prepend[indent]
		field.regionFor.keyword(':').surround[indent; oneSpace]
		field.value.format
	}

	def dispatch void format(MemberSelect select, extension IFormattableDocument document) {
		interior(select.regionFor.keyword('('), select.regionFor.keyword(')'))[indent]
		select.prepend[indent]
		select.receiver.format
		select.regionFor.keyword('.').surround[indent; noSpace]
		select.regionFor.keywords('(').forEach[surround[noSpace]]
		select.regionFor.keywords(')').forEach[prepend[noSpace]]
		select.args.forEach [ arg |
			arg.format.immediatelyFollowing.keyword(',').prepend[noSpace].append[oneSpace]
		]
		select.indexes.forEach[format.prepend[noSpace]]
	}
	
	def dispatch void format(MemberRef ref, extension IFormattableDocument document) {
		interior(ref.regionFor.keyword('('), ref.regionFor.keyword(')'))[indent]
		ref.prepend[indent]
		ref.regionFor.keywords('(').forEach[surround[noSpace]]
		ref.regionFor.keywords(')').forEach[prepend[noSpace]]
		ref.args.forEach [ arg |
			arg.format.immediatelyFollowing.keyword(',').prepend[noSpace].append[oneSpace]
		]
		ref.indexes.forEach[format.prepend[noSpace]]
	}

	def dispatch void format(Statement statement, extension IFormattableDocument document) {
		statement.prepend[indent]
	}

	def dispatch void format(Expression expression, extension IFormattableDocument document) {
		expression.preFormat(document)
	}

	def void preFormat(Expression expression, extension IFormattableDocument document) {
		expression.prepend[indent]
		expression.regionFor.keyword('(').append[noSpace]
		expression.regionFor.keyword(')').prepend[noSpace]
	}
}
