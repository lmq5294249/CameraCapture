/***************************************************************************
 
 ***************************************************************************/
//#include "StdAfx.h"
#include "mjpegwrt.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include <time.h>
#include <string.h>
#include <strings.h>
#include <stddef.h>
#include <string.h>
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>


#define round(x)  ((int)(x+0.5))
typedef unsigned int __uint32_t;
typedef signed int __int32_t;
typedef unsigned short __uint16_t;
typedef signed short __int16_t;
typedef unsigned long long __uint64_t;
typedef signed long long __int64_t;
#define _strdup strdup



#ifdef __GLIBC__
#include <unistd.h>
#endif

#ifndef O_BINARY
#define O_BINARY	0
#endif

#if defined(WIN32) || defined (_WIN32)
#define fsync _commit
#endif

#define HEADERBYTES 0x1000			// 4k
#define DEFCACHE_SZ	0x100000		// 1M

#define MAXSOFTDESC_SZ	30
#define MAXCOMMENT_SZ	64
#define MAXDATE_SZ		22
int OSGetTickCount();

#pragma pack(push, 2)

CMjpeg2AVI CMjpeg;
/*
 int write(FILE * fd,  const void * pdata ,size_t len );
 int close(FILE * fd);
 int OSGetTickCount();
 
 int write(FILE * fd,  const void * pdata ,size_t len ){
 return fwrite(pdata, 1, len, fd);
 }
 
 int close(FILE * fd){
 fclose((FILE *) fd);
 return 0;
 }
*/
struct RiffChunk
{
	__uint32_t ckID;				// fourcc
	__uint32_t ckSize;				// size of chunk data
	unsigned char *ckData;			// chunk data
};

// size - 56
struct AVIHeader
{
	__uint32_t dwMicroSecPerFrame;
	__uint32_t dwMaxBytesPerSec;	//
	__uint32_t dwReserved1;			// must be 0
	__uint32_t dwFlags;				// 0 ?
	__uint32_t dwTotalFrames;
	__uint32_t dwInitialFrames;		// here must be 0
	__uint32_t dwStreams;			// number of streams
	__uint32_t dwSuggestedBufferSize;
	__uint32_t dwWidth;				// width of frame
	__uint32_t dwHeight;			// height of frame
	__uint32_t dwReserved[4];		// all must be 0
};

// size - 56
struct AVIStreamHeader
{
	__uint32_t fccType;				// 'vids'
	__uint32_t fccHandler;			// 'mjpg'
	__uint32_t dwFlags;				// here 0
	__uint16_t wPriority;			// here 0
	__uint16_t wLanguage;			// here 0
	__uint32_t dwInitialFrames;		// here 0
	__uint32_t dwScale;				// dwMicroSecPerFrame
	__uint32_t dwRate;				// 1000000
	__uint32_t dwStart;				// here 0
	__uint32_t dwLength;			// dwTotalFrames
	__uint32_t dwSuggestedBufferSize;	//  size largest chunk in the stream
	__uint32_t dwQuality;			// from 0 to 10000
	__uint32_t dwSampleSize;		// here 0
	struct							// here all field zero
	{
		__uint16_t left;
		__uint16_t top;
		__uint16_t right;
		__uint16_t bottom;
	} rcFrame;
};

// size - 40
struct AVIStreamFormat
{
	__uint32_t biSize;				// must be 40
	__int32_t   biWidth;			// width of frame
	__int32_t   biHeight;			// height of frame
	__uint16_t biPlanes;			// here must be 1
	__uint16_t biBitCount;			// here must be 24
	__uint32_t biCompression;		// here 'MJPG' or 0x47504A4D
	__uint32_t biSizeImage;			// size, in bytes, of the image (in D90_orig.avi 2764800)
	__int32_t   biXPelsPerMeter;	// here 0
	__int32_t   biYPelsPerMeter;	// here 0
	__uint32_t biClrUsed;			// here 0
	__uint32_t biClrImportant;		// here 0
};

struct AVIIndexChunk
{
	__uint32_t ckID;
	__uint32_t flags;				// unknown?
	__uint32_t offset;				// offset from 'movi' to video frame chunk
	__uint32_t size;				// size of video frame chunk
};

#pragma pack(pop)

typedef struct
{
	int fd;							// file descriptor
	__uint32_t realHeaderSize;
	__uint32_t frames;
	double fps;
	unsigned char* index;
	__uint32_t index_curpos;
	__uint32_t* pindex_real_size;
	__uint32_t index_size;
	unsigned char* header;
	__uint32_t *pFileSize;
	__uint32_t *pDataSize;
	struct AVIHeader* aviheader;
	struct AVIStreamHeader* avistreamheader;
	struct AVIStreamFormat* avistreamformat;
	char* pSoftStr;
	char* pCommentStr;
	char* pDateStr;
	unsigned char* cache;
	unsigned int cache_sz;
	unsigned int cache_pos;
} RIFFFILE;



