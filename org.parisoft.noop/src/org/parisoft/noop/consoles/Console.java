package org.parisoft.noop.consoles;

import java.io.OutputStream;

public interface Console {

	OutputStream newOutStream();

	OutputStream newErrStream();

}
