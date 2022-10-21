#include "AACDecoder.h"
#include "FFmpegAudioDecoder.h"
#include "g711.h"

#include "libavutil/opt.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"

FFmpegAudioHandle* FFmpegAudioDecoder(int code, int sample_rate, int channels, int sample_bit) {
    FFmpegAudioHandle *pHandle = malloc(sizeof(FFmpegAudioHandle));
    pHandle->code = code;
    pHandle->pContext = 0;
    if (code == RTSP_AUDIO_CODE_AAC || code == RTSP_AUDIO_CODE_G726) {
        av_register_all();
        pHandle->pContext = aac_decoder_create(code, sample_rate, channels, sample_bit);
        if(NULL == pHandle->pContext) {
            free(pHandle);
            return NULL;
        }
    }
    
    return pHandle;
}

FFmpegAudioHandle *FFmpegAudioDecoderCreate(RtspMediaInfo info) {
    FFmpegAudioHandle *handle = malloc(sizeof(FFmpegAudioHandle));
    handle->code = info.u32AudioCodec;
    handle->pContext = 0;
    if (info.u32AudioCodec == RTSP_AUDIO_CODE_AAC || info.u32AudioCodec == RTSP_AUDIO_CODE_G726) {
        av_register_all();
        handle->pContext = aac_decoder_create(info.u32AudioCodec, info.u32AudioSamplerate, info.u32AudioChannel, 16);
        if (NULL == handle->pContext) {
            free(handle);
            return NULL;
        }
    }
    return handle;
}
int FFmpegAudioDecode(FFmpegAudioHandle* pHandle, unsigned char* buffer, int offset, int length, unsigned char* pcm_buffer, int* pcm_length) {
    int err = 0;
    if (pHandle->code == RTSP_AUDIO_CODE_AAC || pHandle->code == RTSP_AUDIO_CODE_G726) {
        err = aac_decode_frame(pHandle->pContext, (unsigned char *)(buffer + offset),length, (unsigned char *)pcm_buffer, (unsigned int*)pcm_length);
    } else if (pHandle->code == RTSP_AUDIO_CODE_G711U) {
        short *pOut = (short *)(pcm_buffer);
        unsigned char *pIn = (unsigned char *)(buffer + offset);
        for (int m=0; m<length; m++){
            pOut[m] = ulaw2linear(pIn[m]);
        }
        *pcm_length = length*2;
    } else if (pHandle->code == RTSP_AUDIO_CODE_G711A) {
        short *pOut = (short *)(pcm_buffer);
        unsigned char *pIn = (unsigned char *)(buffer + offset);
        for (int m=0; m<length; m++){
            pOut[m] = alaw2linear(pIn[m]);
        }
        *pcm_length = length*2;
    }
    
    return err;
}

void FFmpegAudioDecodeClose(FFmpegAudioHandle* pHandle) {
    if (pHandle->code == RTSP_AUDIO_CODE_AAC || pHandle->code == RTSP_AUDIO_CODE_G726){
        aac_decode_close(pHandle->pContext);
    }
    
    free(pHandle);
}