int OSGetTickCount()
{
    
	// this is not true implementation of GetTickCount() for Unix
	// but it usefull to compute time difference.
	static int start_time_sec = 0;
	struct timeval tv;
	if (start_time_sec == 0)			// first call
	{
		gettimeofday(&tv, NULL);
		start_time_sec = tv.tv_sec;
	}
	gettimeofday(&tv, NULL);
	// to exclude integer overflow decrement start time.
	return (tv.tv_sec - start_time_sec)*1000 + tv.tv_usec/1000;
}


CMjpeg2AVI::CMjpeg2AVI(void)
{
    pThis = NULL;
    iErrCode = 0;
    m_FramesCount = 0;
    
    m_FileSizeTimer = 50 * 1024 * 1024;
    m_TimeTimer     = -1;
    m_FramesTimer = -1;
    m_CurFileSize    =   0;
    
    dStableFPS = 25.0;
    m_BufferSize =  1 * 1024 * 1024;
    m_StopWriteTime = 0;
    m_StartWriteTime = 0;
    m_frame_width    = 640;
    m_frame_height  = 480;
    strcpy(szSoftwareInfo,"JiangYong");
    strcpy(szMovieInfo,"Movie");
    szAviFileName = NULL;
    szImageFileName = NULL;
    time_t t = time(0);
    struct tm* tm = localtime(&t);
    sprintf(szDate, "%04u/%02u/%02u %02u:%02u:%02u", tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday, tm->tm_hour, tm->tm_min, tm->tm_sec);
    m_AllFramesCount = 0;
    m_SkippedCount = 0;
    m_DuplicatedCount = 0;
    m_ElapsedTime = 0;
    
    m_TempTime1 = 0;
    m_TempTime2  = 0;
    m_TempTime3  = 0;
    bStopFromInside = false;
    bUseStabFPS = true;
    m_StableFPSCount = 0;
    bContinueRec = true;
    bRun = false;
}

CMjpeg2AVI::~CMjpeg2AVI(void)
{
    pThis = NULL;
    iErrCode=0;
    m_FramesCount = 0;
    dStableFPS = 25.0;
    if (szAviFileName)
    {
        free(szAviFileName);
    }
    if (szImageFileName)
    {
        free(szImageFileName);
    }
}


///< set record fine name
int  CMjpeg2AVI::SetAviFileName(const char* fname)
{
    if (szAviFileName)
    {
        free(szAviFileName);
        //__android_log_write(ANDROID_LOG_ERROR,"JNI","free(szAviFileName);");
    }
    szAviFileName = _strdup(fname);
    return 0;
}

int  CMjpeg2AVI::SetImaFileName(const char* fname)
{
    if (szImageFileName)
    {
        free(szImageFileName);
    }
    szImageFileName = _strdup(fname);
    return 0;
}

///< start record video
int  CMjpeg2AVI::On(void)
{
    //printf("lib On \n");
    bRun = true;
    return 0;
}

///< stop record video
int  CMjpeg2AVI::Off(void)
{
    //printf("lib Off \n");
    bRun = false;
    StopRecord();
    return 0;
}

int  CMjpeg2AVI::Snapshot(void)	//快照
{
    bSnapshot = true;
    return 0;
}

int  CMjpeg2AVI::doSnapshot(unsigned char *pData,int iDateSize)
{
    if (true != bSnapshot)
    {
        return -1;
    }
    if (NULL == szImageFileName)
    {
        return -2;
    }
    int fd = open(szImageFileName, O_BINARY | O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0)
    {
        bSnapshot = false;
        return 3;
    }
    write(fd,pData,iDateSize);
    close(fd);
    bSnapshot = false;
    return 0;
}

int  CMjpeg2AVI::Run(unsigned char *pData,int iDateSize)
{
    //printf("lib Run invoke\n");
    if(true == bRun)
    {
        StartRecord();
        WriteOneFrame(pData,iDateSize);
        UpdateFps();
        //__android_log_write(ANDROID_LOG_ERROR,"JNI","RECORD....");
        return 0;
    }
    else
    {
        StopRecord();
        return -1;
    }
    return 0;
}

