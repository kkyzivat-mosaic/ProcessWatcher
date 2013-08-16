/**
 * Copyright 2013, Mosaic Storage Systems Inc
 */
package com.mosaic.daemon;

import com.mosaic.daemon.LightroomProcessMonitor.LightroomVersion;

/**
 * @author Keith Kyzivat (kkyzivat@mosaicarchive.com)
 */
public interface LightroomProcessMonitorListener
{
    void processStarted(LightroomVersion version);
    void processStopped(LightroomVersion version);
}
