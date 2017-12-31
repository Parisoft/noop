package org.parisoft.noop.ui.perspectives

import org.eclipse.ui.IPerspectiveFactory
import org.eclipse.ui.IPageLayout

class NoopPerspectiveFactory implements IPerspectiveFactory {

	override createInitialLayout(IPageLayout layout) {
		val editorArea = layout.getEditorArea();

		// Top left: Resource Navigator view and Bookmarks view placeholder
		val topLeft = layout.createFolder("topLeft", IPageLayout.LEFT, 0.25f, editorArea);
		topLeft.addView(IPageLayout.ID_PROJECT_EXPLORER);
		topLeft.addPlaceholder(IPageLayout.ID_BOOKMARKS);

		// Bottom left: Outline view and Property Sheet view
//		val bottomLeft = layout.createFolder("bottomLeft", IPageLayout.BOTTOM, 0.50f, "topLeft");
//		bottomLeft.addView(IPageLayout.ID_OUTLINE);
//		bottomLeft.addView(IPageLayout.ID_PROP_SHEET);
		// Bottom right: Task List view
		layout.addView(IPageLayout.ID_PROBLEM_VIEW, IPageLayout.BOTTOM, 0.66f, editorArea);
	}

}