int  CMjpeg2AVI::StartRecord(void)
{
    
    if (NULL == szAviFileName)
    {
        //__android_log_write(ANDROID_LOG_ERROR,"JNI","NULL == szAviFileName");
        return -1;                    //liyingquan
    }
    
    if (NULL  != pThis)
    {
        //__android_log_write(ANDROID_LOG_ERROR,"JNI","NULL  != pThis");
        return -1;
    }
    
    m_FramesCount = 0;
    // m_FileSizeTimer = 50 * 1024 * 1024;
    m_FileSizeTimer = 50 * 1024 * 1024;
    m_TimeTimer     = -1;
    m_FramesTimer = -1;
    m_CurFileSize    =   0;
    
    dStableFPS = 25.0;
    //m_BufferSize =  1 * 1024 * 1024;
    m_BufferSize =  1 * 1024 * 1024;
    m_StopWriteTime = 0;
    m_StartWriteTime = 0;
    strcpy(szSoftwareInfo,"JiangYong");
    strcpy(szMovieInfo,"CamOne Movie");
    //szFileName = _strdup("abcdefg.avi");
    m_frame_width    = 640;
    m_frame_height  = 480;
    time_t t = time(0);
    struct tm* tm = localtime(&t);
    sprintf(szDate, "%04u/%02u/%02u %02u:%02u:%02u", tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday, tm->tm_hour, tm->tm_min, tm->tm_sec);
    m_AllFramesCount = 0;
    m_SkippedCount = 0;
    m_DuplicatedCount = 0;
    m_ElapsedTime = 0;
    
    m_TempTime1 = 0;
    m_TempTime2  = 0;
    m_TempTime3  = 0;
    bStopFromInside = false;
    bUseStabFPS = true;
    m_StableFPSCount = 0;
    bContinueRec = true;
    
    pThis = mjpegCreateFile(szAviFileName);
    if(NULL == pThis)
    {
//        __android_log_write(ANDROID_LOG_ERROR,"JNI","文件创建失败");
        return -2;
    }else
    {
//        __android_log_write(ANDROID_LOG_ERROR,"JNI","文件创建成功");
    }
    
    m_CurFileSize += sizeof(RIFFFILE);
    m_Max_frame_size = 0;
    m_StartWriteTime  = OSGetTickCount();
    m_TempTime1  = m_StartWriteTime;
    m_TempTime2  = m_StartWriteTime;
    m_TempTime3  = m_StartWriteTime;
    bStopFromInside = false;
    
    mjpegSetup(pThis, 0, 0, dStableFPS, 10000);
    if (!mjpegSetCache(pThis, m_BufferSize))
    {
        //__android_log_write(ANDROID_LOG_ERROR,"JNI","kk8");
        // QApplication::postEvent(Owner, new GCameraEvent(CAMERA_EVENT_SHOWMSG, tr("Can't alloc buffer with size %1 MB").arg(BufferSize/(1024*1024))));
        return -3;
    }
    // here we read buffer - this is not a critical section
    //mjpegWriteChunk(pThis, (unsigned char*)live_buffer::frame, live_buffer::frame_size);
    //WritenCount++;
    //printf("lib StartRecord invoke\n");
    return 0;
    ///< 内存泄漏
}

/*
 
 int  CMjpeg2AVI::StartRecord(void)
 {
 if (NULL == szAviFileName)
 {
 return -1;
 }
 
 if (NULL  != pThis)
 {
 return -1;
 }
 
 m_FramesCount = 0;
 m_FileSizeTimer = 50 * 1024 * 1024;
 m_TimeTimer     = -1;
 m_FramesTimer = -1;
 m_CurFileSize    =   0;
 
 dStableFPS = 25.0;
 m_BufferSize =  1 * 1024 * 1024;
 m_StopWriteTime = 0;
 m_StartWriteTime = 0;
 strcpy(szSoftwareInfo,"JiangYong");
 strcpy(szMovieInfo,"CamOne Movie");
 //szFileName = _strdup("abcdefg.avi");
 time_t t = time(0);
 struct tm* tm = localtime(&t);
 sprintf(szDate, "%04u/%02u/%02u %02u:%02u:%02u", tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday, tm->tm_hour, tm->tm_min, tm->tm_sec);
 m_AllFramesCount = 0;
 m_SkippedCount = 0;
 m_DuplicatedCount = 0;
 m_ElapsedTime = 0;
 
 m_TempTime1 = 0;
 m_TempTime2  = 0;
 m_TempTime3  = 0;
 bStopFromInside = false;
 bUseStabFPS = true;
 m_StableFPSCount = 0;
 bContinueRec = true;
 
 pThis = mjpegCreateFile(szAviFileName);
 if(NULL == pThis)
 {
 return -2;
 }
 
 m_CurFileSize += sizeof(RIFFFILE);
 m_Max_frame_size = 0;
 m_StartWriteTime  = OSGetTickCount();
 m_TempTime1  = m_StartWriteTime;
 m_TempTime2  = m_StartWriteTime;
 m_TempTime3  = m_StartWriteTime;
 bStopFromInside = false;
 
 mjpegSetup(pThis, 0, 0, dStableFPS, 10000);
 if (!mjpegSetCache(pThis, m_BufferSize))
 {
 //QApplication::postEvent(Owner, new GCameraEvent(CAMERA_EVENT_SHOWMSG, tr("Can't alloc buffer with size %1 MB").arg(BufferSize/(1024*1024))));
 return -3;
 }
 // here we read buffer - this is not a critical section
 //mjpegWriteChunk(pThis, (unsigned char*)live_buffer::frame, live_buffer::frame_size);
 //WritenCount++;
 return 0;
 ///< 内存泄漏
 }
 */


