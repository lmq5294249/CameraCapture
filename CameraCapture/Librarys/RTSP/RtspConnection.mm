//
//  RtspConnection.m
//  WRJ_RTSP
//
//  Created by 林漫钦 on 16/10/27.
//  Copyright (c) 2016年 Lin. All rights reserved.

#import "RtspConnection.h"
#import "liveMedia.hh"
#import "BasicUsageEnvironment.hh"
#import "AWLinkConstant.h"
#import "AWTools.h"

@interface RtspConnection()      //


@end
@implementation RtspConnection
singleton_implementation(RtspConnection)

#define h264_add @"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4"
//#define jpeg_add @"rtsp://192.168.101.1:7070/JPEGVideoSMS"
//#define audio_add @"rtsp://192.168.101.1:7070/wavLiverAudio"
//#define video_audio_add @"rtsp://192.168.101.1:7070/JPEGWavLiver"
#define online_play @"rtsp://192.168.2.1/live2"
+(RtspConnection *)shareStore
{
    static RtspConnection *shareRtsp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareRtsp = [[RtspConnection alloc] init];
    });
    return shareRtsp;
}

char eventLoopWatchVariable = 1;

int sthvalue(char c);
int strtohex(char *str, char *data);

void continueAfterDESCRIBE(RTSPClient* rtspClient, int resultCode, char* resultString);
void continueAfterSETUP(RTSPClient* rtspClient, int resultCode, char* resultString);
void continueAfterPLAY(RTSPClient* rtspClient, int resultCode, char* resultString);

// Other event handler functions:
void subsessionAfterPlaying(void* clientData); // called when a stream's subsession (e.g., audio or video substream) ends
void subsessionByeHandler(void* clientData); // called when a RTCP "BYE" is received for a subsession
void streamTimerHandler(void* clientData);
// called at the end of a stream's expected duration (if the stream has not already signaled its end using a RTCP "BYE")

// The main streaming routine (for each "rtsp://" URL):
void openURL(UsageEnvironment& env, char const* progName, char const* rtspURL);

// Used to iterate through each stream's 'subsessions', setting up each one:
void setupNextSubsession(RTSPClient* rtspClient);

// Used to shut down and close a stream (including its "RTSPClient" object):
void shutdownStream(RTSPClient* rtspClient, int exitCode = 1);

// A function that outputs a string that identifies each stream (for debugging output).  Modify this if you wish:
UsageEnvironment& operator<<(UsageEnvironment& env, const RTSPClient& rtspClient) {
    return env << "[URL:\"" << rtspClient.url() << "\"]: ";
}

// A function that outputs a string that identifies each subsession (for debugging output).  Modify this if you wish:
UsageEnvironment& operator<<(UsageEnvironment& env, const MediaSubsession& subsession) {
    return env << subsession.mediumName() << "/" << subsession.codecName();
}

void usage(UsageEnvironment& env, char const* progName) {
//    env << "Usage: " << progName << " <rtsp-url-1> ... <rtsp-url-N>\n";
//    env << "\t(where each <rtsp-url-i> is a \"rtsp://\" URL)\n";
}


// Define a class to hold per-stream state that we maintain throughout each stream's lifetime:

class StreamClientState {
public:
    StreamClientState();
    virtual ~StreamClientState();
    
public:
    MediaSubsessionIterator* iter;
    MediaSession* session;
    MediaSubsession* subsession;
    TaskToken streamTimerTask;
    double duration;
};

// If you're streaming just a single stream (i.e., just from a single URL, once), then you can define and use just a single
// "StreamClientState" structure, as a global variable in your application.  However, because - in this demo application - we're
// showing how to play multiple streams, concurrently, we can't do that.  Instead, we have to have a separate "StreamClientState"
// structure for each "RTSPClient".  To do this, we subclass "RTSPClient", and add a "StreamClientState" field to the subclass:

