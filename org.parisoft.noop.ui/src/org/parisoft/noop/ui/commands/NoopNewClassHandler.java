package org.parisoft.noop.ui.commands;

import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IResource;
import org.eclipse.jface.wizard.WizardDialog;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.ui.handlers.HandlerUtil;
import org.parisoft.noop.ui.wizards.NoopNewClassWizard;

public class NoopNewClassHandler extends NoopAbstractHandler {

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		Shell activeShell = HandlerUtil.getActiveShell(event);
		IResource resource = getIResource(event);
		String folderPath;

		if (resource instanceof IFile) {
			folderPath = resource.getParent().getFullPath().toString();
		} else if (resource != null) {
			folderPath = resource.getFullPath().toString();
		} else {
			folderPath = "";
		}

		NoopNewClassWizard wizard = new NoopNewClassWizard(folderPath);

		new WizardDialog(activeShell, wizard).open();

		return null;
	}

}