int  CMjpeg2AVI::WriteOneFrame(unsigned char *pData,int iDateSize)
{
    long long int MustBeFrames;	// need to control stable fps recording
    
    if (NULL == pThis)
    {
        return 0;
    }
    
    if (m_Max_frame_size < iDateSize)
    {
        m_Max_frame_size = iDateSize;
    }
    NSLog(@"MAX = %d",m_Max_frame_size);
    NSLog(@"size = %d",iDateSize);
    m_CurFileSize += iDateSize;
    
    // here we read buffer - this is not a critical section
    mjpegWriteChunk(pThis, pData, iDateSize);
    m_FramesCount++;
    if (pThis)
    {
        if (m_FramesCount > 10)
        {
            if (!bUseStabFPS)
            {
                mjpegWriteChunk(pThis, pData,iDateSize);
                m_FramesCount++;
            }
            else
            {
                MustBeFrames = (int)round((double)(OSGetTickCount() - m_StartWriteTime)*dStableFPS/1000.0);
                if (MustBeFrames < m_FramesCount + 1)			// too fast, we must skip frame
                {
                    NSLog(@"too fast!!!");
                    ;										// do nothing...
                }
                else
                {
                    mjpegWriteChunk(pThis, pData, iDateSize);
                    m_FramesCount++;
                    while (MustBeFrames > m_FramesCount)		// too less, we must add dublicated frames
                    {
                        NSLog(@"too slow!!!");
                        mjpegWriteChunk(pThis, pData, iDateSize);
                        m_FramesCount++;
                        m_DuplicatedCount++;
                        // __android_log_write(ANDROID_LOG_ERROR,"JNI","li1");
                    }
                }
            }
        }
        else
        {
            mjpegWriteChunk(pThis, pData, iDateSize);
            m_FramesCount++;
        }
        if (m_FramesCount - m_DuplicatedCount >= m_FramesTimer - 1 && m_FramesTimer > 0)
        {
            bStopFromInside = true;
            //__android_log_write(ANDROID_LOG_ERROR,"JNI","kk2");
        }
        if (OSGetTickCount() - m_StartWriteTime >= m_TimeTimer && m_TimeTimer > 0)
        {
            bStopFromInside = true;
            //__android_log_write(ANDROID_LOG_ERROR,"JNI","kk3");
        }
        ///< 获取当前文件大小
        //if (m_CurFileSize >= m_FileSizeTimer && m_FileSizeTimer > 0)
        {
            //    bStopFromInside = true;
        }
    }
    
    /*if (true == bStopFromInside)
     {
     StopRecord();
     if (true == bContinueRec)
     {
     StartRecord();
     }
     else
     {
     //__android_log_write(ANDROID_LOG_ERROR,"JNI","完成录像了");
     return 0;///< 完成录像了
     }
     }*/
    return 0;
}

int  CMjpeg2AVI::End()
{
    StopRecord();
    return 0;
}

