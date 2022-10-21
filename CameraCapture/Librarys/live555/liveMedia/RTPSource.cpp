/**********
This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the
Free Software Foundation; either version 2.1 of the License, or (at your
option) any later version. (See <http://www.gnu.org/copyleft/lesser.html>.)

This library is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
more details.

You should have received a copy of the GNU Lesser General Public License
along with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
**********/
// "liveMedia"
// Copyright (c) 1996-2015 Live Networks, Inc.  All rights reserved.
// RTP Sources
// Implementation

#include "RTPSource.hh"
#include "GroupsockHelper.hh"

////////// RTPSource //////////

Boolean RTPSource::lookupByName(UsageEnvironment& env,
				char const* sourceName,
				RTPSource*& resultSource) {
  resultSource = NULL; // unless we succeed

  MediaSource* source;
  if (!MediaSource::lookupByName(env, sourceName, source)) return False;

  if (!source->isRTPSource()) {
    env.setResultMsg(sourceName, " is not a RTP source");
    return False;
  }

  resultSource = (RTPSource*)source;
  return True;
}

Boolean RTPSource::hasBeenSynchronizedUsingRTCP() {
  return fCurPacketHasBeenSynchronizedUsingRTCP;
}

Boolean RTPSource::isRTPSource() const {
  return True;
}

RTPSource::RTPSource(UsageEnvironment& env, Groupsock* RTPgs,
		     unsigned char rtpPayloadFormat,
		     u_int32_t rtpTimestampFrequency)
  : FramedSource(env),
    fRTPInterface(this, RTPgs),
    fCurPacketHasBeenSynchronizedUsingRTCP(False), fLastReceivedSSRC(0),
    fRTCPInstanceForMultiplexedRTCPPackets(NULL),
    fRTPPayloadFormat(rtpPayloadFormat), fTimestampFrequency(rtpTimestampFrequency),
    fSSRC(our_random32()), fEnableRTCPReports(True) {
  fReceptionStatsDB = new RTPReceptionStatsDB();
}

RTPSource::~RTPSource() {
  delete fReceptionStatsDB;
}

void RTPSource::getAttributes() const {
  envir().setResultMsg(""); // Fix later to get attributes from  header #####
}


////////// RTPReceptionStatsDB //////////

RTPReceptionStatsDB::RTPReceptionStatsDB()
  : fTable(HashTable::create(ONE_WORD_HASH_KEYS)), fTotNumPacketsReceived(0) {
  reset();
}

void RTPReceptionStatsDB::reset() {
  fNumActiveSourcesSinceLastReset = 0;

  Iterator iter(*this);
  RTPReceptionStats* stats;
  while ((stats = iter.next()) != NULL) {
    stats->reset();
  }
}

RTPReceptionStatsDB::~RTPReceptionStatsDB() {
  // First, remove and delete all stats records from the table:
  RTPReceptionStats* stats;
  while ((stats = (RTPReceptionStats*)fTable->RemoveNext()) != NULL) {
    delete stats;
  }

  // Then, delete the table itself:
  delete fTable;
}

void RTPReceptionStatsDB
::noteIncomingPacket(u_int32_t SSRC, u_int16_t seqNum,
		     u_int32_t rtpTimestamp, unsigned timestampFrequency,
		     Boolean useForJitterCalculation,
		     struct timeval& resultPresentationTime,
		     Boolean& resultHasBeenSyncedUsingRTCP,
		     unsigned packetSize) {
  ++fTotNumPacketsReceived;
  RTPReceptionStats* stats = lookup(SSRC);
  if (stats == NULL) {
    // This is the first time we've heard from this SSRC.
    // Create a new record for it:
    stats = new RTPReceptionStats(SSRC, seqNum);
    if (stats == NULL) return;
    add(SSRC, stats);
  }

  if (stats->numPacketsReceivedSinceLastReset() == 0) {
    ++fNumActiveSourcesSinceLastReset;
  }

  stats->noteIncomingPacket(seqNum, rtpTimestamp, timestampFrequency,
			    useForJitterCalculation,
			    resultPresentationTime,
			    resultHasBeenSyncedUsingRTCP, packetSize);
}

