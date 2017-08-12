#include <jni.h>

JNIEXPORT jstring JNICALL
Java_mimoja_abfackeln_jetzt_scryptpwgen_MainActivity_generatePassword(JNIEnv *env, jobject instance,
                                                                      jstring site_,
                                                                      jstring password_) {
    const char *site = (*env)->GetStringUTFChars(env, site_, 0);
    const char *password = (*env)->GetStringUTFChars(env, password_, 0);

    const char *returnPassword = "Fix me in native-lib.m";

    (*env)->ReleaseStringUTFChars(env, site_, site);
    (*env)->ReleaseStringUTFChars(env, password_, password);

    return (*env)->NewStringUTF(env, returnPassword);
}