int  CMjpeg2AVI::UpdateFps(void)
{
	// for temp fps
	int TempFrameCount = 0;
	double TempFPS;
	if (NULL == pThis)
	{
        return -1;
	}
	// calc temp fps
	/*	if (m_TempTime2 - m_TempTime1 >= 2000)
     {
     __android_log_write(ANDROID_LOG_ERROR,"JNI","k1k");
     TempFPS = ((double)TempFrameCount*1000.0)/(double)(m_TempTime2 - m_TempTime1);
     m_TempTime1 = m_TempTime2;
     TempFrameCount = 0;
     m_StableFPSCount++;
     if (m_StableFPSCount == 2)
     dStableFPS = TempFPS;
     else if (m_StableFPSCount > 2 && m_StableFPSCount < 5)
     dStableFPS = ((double)(m_StableFPSCount - 2)*dStableFPS + TempFPS)/(double)(m_StableFPSCount - 1);
     //if (Owner)
     {
     //QApplication::postEvent(Owner, new GCameraEvent(CAMERA_EVENT_FPS_UPDATED, QVariant(TempFPS)));
     //if (StableFPSCount == 4)
     //	QApplication::postEvent(Owner, new GCameraEvent(CAMERA_EVENT_FPS_CALCULATED, QVariant((int)StableFPS)));
     }
     }
     m_TempTime2 = OSGetTickCount();*/
	return 0;
}


int  CMjpeg2AVI::StopRecord(void)
{
    if (pThis)
    {
        m_StopWriteTime = OSGetTickCount();
        double fps = ((double)m_FramesCount*1000.0)/(double)(m_StopWriteTime - m_StartWriteTime);
        if (fps > 60.0)
        {
            fps = 60.0;
            
        }
        mjpegSetup(pThis, m_frame_width, m_frame_height, fps, 10000);
        mjpegSetMaxChunkSize(pThis, m_Max_frame_size);
        time_t t = time(0);
        struct tm* tm = localtime(&t);
        sprintf(szDate, "%04u/%02u/%02u %02u:%02u:%02u", tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday, tm->tm_hour, tm->tm_min, tm->tm_sec);
        mjpegSetInfo(pThis, szSoftwareInfo, szMovieInfo, szDate);
        mjpegCloseFile(pThis);
        //printf("lib StopRecord invoke\n");
        pThis = 0;
    }
    return 0;
}

