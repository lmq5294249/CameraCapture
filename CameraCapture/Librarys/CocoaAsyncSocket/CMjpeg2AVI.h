//
//  CMjpeg2AVI.h
//  SocketDemo
//
//  Created by 彭 文彪 on 13-6-21.
//  Copyright (c) 2013年 彭 文彪. All rights reserved.
//

#ifndef SocketDemo_CMjpeg2AVI_h
#define SocketDemo_CMjpeg2AVI_h

class CMjpeg2AVI
{
private:
    void          * pThis;							///< 指针
    int			     iErrCode;
    long long   m_AvailSpace;        ///< 有效的磁盘空间大小
    long long   m_FramesCount;
    char *          szAviFileName;
    char *          szImageFileName;
    double		 dStableFPS;
    int				m_BufferSize;
    int				m_StopWriteTime;
    int				m_StartWriteTime;
    int				m_frame_width;
    int				m_frame_height;
    int				m_Max_frame_size;
    // for statistics
    long long int m_AllFramesCount;
    long long int m_SkippedCount;
    long long int m_DuplicatedCount;
    int		m_StableFPSCount;
    int				    m_ElapsedTime;
    
    int			m_TimeTimer;		///<按时间录像
    int			m_FramesTimer;  ///<按帧数录像
    int           m_FileSizeTimer;  ///< 录像文件大小
    int           m_CurFileSize;  ///< 录像文件大小
    
    // for statistics
    char				szMovieInfo[64];
    char				szSoftwareInfo[30];
    char				szDate[22];
    
    //for fps calc
    int			m_TempTime1;
    int			m_TempTime2;
    int			m_TempTime3;
    bool		bStopFromInside;
    bool		bUseStabFPS;
    bool		bContinueRec;  ///< 是否连续录像
    bool		bRun;
    bool       bSnapshot;
    
protected:
    
public:
    CMjpeg2AVI(void);
    ~CMjpeg2AVI(void);
    
    int  SetAviFileName(const char* fname);
    int  SetImaFileName(const char* fname);
    int  On(void);
    int  Off(void);
    int  Run(unsigned char *pData,int iDateSize);
    int  End();
    int  Snapshot(void);
    int  doSnapshot(unsigned char *pData,int iDateSize);
    
private:
    int  StartRecord(void);
    int  WriteOneFrame(unsigned char *pData,int iDateSize);
    int  UpdateFps(void);
    int  StopRecord(void);
    
    void* mjpegCreateFile(const char* fname);
    int mjpegSetup(void* rf, int fwidth, int fheight, double fps, int quality);
    int mjpegSetInfo(void* rf, const char* software, const char* comment, const char* date);
    int mjpegSetCache(void* rf, int sz);
    int mjpegSetMaxChunkSize(void* rf, unsigned int sz);
    int mjpegWriteChunk(void* rf, const unsigned char* jpeg_data, unsigned int size);
    int mjpegCloseFile(void* rf);
};

#endif