class ourRTSPClient: public RTSPClient {
public:
    static ourRTSPClient* createNew(UsageEnvironment& env, char const* rtspURL,
                                    int verbosityLevel = 0,
                                    char const* applicationName = NULL,
                                    portNumBits tunnelOverHTTPPortNum = 0);
    
protected:
    ourRTSPClient(UsageEnvironment& env, char const* rtspURL,
                  int verbosityLevel, char const* applicationName, portNumBits tunnelOverHTTPPortNum);
    // called only by createNew();
    virtual ~ourRTSPClient();
    
public:
    StreamClientState scs;
};

// Define a data sink (a subclass of "MediaSink") to receive the data for each subsession (i.e., each audio or video 'substream').
// In practice, this might be a class (or a chain of classes) that decodes and then renders the incoming audio or video.
// Or it might be a "FileSink", for outputting the received data into a file (as is done by the "openRTSP" application).
// In this example code, however, we define a simple 'dummy' sink that receives incoming data, but does nothing with it.

class DummySink: public MediaSink {
public:
    static DummySink* createNew(UsageEnvironment& env,
                                MediaSubsession& subsession, // identifies the kind of data that's being received
                                char const* streamId = NULL); // identifies the stream itself (optional)
    
private:
    DummySink(UsageEnvironment& env, MediaSubsession& subsession, char const* streamId);
    // called only by "createNew()"
    virtual ~DummySink();
    
    static void afterGettingFrame(void* clientData, unsigned frameSize,
                                  unsigned numTruncatedBytes,
                                  struct timeval presentationTime,
                                  unsigned durationInMicroseconds);
    void afterGettingFrame(unsigned frameSize, unsigned numTruncatedBytes,
                           struct timeval presentationTime, unsigned durationInMicroseconds);
    
private:
    // redefined virtual functions:
    virtual Boolean continuePlaying();
    
private:
    u_int8_t* fReceiveBuffer;
    MediaSubsession& fSubsession;
    char* fStreamId;
    
    
    //custom
//    AVSync *avsync;
    
};

#define RTSP_CLIENT_VERBOSITY_LEVEL 1 // by default, print verbose output from each "RTSPClient"

static unsigned rtspClientCount = 0; // Counts how many streams (i.e., "RTSPClient"s) are currently in use.

void openURL(UsageEnvironment& env, char const* progName, char const* rtspURL) {
    // Begin by creating a "RTSPClient" object.  Note that there is a separate "RTSPClient" object for each stream that we wish
    // to receive (even if more than stream uses the same "rtsp://" URL).
    RTSPClient* rtspClient = ourRTSPClient::createNew(env, rtspURL, RTSP_CLIENT_VERBOSITY_LEVEL, progName);
    if (rtspClient == NULL) {
        env << "Failed to create a RTSP client for URL \"" << rtspURL << "\": " << env.getResultMsg() << "\n";
        return;
    }
    
    ++rtspClientCount;
    
    // Next, send a RTSP "DESCRIBE" command, to get a SDP description for the stream.
    // Note that this command - like all RTSP commands - is sent asynchronously; we do not block, waiting for a response.
    // Instead, the following function call returns immediately, and we handle the RTSP response later, from within the event loop:
    rtspClient->sendDescribeCommand(continueAfterDESCRIBE);
}


// Implementation of the RTSP 'response handlers':

void continueAfterDESCRIBE(RTSPClient* rtspClient, int resultCode, char* resultString) {
    do {
        UsageEnvironment& env = rtspClient->envir(); // alias
        StreamClientState& scs = ((ourRTSPClient*)rtspClient)->scs; // alias
        
        if (resultCode != 0) {
            env << *rtspClient << "Failed to get a SDP description: " << resultString << "\n";
            delete[] resultString;
            break;
        }
        
        char* const sdpDescription = resultString;
        env << *rtspClient << "Got a SDP description:\n" << sdpDescription << "\n";
        
        // Create a media session object from this SDP description:
        scs.session = MediaSession::createNew(env, sdpDescription);
        delete[] sdpDescription; // because we don't need it anymore
        if (scs.session == NULL) {
            env << *rtspClient << "Failed to create a MediaSession object from the SDP description: " << env.getResultMsg() << "\n";
            break;
        } else if (!scs.session->hasSubsessions()) {
            env << *rtspClient << "This session has no media subsessions (i.e., no \"m=\" lines)\n";
            break;
        }
        
        // Then, create and set up our data source objects for the session.  We do this by iterating over the session's 'subsessions',
        // calling "MediaSubsession::initiate()", and then sending a RTSP "SETUP" command, on each one.
        // (Each 'subsession' will have its own data source.)
        scs.iter = new MediaSubsessionIterator(*scs.session);
        setupNextSubsession(rtspClient);
        return;
    } while (0);
    
    // An unrecoverable error occurred with this stream.
    shutdownStream(rtspClient);
}

