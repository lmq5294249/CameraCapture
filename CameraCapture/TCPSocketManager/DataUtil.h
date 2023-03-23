//
//  DataUtil.h
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/1.
//

#import "MMTCPSocket.h"

typedef struct HeadData {
    UInt32 u32Size;
    UInt32 u32Type;
    UInt32 u32Status;
    UInt32 u32Channel;
    UInt32 u32Time;
    UInt32 u32Data;
    UInt32 u32Id;
    UInt32 u32Level;
}CamHeadData;

typedef struct UartCmd {
    char cCmdData[64];
    int iCmdLen;
}UartCmd_T;

typedef struct tagT_HHUPSDKHeader{
    UInt32 identify; // 标识头，固定 0x6ABABABA,小端格式
    UInt32 cmdType; // 命令类型
    UInt32 cmdId; // 命令
    UInt32 pktType; // 包类型,bit0 表示结束包,bit1 表示起始包,bit2 表示中间包
    UInt32 pktSeq; // 包序号,从 0 起
    UInt32 sessionID; // 会话 ID 号，短连接时用于标识会话
    UInt32 status; // 状态值，response 类型必填值，0 表示正常，非 0 表示出错，出错详细信息在 data 中表示
    UInt32 dataLen; // 后续的数据长度,不含 T_HHUPSDKHeader 结构体
}T_HHUPSDKHeader;

typedef struct UpPkgData_Info{
    int8_t  Md5Code[16];
    int8_t  UpPkgData[2048];
    int32_t UpPkgDataSize;
}T_UpPkgData_Info;

typedef struct Mp4DownloadInfo{
    int  mp4PktSeq;
    char mp4PktData[60*1024];
    int  mp4PktSize;
    char Md5[16];
}Mp4DownloadInfo_T;

@interface DataUtil : NSObject

+(NSData *)buildHeadPackWithU32Type:(UInt32)typeValue Id:(UInt32)idValue dataPackLength:(NSUInteger)length;
+(NSData *)buildPingHeartPack;
+(NSData *)buildYunTaiDataPack:(NSData *)data;
+(NSData *)unPackYunTaiData:(NSData *)data;
//MARK: - pack
//实时视频翻转镜像设置
+(NSData *)buildFlipRealTimeVideoCmdPack:(NSDictionary *)dic;
//拍照
+(NSData *)buildTakePhotoCmdPack;
//开始录像
+(NSData *)buildStartRecordCmdPack;
//结束录像
+(NSData *)buildStopRecordCmdPack;
//SD 卡图片列表获取请求
+(NSData *)buildGetSDCardPhotoListCmdPack;
//SD 卡图片缩略图列表获取请求
+(NSData *)buildGetSDCardPhotoThumbListCmdPack:(NSArray *)fileArray;
//SD 卡图片下载请求
+(NSData *)buildDownloadPhotoFromSDCardCmdPack:(NSString *)fileName;
//SD 卡图片删除请求
+(NSData *)buildDeletePhotoFromSDCardCmdPack:(NSString *)fileName;
//SD 卡录像文件列表获取请求
+(NSData *)buildGetSDCardVideoListCmdPack;
//SD 卡视频缩略图列表获取请求
+(NSData *)buildGetSDCardVideoThumbListCmdPack:(NSArray *)fileArray;
//SD 卡录像文件删除请求
+(NSData *)buildDeleteVideoFromSDCardCmdPack:(NSString *)fileName;
//SD 卡录像文件下载请求
+(NSData *)buildDownloadVideoFromSDCardCmdPack:(NSString *)fileName;
//SD 卡录像文件回放开始请求
+(NSData *)buildStartSDCardVideoPlayBackCmdPack:(NSString *)fileName;
//SD 卡录像文件回放停止请求
+(NSData *)buildStopSDCardVideoPlayBackCmdPack;
//时间设置请求
+(NSData *)buildSetCameraSystemTimeCmdPack;
//时间获取请求
+(NSData *)buildGetCameraSystemTimeCmdPack;
//名称和密码设置请求
+(NSData *)buildSetCameraWifiCmdPack:(NSString *)wifiName wifiPasswordKey:(NSString *)password;
//格式化SD 卡请求
+(NSData *)buildSDCardFormatCmdPack;
//MARK: - unPack
+(NSData *)unPackDataPack:(NSData *)data;
+(NSDictionary *)unPackCmdPack:(NSData *)data;


//MARK:- 固件升级
+(NSData *)buildGetCameraFirmwareInfoPack;
+(NSData *)buildUpgradeCameraFirmwareCmdPack;
+(NSData *)buildCameraFirmwareDataCmdPack:(NSData *)data fileMd5:(const char *)md5Code pktSeq:(UInt32)numPkt sendPktComplete:(BOOL)state;


@end