void RTPReceptionStatsDB
::noteIncomingSR(u_int32_t SSRC,
		 u_int32_t ntpTimestampMSW, u_int32_t ntpTimestampLSW,
		 u_int32_t rtpTimestamp) {
  RTPReceptionStats* stats = lookup(SSRC);
  if (stats == NULL) {
    // This is the first time we've heard of this SSRC.
    // Create a new record for it:
    stats = new RTPReceptionStats(SSRC);
    if (stats == NULL) return;
    add(SSRC, stats);
  }

  stats->noteIncomingSR(ntpTimestampMSW, ntpTimestampLSW, rtpTimestamp);
}

void RTPReceptionStatsDB::removeRecord(u_int32_t SSRC) {
  RTPReceptionStats* stats = lookup(SSRC);
  if (stats != NULL) {
    long SSRC_long = (long)SSRC;
    fTable->Remove((char const*)SSRC_long);
    delete stats;
  }
}

RTPReceptionStatsDB::Iterator
::Iterator(RTPReceptionStatsDB& receptionStatsDB)
  : fIter(HashTable::Iterator::create(*(receptionStatsDB.fTable))) {
}

RTPReceptionStatsDB::Iterator::~Iterator() {
  delete fIter;
}

RTPReceptionStats*
RTPReceptionStatsDB::Iterator::next(Boolean includeInactiveSources) {
  char const* key; // dummy

  // If asked, skip over any sources that haven't been active
  // since the last reset:
  RTPReceptionStats* stats;
  do {
    stats = (RTPReceptionStats*)(fIter->next(key));
  } while (stats != NULL && !includeInactiveSources
	   && stats->numPacketsReceivedSinceLastReset() == 0);

  return stats;
}

RTPReceptionStats* RTPReceptionStatsDB::lookup(u_int32_t SSRC) const {
  long SSRC_long = (long)SSRC;
  return (RTPReceptionStats*)(fTable->Lookup((char const*)SSRC_long));
}

void RTPReceptionStatsDB::add(u_int32_t SSRC, RTPReceptionStats* stats) {
  long SSRC_long = (long)SSRC;
  fTable->Add((char const*)SSRC_long, stats);
}

////////// RTPReceptionStats //////////

RTPReceptionStats::RTPReceptionStats(u_int32_t SSRC, u_int16_t initialSeqNum) {
  initSeqNum(initialSeqNum);
  init(SSRC);
}

RTPReceptionStats::RTPReceptionStats(u_int32_t SSRC) {
  init(SSRC);
}

RTPReceptionStats::~RTPReceptionStats() {
}

void RTPReceptionStats::init(u_int32_t SSRC) {
  fSSRC = SSRC;
  fTotNumPacketsReceived = 0;
  fTotBytesReceived_hi = fTotBytesReceived_lo = 0;
  fBaseExtSeqNumReceived = 0;
  fHighestExtSeqNumReceived = 0;
  fHaveSeenInitialSequenceNumber = False;
  fLastTransit = ~0;
  fPreviousPacketRTPTimestamp = 0;
  fJitter = 0.0;
  fLastReceivedSR_NTPmsw = fLastReceivedSR_NTPlsw = 0;
  fLastReceivedSR_time.tv_sec = fLastReceivedSR_time.tv_usec = 0;
  fLastPacketReceptionTime.tv_sec = fLastPacketReceptionTime.tv_usec = 0;
  fMinInterPacketGapUS = 0x7FFFFFFF;
  fMaxInterPacketGapUS = 0;
  fTotalInterPacketGaps.tv_sec = fTotalInterPacketGaps.tv_usec = 0;
  fHasBeenSynchronized = False;
  fSyncTime.tv_sec = fSyncTime.tv_usec = 0;
  reset();
}