// By default, we request that the server stream its data using RTP/UDP.
// If, instead, you want to request that the server stream via RTP-over-TCP, change the following to True:
#define REQUEST_STREAMING_OVER_TCP true

void setupNextSubsession(RTSPClient* rtspClient) {
    UsageEnvironment& env = rtspClient->envir(); // alias
    StreamClientState& scs = ((ourRTSPClient*)rtspClient)->scs; // alias
    
    scs.subsession = scs.iter->next();
    if (scs.subsession != NULL) {
        if (!scs.subsession->initiate()) {
            env << *rtspClient << "Failed to initiate the \"" << *scs.subsession << "\" subsession: " << env.getResultMsg() << "\n";
            setupNextSubsession(rtspClient); // give up on this subsession; go to the next one
        } else {
            env << *rtspClient << "Initiated the \"" << *scs.subsession << "\" subsession (";
            if (scs.subsession->rtcpIsMuxed()) {
                env << "client port " << scs.subsession->clientPortNum();
            } else {
                env << "client ports " << scs.subsession->clientPortNum() << "-" << scs.subsession->clientPortNum()+1;
            }
            env << ")\n";
            
            // Continue setting up this subsession, by sending a RTSP "SETUP" command:
            rtspClient->sendSetupCommand(*scs.subsession, continueAfterSETUP, False, REQUEST_STREAMING_OVER_TCP);
        }
        return;
    }
    
    // We've finished setting up all of the subsessions.  Now, send a RTSP "PLAY" command to start the streaming:
    if (scs.session->absStartTime() != NULL) {
        // Special case: The stream is indexed by 'absolute' time, so send an appropriate "PLAY" command:
        rtspClient->sendPlayCommand(*scs.session, continueAfterPLAY, scs.session->absStartTime(), scs.session->absEndTime());
    } else {
        scs.duration = scs.session->playEndTime() - scs.session->playStartTime();
        rtspClient->sendPlayCommand(*scs.session, continueAfterPLAY);
    }
}

void continueAfterSETUP(RTSPClient* rtspClient, int resultCode, char* resultString) {

    do {
        UsageEnvironment& env = rtspClient->envir(); // alias
        StreamClientState& scs = ((ourRTSPClient*)rtspClient)->scs; // alias
        
        if (resultCode != 0) {
            env << *rtspClient << "Failed to set up the \"" << *scs.subsession << "\" subsession: " << resultString << "\n";
            break;
        }
        
        env << *rtspClient << "Set up the \"" << *scs.subsession << "\" subsession (";
        if (scs.subsession->rtcpIsMuxed()) {
            env << "client port " << scs.subsession->clientPortNum();
        } else {
            env << "client ports " << scs.subsession->clientPortNum() << "-" << scs.subsession->clientPortNum()+1;
        }
        env << ")\n";
        
        // Having successfully setup the subsession, create a data sink for it, and call "startPlaying()" on it.
        // (This will prepare the data sink to receive data; the actual flow of data from the client won't start happening until later,
        // after we've sent a RTSP "PLAY" command.)
        
        scs.subsession->sink = DummySink::createNew(env, *scs.subsession, rtspClient->url());
        
        // perhaps use your own custom "MediaSink" subclass instead
        if (scs.subsession->sink == NULL) {
            env << *rtspClient << "Failed to create a data sink for the \"" << *scs.subsession
            << "\" subsession: " << env.getResultMsg() << "\n";
            break;
        }
        
        env << *rtspClient << "Created a data sink for the \"" << *scs.subsession << "\" subsession\n";
        scs.subsession->miscPtr = rtspClient; // a hack to let subsession handler functions get the "RTSPClient" from the subsession
        scs.subsession->sink->startPlaying(*(scs.subsession->readSource()),
                                           subsessionAfterPlaying, scs.subsession);
        // Also set a handler to be called if a RTCP "BYE" arrives for this subsession:
        if (scs.subsession->rtcpInstance() != NULL) {
            scs.subsession->rtcpInstance()->setByeHandler(subsessionByeHandler, scs.subsession);
        }
        
        if (scs.subsession) {
            //连接成功->解析数据，因为很多属性禁止访问导致不能直接获取参数，修改源码或者通过可获取的字符串解析
            MediaSubsession *mediaSession = scs.subsession;
            RtspFrameInfo audioFrameInfo;
            char const* audioCodecName = mediaSession->codecName();
            if (!strcmp(audioCodecName, "MPEG4-GENERIC")) {
                audioFrameInfo.codec = RTSP_AUDIO_CODE_AAC;
                audioFrameInfo.sample_rate = (unsigned int)mediaSession->rtpTimestampFrequency();
                audioFrameInfo.bits_per_sample = (unsigned int)16; //一般都是默认16位
                audioFrameInfo.channels = (unsigned int)mediaSession->numChannels();
                RtspConnection *rtspConnection = [RtspConnection shareStore];
                [rtspConnection.delegate setAudioFrameDecodeInfo:audioFrameInfo];
            }
        }
        
    } while (0);
    delete[] resultString;
    
    // Set up the next subsession, if any:
    setupNextSubsession(rtspClient);
}

