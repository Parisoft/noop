package org.parisoft.noop.ui.perspectives

import org.eclipse.ui.IPageLayout
import org.eclipse.ui.IPerspectiveFactory

class NoopPerspectiveFactory implements IPerspectiveFactory {

	override createInitialLayout(IPageLayout layout) {
		val editorArea = layout.editorArea

		val topLeft = layout.createFolder("topLeft", IPageLayout::LEFT, 0.25f, editorArea)
		topLeft.addView(IPageLayout.ID_PROJECT_EXPLORER)
		topLeft.addPlaceholder(IPageLayout.ID_BOOKMARKS)

		layout.addView(IPageLayout.ID_PROBLEM_VIEW, IPageLayout::BOTTOM, 0.66f, editorArea)
//		layout.addView(IConsoleConstants.ID_CONSOLE_VIEW, IPageLayout::BOTTOM, 0.66f, editorArea)
	}

}