void* CMjpeg2AVI::mjpegCreateFile(const char* fname)
{
	int fd = open(fname, O_BINARY | O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fd < 0)
		return 0;
    
	RIFFFILE* riff = (RIFFFILE*)malloc(sizeof(RIFFFILE));
	if (!riff)
	{
		close(riff->fd);
		return 0;
	}
	memset(riff, 0, sizeof(RIFFFILE));
	riff->fd = fd;
	riff->header = (unsigned char*)malloc(HEADERBYTES);
	if (!riff->header)
	{
		close(riff->fd);
		free(riff);
		return 0;
	}
	memset(riff->header, 0, HEADERBYTES);
    
	riff->index_size = 0x100;
	riff->index = (unsigned char*)malloc(riff->index_size);
	if (!riff->index)
	{
		close(riff->fd);
		free(riff->header);
		free(riff);
		return 0;
	}
    
	riff->pFileSize = (__uint32_t*)(riff->header + 4);
	*riff->pFileSize = HEADERBYTES - 8;
	__uint32_t* pnum = 0;
	__uint32_t offset = 0;
	char* ptr = (char*)riff->header;					// addr = 0
	strncpy(ptr, "RIFF", 4);
	offset += 8;
	ptr = (char*)(riff->header + offset);				// addr = 8
	strncpy(ptr, "AVI LIST", 8);
	offset += 8;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 16
	*pnum = 40 + sizeof(struct AVIHeader) + sizeof(struct AVIStreamHeader) + sizeof(struct AVIStreamFormat);
	offset += 4;
	ptr = (char*)(riff->header + offset);				// addr = 20
	strncpy(ptr, "hdrlavih", 8);
	offset += 8;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 28
	*pnum = sizeof(struct AVIHeader);
	offset += 4;
	riff->aviheader = (struct AVIHeader*)(riff->header + offset);	// addr = 32
	riff->aviheader->dwStreams = 1;						// only video stream
	riff->aviheader->dwFlags = 0x110;					// has index & interlieved
	offset += sizeof(struct AVIHeader);
	ptr = (char*)(riff->header + offset);				// addr = 88
	strncpy(ptr, "LIST", 4);
	offset += 4;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 92
	*pnum = 20 + sizeof(struct AVIStreamHeader) + sizeof(struct AVIStreamFormat);
	offset += 4;
	ptr = (char*)(riff->header + offset);				// addr = 96
	strncpy(ptr, "strlstrh", 8);
	offset += 8;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 104
	*pnum = sizeof(struct AVIStreamHeader);
	offset += 4;
	riff->avistreamheader = (struct AVIStreamHeader*)(riff->header + offset);	// addr = 108
	riff->avistreamheader->fccType = 0x73646976;		// 'vids'
	riff->avistreamheader->fccHandler = 0x67706a6d;		// 'mjpg'
	offset += sizeof(struct AVIStreamHeader);
	ptr = (char*)(riff->header + offset);				// addr = 164
	strncpy(ptr, "strf", 4);
	offset += 4;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 168
	*pnum = sizeof(struct AVIStreamFormat);
	offset += 4;
	riff->avistreamformat = (struct AVIStreamFormat*)(riff->header + offset);	// addr = 172
	offset += sizeof(struct AVIStreamFormat);
    
	ptr = (char*)(riff->header + offset);				// addr = 212
	strncpy(ptr, "LIST", 4);
	offset += 4;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 216
	*pnum = 12 + MAXSOFTDESC_SZ + 8 + MAXCOMMENT_SZ + 8 + MAXDATE_SZ;	// ISFT, ICMT & ICRD
	offset += 4;
	ptr = (char*)(riff->header + offset);				// addr = 220
	strncpy(ptr, "INFOISFT", 8);
	offset += 8;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 228
	*pnum = MAXSOFTDESC_SZ;								// ISFT
	offset += 4;
	riff->pSoftStr = (char*)(riff->header + offset);	// addr = 232
	// fill this later
	offset += MAXSOFTDESC_SZ;
	ptr = (char*)(riff->header + offset);				// addr = 262
	strncpy(ptr, "ICMT", 4);
	offset += 4;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 266
	*pnum = MAXCOMMENT_SZ;								// ICMT
	offset += 4;
	riff->pCommentStr = (char*)(riff->header + offset);	// addr = 270
	// fill this later
	offset += MAXCOMMENT_SZ;
    
	ptr = (char*)(riff->header + offset);				// addr = 334
	strncpy(ptr, "ICRD", 4);
	offset += 4;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 338
	*pnum = MAXDATE_SZ;									// ICRD
	offset += 4;
	riff->pDateStr = (char*)(riff->header + offset);	// addr = 342
	// fill this later
	offset += MAXDATE_SZ;
    
	riff->realHeaderSize = offset;
    
	// JUNK chunk
	ptr = (char*)(riff->header + offset);				// addr = 364
	strncpy(ptr, "JUNK", 4);
	offset += 4;
	__uint32_t junk_size = HEADERBYTES - riff->realHeaderSize - 20;
	pnum = (__uint32_t*)(riff->header + offset);		// addr = 368
	*pnum = junk_size;
	offset += 4;
    
	ptr = (char*)(riff->header + HEADERBYTES - 12);		// addr = 4084
	strncpy(ptr, "LIST", 4);
	riff->pDataSize = (__uint32_t*)(riff->header + HEADERBYTES - 8);	// 4088
	*riff->pDataSize = 4;
	ptr += 8;											// addr = 4092
	strncpy(ptr, "movi", 4);
    
	// for index chunk
	riff->pindex_real_size = (__uint32_t*)(riff->index + 4);
	ptr = (char*)riff->index;
	strncpy(ptr, "idx1", 4);
	*riff->pindex_real_size = 0;
	riff->index_curpos = 8;
	*riff->pFileSize += 8;
    
	riff->cache_sz = DEFCACHE_SZ;
	riff->cache_pos = 0;
	riff->cache = (unsigned char*)malloc(riff->cache_sz);
	if (!riff->cache)
	{
		close(riff->fd);
		free(riff->header);
		free(riff->index);
		free(riff);
		return 0;
	}
    
	if (!write(riff->fd, riff->header, HEADERBYTES))
	{
		close(riff->fd);
		free(riff->header);
		free(riff->index);
		free(riff);
		return 0;
	}
    
	return (void*)riff;
}

static int cached_write(RIFFFILE* rf, const void* buf, unsigned int sz)
{
	if (!rf || !rf->cache)
		return -1;
	int res = 0;
	int inbuf_pos = 0;
	char* ptr = (char*)rf->cache + rf->cache_pos;
	char* buf_ptr = (char*)buf;
	if (rf->cache_pos + sz > rf->cache_sz)
	{
		inbuf_pos = rf->cache_sz - rf->cache_pos;
		memcpy(ptr, buf_ptr, inbuf_pos);
		res = write(rf->fd, rf->cache, rf->cache_sz);
		if (res > 0)
		{
			rf->cache_pos = 0;
			ptr = (char*)rf->cache;
		}
		else
			return res;
        
		buf_ptr += inbuf_pos;
		int full_count = (sz - inbuf_pos)/rf->cache_sz;
		if (full_count > 0)
		{
			unsigned int f_pos = full_count*rf->cache_sz;
			res = write(rf->fd, buf_ptr, f_pos);
			if (res != f_pos)
				return res;
			inbuf_pos += f_pos;
			buf_ptr += f_pos;
		}
	}
	memcpy(ptr, buf_ptr, sz - inbuf_pos);
	rf->cache_pos += sz - inbuf_pos;
	return sz;
}