void continueAfterPLAY(RTSPClient* rtspClient, int resultCode, char* resultString) {
    Boolean success = False;
    
    do {
        UsageEnvironment& env = rtspClient->envir(); // alias
        StreamClientState& scs = ((ourRTSPClient*)rtspClient)->scs; // alias
        
        if (resultCode != 0) {
            env << *rtspClient << "Failed to start playing session: " << resultString << "\n";
            break;
        }
        
        // Set a timer to be handled at the end of the stream's expected duration (if the stream does not already signal its end
        // using a RTCP "BYE").  This is optional.  If, instead, you want to keep the stream active - e.g., so you can later
        // 'seek' back within it and do another RTSP "PLAY" - then you can omit this code.
        // (Alternatively, if you don't want to receive the entire stream, you could set this timer for some shorter value.)
        if (scs.duration > 0) {
            unsigned const delaySlop = 2; // number of seconds extra to delay, after the stream's expected duration.  (This is optional.)
            scs.duration += delaySlop;
            unsigned uSecsToDelay = (unsigned)(scs.duration*1000000);
            scs.streamTimerTask = env.taskScheduler().scheduleDelayedTask(uSecsToDelay, (TaskFunc*)streamTimerHandler, rtspClient);
        }
        
        env << *rtspClient << "Started playing session";
        if (scs.duration > 0) {
            env << " (for up to " << scs.duration << " seconds)";
        }
        env << "...\n";
        
        success = True;
    } while (0);
    delete[] resultString;
    
    if (!success) {
        // An unrecoverable error occurred with this stream.
        shutdownStream(rtspClient);
    }
}
;

// Implementation of the other event handlers:

void subsessionAfterPlaying(void* clientData) {
    MediaSubsession* subsession = (MediaSubsession*)clientData;
    RTSPClient* rtspClient = (RTSPClient*)(subsession->miscPtr);
    
    // Begin by closing this subsession's stream:
    Medium::close(subsession->sink);
    subsession->sink = NULL;
    
    // Next, check whether *all* subsessions' streams have now been closed:
    MediaSession& session = subsession->parentSession();
    MediaSubsessionIterator iter(session);
    while ((subsession = iter.next()) != NULL) {
        if (subsession->sink != NULL) return; // this subsession is still active
    }
    
    // All subsessions' streams have now been closed, so shutdown the client:
    shutdownStream(rtspClient);
}