void RTPReceptionStats::initSeqNum(u_int16_t initialSeqNum) {
    fBaseExtSeqNumReceived = 0x10000 | initialSeqNum;
    fHighestExtSeqNumReceived = 0x10000 | initialSeqNum;
    fHaveSeenInitialSequenceNumber = True;
}

#ifndef MILLION
#define MILLION 1000000
#endif
//MARK:同步注释
/*
noteIncomingPacket的实质是:将 RTP timestamp 转换为 'wall clock' time用于计算抖动，
每次接收到一个rtp包后，都会用此函数计算抖动。逻辑完全取决于系统时间的精确度，没有任何校正机制。
live555是在哪里实现时间校正的呢?答案是利用RTSP客户端(数据的接收者)利用RTCP返回的Sender Report,
然后利用其中的NTP Timestamp和RTP timestamp, 对fSyncTimestamp和fSyncTime进行校正。
实现音视频同步 (live555)总体思路是：把A/V的RTP时间戳同步到RTCP的绝对时间(NTP Timestamp)，实现A/V同步
*/
void RTPReceptionStats
::noteIncomingPacket(u_int16_t seqNum, u_int32_t rtpTimestamp,
		     unsigned timestampFrequency,
		     Boolean useForJitterCalculation,
		     struct timeval& resultPresentationTime,
		     Boolean& resultHasBeenSyncedUsingRTCP,
		     unsigned packetSize) {
  if (!fHaveSeenInitialSequenceNumber) initSeqNum(seqNum);//如果没有初始化序列号则先作初始化。

  ++fNumPacketsReceivedSinceLastReset;//上次重置后，接收到的rtp包个数。
  ++fTotNumPacketsReceived;//一共接收到的rtp包个数。
  u_int32_t prevTotBytesReceived_lo = fTotBytesReceived_lo;//接收的总字节数低四位。
  fTotBytesReceived_lo += packetSize;//fTotBytesReceived_lo是一个无符号32位整数，当达到最大值后，会从新开始计算。
  if (fTotBytesReceived_lo < prevTotBytesReceived_lo) { // wrap-around
    ++fTotBytesReceived_hi;// 接收字节数低位溢出，则高四位须加一。
  }

    // Check whether the new sequence number is the highest yet seen:检查新序列号是否是迄今为止看到的最大序列号
  unsigned oldSeqNum = (fHighestExtSeqNumReceived&0xFFFF);//取低16位数据
  unsigned seqNumCycle = (fHighestExtSeqNumReceived&0xFFFF0000);//取高16位数据
  unsigned seqNumDifference = (unsigned)((int)seqNum-(int)oldSeqNum);//当前序列号　－　上一序列号　　（双字节减法）
  unsigned newSeqNum = 0;
  if (seqNumLT((u_int16_t)oldSeqNum, seqNum)) {
    // This packet was not an old packet received out of order, so check it:
      //当前序列号大于前一次的序列号，看似是合法的rtp包。但还是要检测是否出现溢出归零的情况。
    if (seqNumDifference >= 0x8000) {
        // The sequence number wrapped around, so start a new cycle:前后序列号差距如此大，则认为溢出，高位（高两字节）须加一。
      seqNumCycle += 0x10000;
    }
    
    newSeqNum = seqNumCycle|seqNum;// 得到完整序列号。
    if (newSeqNum > fHighestExtSeqNumReceived) {//记录最大序列号
      fHighestExtSeqNumReceived = newSeqNum;//最大序列号保存到成员变量里面
    }
  } else if (fTotNumPacketsReceived > 1) {//当前序列号小于前一序列号？//先前已经接收到了rtp包。有rtp包已经存在
    // This packet was an old packet received out of order 这个包是旧包，收到时失序。
    
    if ((int)seqNumDifference >= 0x8000) {//序列号是递减的？　　这儿溢出了就要减一？　　看似是退播可能有此现象。
      // The sequence number wrapped around, so switch to an old cycle:
      seqNumCycle -= 0x10000;//上次出现了一次归零的情况，所以这里要把循坏次数减一
    }
    
    newSeqNum = seqNumCycle|seqNum;//得到完整序列号。
    if (newSeqNum < fBaseExtSeqNumReceived) {//记录基准序列号
      fBaseExtSeqNumReceived = newSeqNum;//基准（最小）序列号存入成员变量。
    }
  }

  // Record the inter-packet delay 记录数据包间的延迟 使用８字节，高四字节记录秒数，低四字节记录微秒。
  struct timeval timeNow;
  gettimeofday(&timeNow, NULL);
  if (fLastPacketReceptionTime.tv_sec != 0
      || fLastPacketReceptionTime.tv_usec != 0) {
      /*
       _STRUCT_TIMEVAL
       {
           __darwin_time_t         tv_sec;         // seconds
           __darwin_suseconds_t    tv_usec;        // and microseconds
       };
       其中，tv_sec用于存放当前时间戳的秒数，一般为long类型；tv_usec用于存放当前时间戳的微秒数，一般为int类型。
       */
    unsigned gap //计算rtp包的时间间隔。单位：一百万分之一秒，微秒，1/1000000秒　　＝　当前时间　－　上次抵达时间
      = (timeNow.tv_sec - fLastPacketReceptionTime.tv_sec)*MILLION
      + timeNow.tv_usec - fLastPacketReceptionTime.tv_usec; 
    if (gap > fMaxInterPacketGapUS) {
      fMaxInterPacketGapUS = gap;//记录出现过的最大rtp包时间间隔。
    }
    if (gap < fMinInterPacketGapUS) {
      fMinInterPacketGapUS = gap;//记录出现过的最小rtp包时间间隔。
    }
    fTotalInterPacketGaps.tv_usec += gap;//fTotalInterPacketGaps，rtp包到达的时间间隔累计。
    if (fTotalInterPacketGaps.tv_usec >= MILLION) {//数学计算，微秒溢出，秒进1。微秒减百万
      ++fTotalInterPacketGaps.tv_sec;
      fTotalInterPacketGaps.tv_usec -= MILLION;
    }
  }
  fLastPacketReceptionTime = timeNow;//fLastPacketReceptionTime，将rtp包抵达的时间更新为当前包时间。

  // Compute the current 'jitter' using the received packet's RTP timestamp,
  // and the RTP timestamp that would correspond to the current time.
  // (Use the code from appendix A.8 in the RTP spec.)
  // Note, however, that we don't use this packet if its timestamp is
  // the same as that of the previous packet (this indicates a multi-packet
  // fragment), or if we've been explicitly told not to use this packet.
  if (useForJitterCalculation
      && rtpTimestamp != fPreviousPacketRTPTimestamp) {//rtpTimestamp，rtp包头部记录的时间戳
    unsigned arrival = (timestampFrequency*timeNow.tv_sec);
    arrival += (unsigned)//计算rtp包的理论抵达时间转换时戳, 以频率为单位, 通常情况下该单位为90khz, 即90000先转换秒, 再转换微妙
      ((2.0*timestampFrequency*timeNow.tv_usec + 1000000.0)/2000000);
      // note: rounding   (+1000000 / 2000000表示向上圆整, 5入)
    int transit = arrival - rtpTimestamp;//理论和实际的时间差值。
    if (fLastTransit == (~0)) fLastTransit = transit; // hack for first time//第一个rtp包。
    int d = transit - fLastTransit;//求本次差值和上次差值的差异
    fLastTransit = transit;//把当前差值放到上次差值成员变量里面，下次使用
    if (d < 0) d = -d;//取正数
      //计算出抖动值。每次d的权重会越来越低，变体为：( (double)d )/16 + (15.0/16.0)*fJitter。
    fJitter += (1.0/16.0) * ((double)d - fJitter);
  }

  // Return the 'presentation time' that corresponds to "rtpTimestamp":
  if (fSyncTime.tv_sec == 0 && fSyncTime.tv_usec == 0) {
    // This is the first timestamp that we've seen, so use the current
    // 'wall clock' time as the synchronization time.  (This will be
    // corrected later when we receive RTCP SRs.)
    fSyncTimestamp = rtpTimestamp;
    fSyncTime = timeNow;
  }

  int timestampDiff = rtpTimestamp - fSyncTimestamp;
      // Note: This works even if the timestamp wraps around
      // (as long as "int" is 32 bits)

  // Divide this by the timestamp frequency to get real time:
  double timeDiff = timestampDiff/(double)timestampFrequency;

  // Add this to the 'sync time' to get our result:
  unsigned const million = 1000000;
  unsigned seconds, uSeconds;
  if (timeDiff >= 0.0) {
    seconds = fSyncTime.tv_sec + (unsigned)(timeDiff);
    uSeconds = fSyncTime.tv_usec
      + (unsigned)((timeDiff - (unsigned)timeDiff)*million);
    if (uSeconds >= million) {
      uSeconds -= million;
      ++seconds;
    }
  } else {
    timeDiff = -timeDiff;
    seconds = fSyncTime.tv_sec - (unsigned)(timeDiff);
    uSeconds = fSyncTime.tv_usec
      - (unsigned)((timeDiff - (unsigned)timeDiff)*million);
    if ((int)uSeconds < 0) {
      uSeconds += million;
      --seconds;
    }
  }
  resultPresentationTime.tv_sec = seconds;
  resultPresentationTime.tv_usec = uSeconds;
  resultHasBeenSyncedUsingRTCP = fHasBeenSynchronized;

  // Save these as the new synchronization timestamp & time:
  fSyncTimestamp = rtpTimestamp;
  fSyncTime = resultPresentationTime;

  fPreviousPacketRTPTimestamp = rtpTimestamp;
}