static int cache_flush(RIFFFILE* rf)
{
	if (!rf || !rf->cache)
		return -1;
	if (rf->cache_pos > 0)
	{
		int res = write(rf->fd, rf->cache, rf->cache_pos);
		if (res > 0)
			rf->cache_pos = 0;
		fsync(rf->fd);
		return res;
	}
	return 0;
}

int CMjpeg2AVI::mjpegSetup(void* p, int fwidth, int fheight, double fps, int quality)
{
	RIFFFILE* rf = (RIFFFILE*)p;
	if (!rf)
		return 0;
	rf->fps = fps;
	//memset(rf->aviheader, 0, sizeof(struct AVIHeader));
	rf->aviheader->dwMicroSecPerFrame = (__uint32_t)(1000000.0/fps);
	rf->aviheader->dwWidth = fwidth;
	rf->aviheader->dwHeight = fheight;
	//memset(rf->avistreamheader, 0, sizeof(struct AVIStreamHeader));
	rf->avistreamheader->dwScale = 1000;
	rf->avistreamheader->dwRate = (__uint32_t)(1000.0*fps);
	rf->avistreamheader->dwQuality = quality;
	//memset(rf->avistreamformat, 0, sizeof(struct AVIStreamFormat));
	rf->avistreamformat->biSize = 40;
	rf->avistreamformat->biWidth = fwidth;
	rf->avistreamformat->biHeight = fheight;
	rf->avistreamformat->biPlanes = 1;
	rf->avistreamformat->biBitCount = 24;
	rf->avistreamformat->biCompression = 0x47504A4D;			// 'MJPG'
	rf->avistreamformat->biSizeImage = fwidth*fheight*3;
	return 1;
}

int CMjpeg2AVI::mjpegSetInfo(void* p, const char* software, const char* comment, const char* date)
{
	RIFFFILE* rf = (RIFFFILE*)p;
	if (!rf)
		return 0;
	if (software)
	{
		strncpy(rf->pSoftStr, software, MAXSOFTDESC_SZ - 1);
		rf->pSoftStr[MAXSOFTDESC_SZ - 1] = 0;
	}
	else
		rf->pSoftStr[0] = 0;
	if (comment)
	{
		strncpy(rf->pCommentStr, comment, MAXCOMMENT_SZ - 1);
		rf->pCommentStr[MAXCOMMENT_SZ - 1] = 0;
	}
	else
		rf->pCommentStr[0] = 0;
	if (date)
	{
		strncpy(rf->pDateStr, date, MAXDATE_SZ - 1);
		rf->pDateStr[MAXDATE_SZ - 1] = 0;
	}
	else
		rf->pDateStr[0] = 0;
	return 1;
}

int CMjpeg2AVI::mjpegSetCache(void* p, int sz)
{
	RIFFFILE* rf = (RIFFFILE*)p;
	if (!rf)
		return 0;
	unsigned char* tmp = (unsigned char*)malloc(sz);
	if (!tmp)
		return 0;
	free(rf->cache);
	rf->cache = tmp;
	rf->cache_sz = sz;
	return 1;
}

int CMjpeg2AVI::mjpegSetMaxChunkSize(void* p, unsigned int sz)
{
	RIFFFILE* rf = (RIFFFILE*)p;
	if (!rf)
		return 0;
	rf->aviheader->dwSuggestedBufferSize = sz;
	rf->aviheader->dwMaxBytesPerSec = (int)(sz*rf->fps) + 1;
	rf->avistreamheader->dwSuggestedBufferSize = sz;
	return 1;
}

