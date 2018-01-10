package org.parisoft.noop.ui.commands;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.commands.IHandler;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;
import org.parisoft.noop.generator.NoopOutputConfigurationProvider;
import org.parisoft.noop.preferences.NoopPreferences;

public class NoopRunHandler extends AbstractHandler implements IHandler {

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		// TODO Auto-generated method stub
		try {
			HandlerUtil.getActiveWorkbenchWindow(event).run(true, true, (monitor) -> {
				monitor.beginTask("open", 1);
				String nes = " /home/andre/git/runtime-EclipseApplication/compile-test/out/Oba.nes";
				try {
					Runtime.getRuntime().exec(NoopPreferences.getPathToEmulator() + nes);
				} catch (IOException e) {
					monitor.setCanceled(true);
				}
				monitor.internalWorked(1);
			});
		} catch (InvocationTargetException | InterruptedException e) {
			MessageDialog.openError(HandlerUtil.getActiveShell(event), "Error", e.getMessage());
		}
//		ISelection selection = HandlerUtil.getCurrentSelection(event);
//		String outPath = "none";
//		
//		if (selection instanceof IStructuredSelection) {
//			IStructuredSelection structuredSelection = (IStructuredSelection) selection;
//			Object firstElement = structuredSelection.getFirstElement();
//		
//			if (firstElement instanceof IFile) {
//				IFile file = (IFile) firstElement;
//				IProject project = file.getProject();
//				IFolder outFolder = project.getFolder(NoopOutputConfigurationProvider.OUTPUT_DIR);
//				outPath = outFolder.getFullPath().toOSString();
//			}
//		}
//		MessageDialog.openInformation(HandlerUtil.getActiveWorkbenchWindow(event).getShell(), "Info", outPath);
		return null;
	}

}