void subsessionByeHandler(void* clientData) {
    MediaSubsession* subsession = (MediaSubsession*)clientData;
    RTSPClient* rtspClient = (RTSPClient*)subsession->miscPtr;
    UsageEnvironment& env = rtspClient->envir(); // alias
    
    env << *rtspClient << "Received RTCP \"BYE\" on \"" << *subsession << "\" subsession\n";
    
    // Now act as if the subsession had closed:
    subsessionAfterPlaying(subsession);
}

void streamTimerHandler(void* clientData) {
    ourRTSPClient* rtspClient = (ourRTSPClient*)clientData;
    StreamClientState& scs = rtspClient->scs; // alias
    
    scs.streamTimerTask = NULL;
    
    // Shut down the stream:
    shutdownStream(rtspClient);
}

void shutdownStream(RTSPClient* rtspClient, int exitCode) {
    UsageEnvironment& env = rtspClient->envir(); // alias
    StreamClientState& scs = ((ourRTSPClient*)rtspClient)->scs; // alias
    
    // First, check whether any subsessions have still to be closed:
    if (scs.session != NULL) {
        Boolean someSubsessionsWereActive = False;
        MediaSubsessionIterator iter(*scs.session);
        MediaSubsession* subsession;
        
        while ((subsession = iter.next()) != NULL) {
            if (subsession->sink != NULL) {
                Medium::close(subsession->sink);
                subsession->sink = NULL;
                
                if (subsession->rtcpInstance() != NULL) {
                    subsession->rtcpInstance()->setByeHandler(NULL, NULL); // in case the server sends a RTCP "BYE" while handling "TEARDOWN"
                }
                
                someSubsessionsWereActive = True;
            }
        }
        
        if (someSubsessionsWereActive) {
            // Send a RTSP "TEARDOWN" command, to tell the server to shutdown the stream.
            // Don't bother handling the response to the "TEARDOWN".
            rtspClient->sendTeardownCommand(*scs.session, NULL);
        }
    }
    
//    env << *rtspClient << "Closing the stream.\n";
    Medium::close(rtspClient);
    // Note that this will also cause this stream's "StreamClientState" structure to get reclaimed.
    
    if (--rtspClientCount == 0) {
        // The final stream has ended, so exit the application now.
        // (Of course, if you're embedding this code into your own application, you might want to comment this out,
        // and replace it with "eventLoopWatchVariable = 1;", so that we leave the LIVE555 event loop, and continue running "main()".)
    }
}


// Implementation of "ourRTSPClient":

ourRTSPClient* ourRTSPClient::createNew(UsageEnvironment& env, char const* rtspURL,
                                        int verbosityLevel, char const* applicationName, portNumBits tunnelOverHTTPPortNum) {
    return new ourRTSPClient(env, rtspURL, verbosityLevel, applicationName, tunnelOverHTTPPortNum);
}

ourRTSPClient::ourRTSPClient(UsageEnvironment& env, char const* rtspURL,
                             int verbosityLevel, char const* applicationName, portNumBits tunnelOverHTTPPortNum)
: RTSPClient(env,rtspURL, verbosityLevel, applicationName, tunnelOverHTTPPortNum, -1) {
}

ourRTSPClient::~ourRTSPClient() {
}


// Implementation of "StreamClientState":

StreamClientState::StreamClientState()
: iter(NULL), session(NULL), subsession(NULL), streamTimerTask(NULL), duration(0.0) {
}

StreamClientState::~StreamClientState() {
    delete iter;
    if (session != NULL) {
        // We also need to delete "session", and unschedule "streamTimerTask" (if set)
        UsageEnvironment& env = session->envir(); // alias
        
        env.taskScheduler().unscheduleDelayedTask(streamTimerTask);
        Medium::close(session);
    }
}


// Implementation of "DummySink":

// Even though we're not going to be doing anything with the incoming data, we still need to receive it.
// Define the size of the buffer that we'll use:
#define DUMMY_SINK_RECEIVE_BUFFER_SIZE 2764800

DummySink* DummySink::createNew(UsageEnvironment& env, MediaSubsession& subsession, char const* streamId) {
    return new DummySink(env, subsession, streamId);
}