int CMjpeg2AVI::mjpegWriteChunk(void* p, const unsigned char* jpeg_data, unsigned int size)
{
	RIFFFILE* rf = (RIFFFILE*)p;
	if (!rf)
		return 0;
	if (!rf->index)
		return 0;
	if (rf->index_curpos + sizeof(struct AVIIndexChunk) > rf->index_size)
	{
		unsigned char* p = (unsigned char*)realloc(rf->index, rf->index_size + 0x100);
		if (p)
		{
			rf->index = p;
			rf->pindex_real_size = (__uint32_t*)(rf->index + 4);
			rf->index_size += 0x100;
		}
		else
		{
			//printf("FATAL: Can't realloc memory for index chunk!\n");
			//__android_log_write(ANDROID_LOG_ERROR,"JNI","FATAL: Can't realloc memory for index chunk!");
			free(rf->index);
			rf->index = 0;
			return 0;
		}
	}
    
	char buff[9];
	strncpy(buff, "00dc", 4);
	__uint32_t* pnum = (__uint32_t*)(buff + 4);
	*pnum = (__uint32_t)size;
	if (cached_write(rf, buff, 8) != 8)
		return 0;
	if (cached_write(rf, jpeg_data, size) != size)
		return 0;
	if (size % 2 != 0)
	{
		char junk = 0;
		if (cached_write(rf, &junk, 1) != 1)
			return 0;
	}
	// fill index
	__uint32_t key_frame = (__uint32_t)(rf->fps);
	struct AVIIndexChunk* ick = (struct AVIIndexChunk*)(rf->index + rf->index_curpos);
	ick->ckID = 0x63643030;					// '00dc'
	ick->flags = (rf->frames % key_frame == 0) ? 0x10 : 0;
	ick->offset = *rf->pDataSize;
	ick->size = (__uint32_t)size;
	rf->index_curpos += sizeof(struct AVIIndexChunk);
	*rf->pindex_real_size += sizeof(struct AVIIndexChunk);
	// increase counters
	*rf->pDataSize += size + 8;
	*rf->pFileSize += size + 8 + sizeof(struct AVIIndexChunk);
	rf->frames++;
	if (size % 2 != 0)
	{
		*rf->pDataSize += 1;
		*rf->pFileSize += 1;
	}
	return 1;
}

int CMjpeg2AVI::mjpegCloseFile(void* p)
{
	RIFFFILE* rf = (RIFFFILE*)p;
	if (!rf)
		return 0;
    
	int res = 1;
	// write index
	if (rf->index)
	{
		if (cached_write(rf, rf->index, *rf->pindex_real_size + 8) != *rf->pindex_real_size + 8)
			res = 0;
	}
	else
		res = 0;
	cache_flush(rf);
	// write modified header
	rf->aviheader->dwTotalFrames = rf->frames;
	rf->avistreamheader->dwLength = rf->frames;
	lseek(rf->fd, 0, SEEK_SET);
	if (write(rf->fd, rf->header, HEADERBYTES) != HEADERBYTES)
		res = 0;
    
	close(rf->fd);
	free(rf->header);
	if (rf->index)
		free(rf->index);
	if (rf->cache)
		free(rf->cache);
	free(rf);
	return res;
}


//void Java_com_czy_client_SetAviFileName(JNIEnv *env, jobject obj, jstring b)
//{
//    
//	const char *_filePath = env->GetStringUTFChars(b, NULL);
//	CMjpeg.SetAviFileName(_filePath);
//    
//}
//void Java_com_czy_client_SetImaFileName(JNIEnv *env, jobject obj, jstring b)
//{
//	
//	const char *_filePath = env->GetStringUTFChars(b, NULL);
//	CMjpeg.SetImaFileName(_filePath);
//    
//}
//void Java_com_czy_client_on(JNIEnv *env, jobject obj)
//{
//	CMjpeg.On();
//	//__android_log_write(ANDROID_LOG_ERROR,"JNI","on");
//	
//}
//void Java_com_czy_client_off(JNIEnv *env, jobject obj)
//{
//	CMjpeg.Off();
//	//__android_log_write(ANDROID_LOG_ERROR,"JNI","off");
//}
//void Java_com_czy_client_Run(JNIEnv *env, jobject obj, jbyteArray b, jint size)
//{
//	unsigned char* data = (unsigned char*)env->GetByteArrayElements(b, 0);
//	CMjpeg.Run((unsigned char*)data,size);
//	//__android_log_write(ANDROID_LOG_ERROR,"JNI","run");
//}
//void Java_com_czy_client_End(JNIEnv *env, jobject obj)
//{
//	CMjpeg.End();
//	//__android_log_write(ANDROID_LOG_ERROR,"JNI","end");
//}
//void Java_com_czy_client_Snapshot(JNIEnv *env, jobject obj)
//{
//	CMjpeg.Snapshot();
//	//__android_log_write(ANDROID_LOG_ERROR,"JNI","snashot");
//}
//
//void Java_com_czy_client_doSnapshot(JNIEnv *env, jobject obj, jbyteArray b, jint size)
//{
//	//char ss[100];
//	unsigned char* data = (unsigned char*)env->GetByteArrayElements(b, 0);
//	CMjpeg.doSnapshot(data,size);
//	//sprintf(ss,"%s,%d", data,size);
//	//__android_log_write(ANDROID_LOG_ERROR,"JNI",ss);
//}