void RTPReceptionStats::noteIncomingSR(u_int32_t ntpTimestampMSW,
				       u_int32_t ntpTimestampLSW,
				       u_int32_t rtpTimestamp) {
  fLastReceivedSR_NTPmsw = ntpTimestampMSW;
  fLastReceivedSR_NTPlsw = ntpTimestampLSW;

  gettimeofday(&fLastReceivedSR_time, NULL);

  // Use this SR to update time synchronization information:
  fSyncTimestamp = rtpTimestamp;
  fSyncTime.tv_sec = ntpTimestampMSW - 0x83AA7E80; // 1/1/1900 -> 1/1/1970
  double microseconds = (ntpTimestampLSW*15625.0)/0x04000000; // 10^6/2^32
  fSyncTime.tv_usec = (unsigned)(microseconds+0.5);
  fHasBeenSynchronized = True;
}

double RTPReceptionStats::totNumKBytesReceived() const {
  double const hiMultiplier = 0x20000000/125.0; // == (2^32)/(10^3)
  return fTotBytesReceived_hi*hiMultiplier + fTotBytesReceived_lo/1000.0;
}

unsigned RTPReceptionStats::jitter() const {
  return (unsigned)fJitter;
}

void RTPReceptionStats::reset() {
  fNumPacketsReceivedSinceLastReset = 0;
  fLastResetExtSeqNumReceived = fHighestExtSeqNumReceived;
}

Boolean seqNumLT(u_int16_t s1, u_int16_t s2) {
  // a 'less-than' on 16-bit sequence numbers
  int diff = s2-s1;
  if (diff > 0) {
    return (diff < 0x8000);
  } else if (diff < 0) {
    return (diff < -0x8000);
  } else { // diff == 0
    return False;
  }
}