DummySink::DummySink(UsageEnvironment& env, MediaSubsession& subsession, char const* streamId)
: MediaSink(env),
fSubsession(subsession) {
    fStreamId = strDup(streamId);
#warning 内存泄漏
    
    fReceiveBuffer = new u_int8_t[DUMMY_SINK_RECEIVE_BUFFER_SIZE];
//    avsync = [[AVSync alloc] init];
//    fReceiveBuffer = (u_int8_t*)malloc(sizeof(u_int8_t)*DUMMY_SINK_RECEIVE_BUFFER_SIZE);
}

DummySink::~DummySink() {
    delete[] fReceiveBuffer;
//    free(fReceiveBuffer);
    delete[] fStreamId;
}
static int firstFrame = 1;
void DummySink::afterGettingFrame(void* clientData, unsigned frameSize, unsigned numTruncatedBytes,
                                  struct timeval presentationTime, unsigned durationInMicroseconds) {
    DummySink* sink = (DummySink*)clientData;
    sink->afterGettingFrame(frameSize, numTruncatedBytes, presentationTime, durationInMicroseconds);
}


// If you don't want to see debugging output for each received frame, then comment out the following line:
#define DEBUG_PRINT_EACH_RECEIVED_FRAME 0

void DummySink::afterGettingFrame(unsigned frameSize, unsigned numTruncatedBytes,
                                  struct timeval presentationTime, unsigned /*durationInMicroseconds*/) {
    // We've just received a frame of data.  (Optionally) print out information about it:
#ifdef DEBUG_PRINT_EACH_RECEIVED_FRAME
    #if 0
    if (fStreamId != NULL) envir() << "Stream \"" << fStreamId << "\"; ";
    envir() << fSubsession.mediumName() << "/" << fSubsession.codecName() << ":\tReceived " << frameSize << " bytes";
    if (numTruncatedBytes > 0) envir() << " (with " << numTruncatedBytes << " bytes truncated)";
    char uSecsStr[6+1]; // used to output the 'microseconds' part of the presentation time
    sprintf(uSecsStr, "%06u", (unsigned)presentationTime.tv_usec);
    envir() << ".\tPresentation time: " << (int)presentationTime.tv_sec << "." << uSecsStr;
    if (fSubsession.rtpSource() != NULL && !fSubsession.rtpSource()->hasBeenSynchronizedUsingRTCP()) {
        envir() << "!"; // mark the debugging output to indicate that this presentation time is not RTCP-synchronized
    }
    #endif
#ifdef DEBUG_PRINT_NPT
//    envir() << "\tNPT: " << fSubsession.getNormalPlayTime(presentationTime);
#endif
//    envir() << "\n";
#endif

//    envir() << frameSize <<"\n";
    
//    printf("presentationTime = %f   mediaType:%s \n",fSubsession.getNormalPlayTime(presentationTime),fSubsession.mediumName());
    if (!strcmp(fSubsession.mediumName(), "audio"))
    {
     /*
      这里时间戳对应音视频的前后时间播放顺序
      */
//        printf("audio type = %s \n",fSubsession.codecName());
        double audioPlayTime = fSubsession.getNormalPlayTime(presentationTime);
        printf("audio presentationTime = %f \n",audioPlayTime);
        RtspConnection *rtspConnection = [RtspConnection shareStore];
        [rtspConnection.delegate decodeAudioUnit:fReceiveBuffer Size:frameSize];
        
    }
    else if (!strcmp(fSubsession.mediumName(), "video"))
    {
//        printf("audio type = %s \n",fSubsession.codecName());
        double videoPlayTime = fSubsession.getNormalPlayTime(presentationTime);
        printf("Video presentationTime = %f \n",videoPlayTime);
        RtspConnection *rtspConnection = [RtspConnection shareStore];
        [rtspConnection.delegate decodeNalu:fReceiveBuffer Size:frameSize];
    }
    
    // Then continue, to request the next frame of data:
    continuePlaying();
}

Boolean DummySink::continuePlaying() {
    if (fSource == NULL) return False; // sanity check (should not happen)
    
    // Request the next frame of data from our input source.  "afterGettingFrame()" will get called later, when it arrives:
    fSource->getNextFrame(fReceiveBuffer, DUMMY_SINK_RECEIVE_BUFFER_SIZE,
                          afterGettingFrame, this,
                          onSourceClosure, this);
    return True;
}

