#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void TTInitializeTikTokBusinessSDK(void);
void TTTrackTikTokIdentify(NSString * _Nullable externalID,
                           NSString * _Nullable externalUserName,
                           NSString * _Nullable phoneNumber,
                           NSString * _Nullable email);
void TTTrackTikTokBaseEvent(NSString *eventName, NSString * _Nullable eventId);
void TTTrackTikTokContentsEvent(NSString *eventType,
                                NSDictionary * _Nullable properties,
                                NSString * _Nullable eventId);

NS_ASSUME_NONNULL_END
