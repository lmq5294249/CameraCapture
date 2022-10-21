//
//  RTSPClientAPI.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/10/20.
//

#ifndef RTSPClientAPI_h
#define RTSPClientAPI_h

// 视频编码类型定义
typedef enum VIDEO_CODE_TYPE
{
    // H264编码
    RTSP_VIDEO_CODE_H264 = 0x1C,
    // H265编码
    RTSP_VIDEO_CODE_H265 = 0x48323635,
    // MJPEG编码
    RTSP_VIDEO_CODE_MJPEG = 0x08,
    // MPEG4编码
    RTSP_VIDEO_CODE_MPEG4 = 0x0D,
}RtspVideoCodeType;

// 音频编码类型定义
typedef enum AUDIO_CODE_TYPE
{
    // AAC编码
    RTSP_AUDIO_CODE_AAC = 0x15002,
    // G711 Ulaw编码
    RTSP_AUDIO_CODE_G711U = 0x10006,
    // G711 Alaw编码
    RTSP_AUDIO_CODE_G711A = 0x10007,
    // G726编码
    RTSP_AUDIO_CODE_G726 = 0x1100B,
}RtspAudioCodeType;

// 视频帧类型定义
typedef enum VIDEO_FRAME_TYPE
{
    // I帧
    VIDEO_FRAME_I = 0x01,
    // P帧
    VIDEO_FRAME_P = 0x02,
    // B帧
    VIDEO_FRAME_B = 0x03,
    // JPEG
    VIDEO_FRAME_J = 0x04,
}RtspVideoFrameType;

// 媒体帧类型标志定义
typedef enum FRAME_FLAG_TYPE
{
    // 视频帧标识
    RTSP_VFRAME_FLAG = 0x00000001,
    // 音频帧标识
    RTSP_AFRAME_FLAG = 0x00000002,
    // 事件帧标识
    RTSP_EFRAME_FLAG = 0x00000004,
    // RTP帧标识
    RTSP_RFRAME_FLAG = 0x00000008,
    // SDP帧标识
    RTSP_SFRAME_FLAG = 0x00000010,
    // 媒体类型标识
    RTSP_INFO_FLAG = 0x00000020,
}RtspFrameFlag;

// 帧信息定义
typedef struct RTSP_FRAME_INFO_T
{
    // 音视频编码格式 
    unsigned int    codec;
    
    // 视频帧类型，
    unsigned int    type;
    // 视频帧率
    unsigned char    fps;
    // 视频宽度像素
    unsigned short    width;
    // 视频的高度像素
    unsigned short  height;

    // 如果为关键帧则该字段为spslen + 4
    unsigned int    reserved1;
    // 如果为关键帧则该字段为spslen+4+ppslen+4
    unsigned int    reserved2;

    // 音频采样率
    unsigned int    sample_rate;
    // 音频声道数
    unsigned int    channels;
    // 音频采样精度
    unsigned int    bits_per_sample;

    // 音视频帧大小
    unsigned int    length;
    // 时间戳,微妙数
    unsigned int    timestamp_usec;
    // 时间戳 秒数
    unsigned int    timestamp_sec;

    // 比特率
    float            bitrate;
    // 丢包率
    float            losspacket;
}RtspFrameInfo;

/* 媒体信息 */
typedef struct
{
    unsigned int u32VideoCodec;    /* 视频编码类型 */
    unsigned int u32VideoFps;    /* 视频帧率 */
    
    unsigned int u32AudioCodec;    /* 音频编码类型 */
    unsigned int u32AudioSamplerate;  /* 音频采样率 */
    unsigned int u32AudioChannel;   /* 音频通道数 */
    unsigned int u32AudioBitsPerSample;  /* 音频采样精度 */
    
    unsigned int u32VpsLength;   /* VPS 帧长度*/
    unsigned int u32SpsLength;   /* SPS 帧长度 */
    unsigned int u32PpsLength;   /* PPS 帧长度 */
    unsigned int u32SeiLength;   /* SEI 帧长度 */
    unsigned char  u8Vps[255];   /* VPS 帧内容 */
    unsigned char  u8Sps[255];   /* SPS 帧内容 */
    unsigned char  u8Pps[128];   /* PPS 帧内容 */
    unsigned char  u8Sei[128];   /* SEI 帧内容 */
}RtspMediaInfo;

// 连接类型定义
typedef enum RTP_CONNECT_TYPE
{
    // RTP基于TCP连接
    RTP_ON_TCP = 0x01,
    // RTP基于UDP连接
    RTP_ON_UDP = 0x02,
}RtpConnectType;

#endif /* RTSPClientAPI_h */
