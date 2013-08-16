/**
 * Copyright 2013 Mosaic Storage Systems Inc
 */
#include <Foundation/Foundation.h>
#include <Cocoa/Cocoa.h>
#include "com_mosaic_daemon_LightroomProcessMonitor.h"

@interface MCProcessMonitorInfo : NSObject
{
    jobject lrProcessMonitor;
    NSString* lr3BundleId;
    NSString* lr4BundleId;
    NSString* lr5BundleId;
}

-(id) initWithLRProcessMonitorJObject: (jobject) lrProcessMonitorJObject;
@end

// Globals
/** Stores pointer to JVM. Valid across all threads. */
static JavaVM* jvm;
/** Single processMonitorInfo object */
static MCProcessMonitorInfo* gProcessInfo = nil;

// Forwards
// static BOOL processIsRunning(NSString* bundleIdentifier);
static NSString* jstring2nsstring(JNIEnv* env, jstring processName);
static jstring nsstring2jstring(JNIEnv* env, NSString* processName);


@implementation MCProcessMonitorInfo
- (id) initWithLRProcessMonitorJObject: (jobject) lrProcessMonitorJObject
{
    lrProcessMonitor = lrProcessMonitorJObject;
    lr3BundleId = @"com.adobe.Lightroom3";
    lr4BundleId = @"com.adobe.Lightroom4";
    lr5BundleId = @"com.adobe.Lightroom5";
    return self;
}

- (void) processStateChanged: (NSNotification *) notification
{
    BOOL processRunning = ([notification name] == NSWorkspaceDidLaunchApplicationNotification) ? YES : NO;
    NSString* bundleId = [[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"];
    // NSString* changedProcessId = [[notification userInfo] objectForKey:@"NSApplicationProcessIdentifier"];

    // return on process we're not interested in
    if (([bundleId isEqualToString:lr3BundleId] == NO) &&
        ([bundleId isEqualToString:lr4BundleId] == NO) &&
        ([bundleId isEqualToString:lr5BundleId] == NO))
    {
        return;
    }

    NSLog(@"LightroomProcessMonitor - %@ process status changed: %@", bundleId, (processRunning == NO) ? @"stopped" : @"started");

    // Create new JNIEnv for current thread
    JNIEnv* jniEnv = NULL;
    jint status = (*jvm)->GetEnv(jvm, (void**)&jniEnv, JNI_VERSION_1_6);
    if (status == JNI_EDETACHED)
    {
        NSLog(@"Mosaic - Attaching processStateChanged thread to JVM");
        status = (*jvm)->AttachCurrentThread(jvm, (void**)&jniEnv, NULL);
        NSAssert(status == 0, @"Mosaic - Could not attach JVM to current thread");
    }

    jclass cls = (*jniEnv)->GetObjectClass(jniEnv, lrProcessMonitor);
    NSLog(@"jclass: %p", cls);

    // Pick method to call based on whether process is currently running or not.
    const char* method = (processRunning == NO) ? "processStopped" : "processStarted";
    NSLog(@"method: %s", method);

    // Notify processMonitor object of state change
    jmethodID mid = (*jniEnv)->GetMethodID(jniEnv, cls, method, "(Ljava/lang/String;)V");
    // jmethodID mid = (*jniEnv)->GetMethodID(jniEnv, cls, method, "()V");
    NSLog(@"methodId: %p", mid);
    (*jniEnv)->CallVoidMethod(jniEnv, lrProcessMonitor, mid, nsstring2jstring(jniEnv, bundleId));
    // (*jniEnv)->CallVoidMethod(jniEnv, lrProcessMonitor, mid);
}
@end

/**
 * Monitors a Lightroom process running state -- started or stopped.

 * @author Keith Kyzivat (kkyzivat@mosaicarchive.com)
 */
JNIEXPORT
void JNICALL Java_com_mosaic_daemon_LightroomProcessMonitor_nativeMonitorProcess(JNIEnv* env,
                                                                                 jobject lrProcessMonitor)
{
    jint status = (*env)->GetJavaVM(env, &jvm);
    NSCAssert(status == 0, @"Could not get pointer to JVM");

    NSLog(@"LightroomProcessMonitor - Monitoring LR3,LR4,LR5");

    if (gProcessInfo == nil)
    {
        jobject newLrProcessMonitorRef = (*env)->NewGlobalRef(env, lrProcessMonitor);
        gProcessInfo = [[MCProcessMonitorInfo alloc] initWithLRProcessMonitorJObject: newLrProcessMonitorRef];
    }

    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
    NSNotificationCenter* notificationCenter = [workspace notificationCenter];

    [notificationCenter addObserver: gProcessInfo
                        selector: @selector(processStateChanged:)
                        name: NSWorkspaceDidLaunchApplicationNotification
                        object: workspace];

    [notificationCenter addObserver: gProcessInfo
                        selector: @selector(processStateChanged:)
                        name: NSWorkspaceDidTerminateApplicationNotification
                        object: workspace];

    NSLog(@"LightroomProcessMonitor - Done registering");
}

JNIEXPORT
jboolean JNICALL Java_com_mosaic_daemon_LightroomProcessMonitor_nativeProcessIsRunning(JNIEnv * env,
                                                                                       jclass cls,
                                                                                       jstring lrVersionJStr)
{
    NSString* bundleIdentifier = jstring2nsstring(env, lrVersionJStr);
    NSArray* runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];
    return ([runningApps count] > 0) ? YES : NO;
}

// BOOL processIsRunning(NSString* bundleIdentifier)
// {
//     NSArray* runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];
//     return ([runningApps count] > 0) ? YES : NO;
// }

// /**
//  * Throws Java exception with specified error message.
//  */
// static void throwException(JNIEnv* env, const char* msg)
// {
//     (*env)->ThrowNew(env, (*env)->FindClass(env, "java/lang/Exception"), msg);
// }

/**
 * Converts jstring to an NSString
 */
NSString* jstring2nsstring(JNIEnv* env, jstring s)
{
    const char* p = (*env)->GetStringUTFChars(env, s, NULL);
    NSString* string = [NSString stringWithCString:p encoding:NSUTF8StringEncoding];
    (*env)->ReleaseStringUTFChars(env, s, p);

    return string;
}

/**
 * Converts NSString to jstring
 */
jstring nsstring2jstring(JNIEnv* env, NSString* s)
{
    return (*env)->NewStringUTF(env, [s UTF8String]);
}