-(void)start_rtsp_session:(BOOL)online rtspAddress:(NSString *)str
{
    
    //    [Decoder_Ffmpeg ffmpeg_264_decoder].delegate = delegate;
    
    TaskScheduler* scheduler = BasicTaskScheduler::createNew();
    UsageEnvironment* env = BasicUsageEnvironment::createNew(*scheduler);
    
    // We need at least one "rtsp://" URL argument:
    
    // There are argc-1 URLs: argv[1] through argv[argc-1].  Open and start streaming each one:
//    NSString * str = nil;
//    if ([[AWTools getIPAddress] hasPrefix:IP_Segment]) {
//        str = h264_add;
//    }else
//    {
//        str = [NSString stringWithFormat:@"rtsp://%@:7070/H264VideoSMS",[AWTools routerIp]];
//    }
//    str = h264_add;
    //    openURL(*env, "rtsp_test", [str UTF8String]);
    RTSPClient* rtspClient = ourRTSPClient::createNew(*env, [str UTF8String], RTSP_CLIENT_VERBOSITY_LEVEL, "rtsp_test");
    if (rtspClient == NULL) {
        
        return;
    }
    
    ++rtspClientCount;
    
    // Next, send a RTSP "DESCRIBE" command, to get a SDP description for the stream.
    // Note that this command - like all RTSP commands - is sent asynchronously; we do not block, waiting for a response.
    // Instead, the following function call returns immediately, and we handle the RTSP response later, from within the event loop:
    rtspClient->sendDescribeCommand(continueAfterDESCRIBE);
    
    // All subsequent activity takes place within the event loop:
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        if (!env) {
            return ;
        }
        if (!rtspClient) {
            return;
        }
        eventLoopWatchVariable=0;
        env->taskScheduler().doEventLoop(&eventLoopWatchVariable);
        
        //先判断rtcpInstance()连接是否存在，如果不存在就不要释放资源不然容易造成闪退
        StreamClientState& scs = ((ourRTSPClient*)rtspClient)->scs;
        if (scs.streamTimerTask != NULL) {
            shutdownStream(rtspClient);
        }
    });
    
}

-(void)close_rtsp_client
{
    NSLog(@"关闭rtsp");
    eventLoopWatchVariable=1;
}

-(BOOL)isConnecting
{
    if (eventLoopWatchVariable == 0) {
        return YES;
    }
    else return NO;
}



int sthvalue(char c)
{
        int value;
        if((c >= '0') && (c <= '9'))
                value = 48;
        else if ((c >= 'a') && (c <='f'))
                value = 87;
        else if ((c >= 'A') && (c <='F'))
                value = 55;
        else {
                printf("invalid data %c",c);
                return -1;
        }
        return value;
}
/*转化函数，把字符串和一个数组当做参数，这个函数会把str的值，每两个组合成一个16进制的数*/
int strtohex(char *str, char *data)
{
        int len =0;
        int sum =0;
        int high=0;
        int low=0;
        int value=0;
        int j=0;
        len = strlen(str);//获取字符串的字符个数
        //char data[256] = {0};
        printf("%d\n", len);
        //在for循环中，从0开始，每两个数组成一个16进制，高4位和低4位，然后放技能数组中去
        for(int i=0; i<len; i++)
        {

//              printf("high-n:0x%02x\n", str[i]);
                value = sthvalue(str[i]);
                high = (((str[i]-value)&0xF)<<4);//获取数据，成为高4位
//              printf("high:0x%02x\n", high);
//              printf("low-n:0x%02x\n", str[i+1]);
                value = sthvalue(str[i+1]);
                low = ((str[i+1]-value)&0xF);//获取数据，成为低4位
//              printf("low:0x%02x\n", low);
                sum = high | low; //组合高低四位数，成为一byte数据
//              printf("sum:0x%02x\n", sum);
                j = i / 2; //由于两个字符组成一byte数，这里的j值要注意
                data[j] = sum;//把这byte数据放到数组中
                i=i+1; //每次循环两个数据，i的值要再+1
        }
        return len;
}


@end
